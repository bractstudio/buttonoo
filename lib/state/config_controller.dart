import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_config.dart';
import '../models/gesture.dart';
import '../models/key_action.dart';
import '../models/overlay_config.dart';
import '../native/remapper_channel.dart';

/// The app's configuration, owned in one place.
///
/// Several screens edit the same settings — haptics appear both in Behaviour and
/// in their own screen, lock policy sits next to the timings. Each of those used
/// to hold a private snapshot taken in `initState`, so editing one left the other
/// showing a stale value until it happened to be rebuilt.
///
/// Every mutator writes through to the platform and then notifies, so whatever is
/// on screen reflects what was actually stored.
class ConfigController extends ChangeNotifier {
  ConfigController({RemapperChannel? channel}) : _channel = channel ?? RemapperChannel();

  static const Duration _writeDelay = Duration(milliseconds: 200);

  final RemapperChannel _channel;
  final Map<String, _PendingWrite> _pending = {};

  AppConfig? _config;
  bool _loading = true;

  AppConfig? get config => _config;
  bool get loading => _loading;

  /// Labels for the packages the current actions point at. Populated alongside
  /// the config so tiles can name an app without loading the whole device.
  Map<String, String> get appNames => _appNames;
  Map<String, String> _appNames = const {};

  /// The last error from a load, if the platform could not be reached.
  Object? get error => _error;
  Object? _error;

  Future<void> load() async {
    try {
      final config = await _channel.getConfig();
      _config = config;
      _appNames = await _channel.appLabels(_referencedPackages(config));
      _error = null;
    } catch (e) {
      // Leaving _loading true here would strand the app on a spinner with no way
      // out. Surface the failure and let the screen show what it has.
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    await _channel.setEnabled(value);
    await load();
  }

  Future<void> setAction(KeyGesture gesture, ActionSpec action) async {
    await _channel.setAction(gesture, action);
    await load();
  }

  void setTiming({required int longPressMs, required int multiTapMs}) {
    _apply((c) => c.copyWith(longPressMs: longPressMs, multiTapMs: multiTapMs));
    _write('timing', () => _channel.setTiming(longPressMs: longPressMs, multiTapMs: multiTapMs));
  }

  void setOverlay(OverlayConfig overlay) {
    _apply((c) => c.copyWith(overlay: overlay));
    _write('overlay', () => _channel.setOverlay(overlay));
  }

  void setAnchor(String edge, double fraction) {
    _apply((c) => c.copyWith(anchorEdge: edge, anchorFraction: fraction));
    _write('anchor', () => _channel.setAnchor(edge, fraction));
  }

  void setLockPolicy(Map<KeyGesture, bool> policy) {
    _apply((c) => c.copyWith(lockPolicy: policy));
    _write('lockPolicy', () => _channel.setLockPolicy(policy));
  }

  void setHaptics({required bool enabled, required String intensity}) {
    _apply((c) => c.copyWith(hapticsEnabled: enabled, hapticsIntensity: intensity));
    _write('haptics', () => _channel.setHaptics(enabled: enabled, intensity: intensity));
  }

  /// Updates local state and notifies before the platform write completes.
  ///
  /// Sliders call these on every frame of a drag; waiting for a round trip before
  /// moving the thumb would make them feel broken. The values are the user's own
  /// input, so showing them immediately is honest.
  void _apply(AppConfig Function(AppConfig) change) {
    final current = _config;
    if (current == null) return;
    _config = change(current);
    notifyListeners();
  }

  /// Coalesces rapid writes to the same setting.
  ///
  /// A slider drag produces one call per frame, and each platform write is a
  /// DataStore edit that the running service observes and reconfigures itself
  /// from. Only the value the user settles on needs to reach disk.
  void _write(String key, Future<void> Function() write) {
    _pending.remove(key)?.timer.cancel();
    _pending[key] = _PendingWrite(
      write: write,
      timer: Timer(_writeDelay, () {
        _pending.remove(key);
        write();
      }),
    );
  }

  /// Sends anything still waiting, immediately. Called when the owner goes away
  /// so a change made in the last moments before a screen closes is not lost.
  Future<void> flush() async {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final entry in pending) {
      entry.timer.cancel();
      await entry.write();
    }
  }

  @override
  void dispose() {
    flush();
    super.dispose();
  }

  Iterable<String> _referencedPackages(AppConfig config) sync* {
    for (final action in config.actions.values) {
      switch (action) {
        case AppActionSpec(:final packageName) ||
            ShortcutActionSpec(:final packageName) ||
            ActivityActionSpec(:final packageName):
          yield packageName;
        case AppsColumnActionSpec(:final packageNames):
          yield* packageNames;
      }
    }
  }
}

class _PendingWrite {
  const _PendingWrite({required this.timer, required this.write});

  final Timer timer;
  final Future<void> Function() write;
}
