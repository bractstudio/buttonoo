import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_config.dart';
import '../models/app_entry.dart';
import '../models/device_profile.dart';
import '../models/gesture.dart';
import '../models/key_action.dart';
import '../models/observed_key_event.dart';
import '../models/overlay_config.dart';
import '../models/status.dart';

/// Mirrors ShizukuRoute.State on the native side.
enum ShizukuState {
  notInstalled,
  notRunning,
  needsPermission,
  ready;

  static ShizukuState parse(String? raw) => switch (raw) {
    'READY' => ShizukuState.ready,
    'NEEDS_PERMISSION' => ShizukuState.needsPermission,
    'NOT_RUNNING' => ShizukuState.notRunning,
    _ => ShizukuState.notInstalled,
  };

  String get label => switch (this) {
    ShizukuState.ready => 'Ready',
    ShizukuState.needsPermission => 'Permission needed',
    ShizukuState.notRunning => 'Not running',
    ShizukuState.notInstalled => 'Not installed',
  };
}

class PairingResult {
  const PairingResult({required this.ok, required this.message});
  final bool ok;
  final String message;
}

/// A resolved icon lookup. Wraps the bytes so that "we asked and there is no
/// icon" can be cached as distinct from "we have not asked yet".
class _Icon {
  const _Icon(this.bytes);
  final Uint8List? bytes;
}

/// Least-recently-used map. Small enough that a dependency would not earn its keep.
class _LruCache<K, V> {
  _LruCache(this.capacity);

  final int capacity;
  final LinkedHashMap<K, V> _entries = LinkedHashMap();

  V? get(K key) {
    final value = _entries.remove(key);
    if (value != null) _entries[key] = value;
    return value;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}

class RemapperChannel {
  static const MethodChannel _m = MethodChannel('dev.buttonooo.essential_key/methods');
  static const EventChannel _keys = EventChannel('dev.buttonooo.essential_key/keyEvents');
  static const EventChannel _adb = EventChannel('dev.buttonooo.essential_key/adbProgress');

  /// Icon bytes for recently shown packages. Bounded because a device can have
  /// hundreds of apps and the pickers scroll through all of them.
  static final _LruCache<String, _Icon> _icons = _LruCache(120);
  static final Map<String, Future<Uint8List?>> _iconRequests = {};

  Future<ServiceStatus> getStatus() async {
    final res = await _m.invokeMethod('getStatus');
    return ServiceStatus.fromMap(res as Map);
  }

