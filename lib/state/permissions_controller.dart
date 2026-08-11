import 'package:flutter/widgets.dart';

import '../models/status.dart';
import '../native/remapper_channel.dart';

/// Permission and service state, refreshed whenever the app comes back to the
/// foreground.
///
/// Every permission this app needs is granted somewhere else — a Settings page,
/// an accessibility list, a battery screen. The user leaves, changes something,
/// and returns. Re-reading on resume is the only point at which the answer can
/// have changed, and reading at any other time gives a stale one: an earlier
/// version re-read in the same frame that it fired the Settings intent, so it
/// could only ever report the old value.
class PermissionsController extends ChangeNotifier with WidgetsBindingObserver {
  PermissionsController({RemapperChannel? channel}) : _channel = channel ?? RemapperChannel() {
    WidgetsBinding.instance.addObserver(this);
  }

  final RemapperChannel _channel;

  ServiceStatus? _status;
  bool _loading = true;

  ServiceStatus? get status => _status;
  bool get loading => _loading;

  Future<void> refresh() async {
    try {
      _status = await _channel.getStatus();
    } catch (_) {
      // Keep the previous answer rather than blanking every indicator; a failed
      // read is not evidence that a permission was revoked.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