  Future<AppConfig> getConfig() async {
    final raw = await _m.invokeMethod<String>('getConfig');
    if (raw == null || raw.isEmpty) {
      return AppConfig(
        actions: {for (var g in KeyGesture.values) g: const NoneActionSpec()},
        overlay: const OverlayConfig(),
        lockPolicy: {for (var g in KeyGesture.values) g: false},
      );
    }
    return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setEnabled(bool v) async {
    await _m.invokeMethod('setEnabled', {'value': v});
  }

  Future<void> setAction(KeyGesture g, ActionSpec a) async {
    await _m.invokeMethod('setAction', {'gesture': g.key, 'actionJson': jsonEncode(a.toJson())});
  }

  Future<void> setTiming({required int longPressMs, required int multiTapMs}) async {
    await _m.invokeMethod('setTiming', {'longPressMs': longPressMs, 'multiTapMs': multiTapMs});
  }

  Future<void> setOverlay(OverlayConfig c) async {
    await _m.invokeMethod('setOverlay', {'overlayJson': jsonEncode(c.toJson())});
  }

  Future<void> setLockPolicy(Map<KeyGesture, bool> p) async {
    final map = p.map((g, v) => MapEntry(g.key, v));
    await _m.invokeMethod('setLockPolicy', {'lockPolicyJson': jsonEncode(map)});
  }

  Future<void> setHaptics({required bool enabled, required String intensity}) async {
    await _m.invokeMethod('setHaptics', {
      'hapticsJson': jsonEncode({'enabled': enabled, 'intensity': intensity}),
    });
  }

  Future<void> setLearnMode(bool v) async {
    await _m.invokeMethod('setLearnMode', {'value': v});
  }

  Future<void> setSuppressActions(bool v) async {
    await _m.invokeMethod('setSuppressActions', {'value': v});
  }

  Future<void> setScanCode(int v) async {
    await _m.invokeMethod('setScanCode', {'scanCode': v});
  }

  Stream<ObservedKeyEvent> keyEvents() {
    return _keys.receiveBroadcastStream().map((e) => ObservedKeyEvent.fromMap(e as Map));
  }

  Stream<String> adbProgress() {
    return _adb.receiveBroadcastStream().map((e) => e.toString());
  }

  Future<DeviceProfile> detectDevice() async {
    final res = await _m.invokeMethod('detectDevice');
    return DeviceProfile.fromMap(res as Map);
  }

  Future<void> setAnchor(String edge, double fraction) async {
    await _m.invokeMethod('setAnchor', {'edge': edge, 'fraction': fraction});
  }

  /// Fires the real overlay. [sticky] holds it on screen until [dismissPreview],
  /// so the settings page can show live edits on the actual overlay.
  Future<void> previewOverlay(
    ActionSpec a, {
    bool sticky = false,
    OverlayConfig? overlay,
    String? edge,
    double? fraction,
  }) async {
    await _m.invokeMethod('previewOverlay', {
      'actionJson': jsonEncode(a.toJson()),
      'sticky': sticky,
      'overlayJson': overlay != null ? jsonEncode(overlay.toJson()) : null,
      'edge': edge,
      'fraction': fraction,
    });
  }

  Future<void> dismissPreview() async {
    await _m.invokeMethod('dismissPreview');
  }

  Future<List<PackageState>> unlockStates() async {
    final res = await _m.invokeListMethod('unlockStates');
    return (res ?? []).map((e) => PackageState.fromMap(e as Map)).toList();
  }

  Future<void> openAppInfo(String pkg) async {
    await _m.invokeMethod('openAppInfo', {'packageName': pkg});
  }

  Future<bool> shizukuAvailable() async {
    final res = await _m.invokeMethod<bool>('shizukuAvailable');
    return res ?? false;
  }

  /// Which precondition Shizuku is currently failing, so the UI can offer the
  /// matching next step instead of a dead "unavailable".
  Future<ShizukuState> shizukuState() async {
    final res = await _m.invokeMethod<String>('shizukuState');
    return ShizukuState.parse(res);
  }

  /// Fires Shizuku's permission dialog. Returns false when it could not be
  /// shown (binder dead, or permanently denied — the user must fix that in the
  /// Shizuku app). Re-read [shizukuState] after the app resumes.
  Future<bool> requestShizukuPermission() async {
    final res = await _m.invokeMethod<bool>('requestShizukuPermission');
    return res ?? false;
  }

  Future<bool> runShizukuUnlock() async {
    final res = await _m.invokeMethod<bool>('runShizukuUnlock');
    return res ?? false;
  }

  /// Returns the route actually taken: `shizuku` when it was restored in place,
  /// or `app_info` when App Info was opened for the user to finish manually.
  Future<String> restoreEssentialSpace() async {
    final res = await _m.invokeMethod<String>('restoreEssentialSpace');
    return res ?? 'app_info';
  }

  Future<void> startAdbDiscovery() async {
    await _m.invokeMethod('startAdbDiscovery');
  }

  /// Pairing is one-time — adbd remembers our key, so once this is true the
  /// user never needs a pairing code again, only Wireless debugging switched on.
  Future<bool> adbIsPaired() async {
    final res = await _m.invokeMethod<bool>('adbIsPaired');
    return res ?? false;
  }

  Future<void> adbForgetPairing() async {
    await _m.invokeMethod('adbForgetPairing');
  }

  /// Disables the consumer packages over an existing pairing. No code needed.
  Future<PairingResult> adbDisable() async {
    final res = await _m.invokeMapMethod<String, dynamic>('adbDisable');
    return PairingResult(
      ok: res?['ok'] as bool? ?? false,
      message: res?['message'] as String? ?? 'Could not reach ADB.',
    );
  }

  Future<void> stopAdbDiscovery() async {
    await _m.invokeMethod('stopAdbDiscovery');
  }

  /// Performs the real pair -> connect -> `pm disable-user` sequence.
  /// The message is user-facing and explains *why* it failed.
  Future<PairingResult> submitPairingCode(String code) async {
    final res = await _m.invokeMapMethod<String, dynamic>('submitPairingCode', {'code': code});
    return PairingResult(
      ok: res?['ok'] as bool? ?? false,
      message: res?['message'] as String? ?? 'Pairing failed.',
    );
  }

  /// Every launcher-visible app, names only. Cheap enough to call on screen open.
  Future<List<AppEntry>> installedApps() async {
    final res = await _m.invokeListMethod('installedApps');
    return (res ?? []).map((e) => AppEntry.fromMap(e as Map)).toList();
  }

  /// Labels for a known set of packages, for screens that display a handful of
  /// assigned apps and have no reason to load the whole device.
  Future<Map<String, String>> appLabels(Iterable<String> packageNames) async {
    final wanted = packageNames.where((p) => p.isNotEmpty).toSet().toList();
    if (wanted.isEmpty) return const {};
    final res = await _m.invokeMapMethod<String, String>('appLabels', {'packageNames': wanted});
    return res ?? const {};
  }

  /// The launcher icon for one package, or null if it has none.
  ///
  /// Concurrent requests for the same package share one platform call, so a list
  /// that rebuilds while scrolling does not queue duplicate work.
  Future<Uint8List?> appIcon(String packageName) {
    final cached = _icons.get(packageName);
    if (cached != null) return Future.value(cached.bytes);

    return _iconRequests.putIfAbsent(packageName, () async {
      try {
        final bytes = await _m.invokeMethod<Uint8List>('appIcon', {'packageName': packageName});
        _icons.put(packageName, _Icon(bytes));
        return bytes;
      } on PlatformException {
        _icons.put(packageName, const _Icon(null));
        return null;
      } finally {
        _iconRequests.remove(packageName);
      }
    });
  }

  /// False unless buttonoo is the default launcher. The platform gates the whole
  /// shortcut API on that, so an empty shortcut list means nothing until this is
  /// checked.
  Future<bool> shortcutHostPermission() async {
    return await _m.invokeMethod<bool>('shortcutHostPermission') ?? false;
  }

  Future<List<Map<String, dynamic>>> shortcuts(String pkg) async {
    final res = await _m.invokeListMethod('shortcuts', {'packageName': pkg});
    return (res ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> activities(String pkg) async {
    final res = await _m.invokeListMethod('activities', {'packageName': pkg});
    return (res ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> openAccessibilitySettings() async => _m.invokeMethod('openAccessibilitySettings');
  Future<void> openOverlayPermission() async => _m.invokeMethod('openOverlayPermission');
  Future<void> openWriteSettings() async => _m.invokeMethod('openWriteSettings');
  Future<void> openDndAccess() async => _m.invokeMethod('openDndAccess');
  Future<void> openBatteryOptimization() async => _m.invokeMethod('openBatteryOptimization');
  Future<void> openDeveloperOptions() async => _m.invokeMethod('openDeveloperOptions');
  Future<void> openWirelessDebugging() async => _m.invokeMethod('openWirelessDebugging');
}
