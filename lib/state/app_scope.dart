import 'package:flutter/widgets.dart';

import 'config_controller.dart';
import 'permissions_controller.dart';

/// Owns the app's controllers and puts them in the tree.
///
/// Two separate scopes rather than one: a slider drag changes the config many
/// times a second, and nothing watching permissions has any reason to rebuild
/// for that.
class AppScope extends StatefulWidget {
  const AppScope({super.key, required this.child});

  final Widget child;

  static ConfigController configOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ConfigScope>()!.notifier!;

  static PermissionsController permissionsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PermissionsScope>()!.notifier!;

  /// Reads a controller without subscribing, for callbacks that only write.
  static ConfigController configReadOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ConfigScope>()!.notifier!;

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  final ConfigController _config = ConfigController();
  final PermissionsController _permissions = PermissionsController();

  @override
  void initState() {
    super.initState();
    _config.load();
    _permissions.refresh();
  }

  @override
  void dispose() {
    _config.dispose();
    _permissions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConfigScope(
      notifier: _config,
      child: _PermissionsScope(notifier: _permissions, child: widget.child),
    );
  }
}

class _ConfigScope extends InheritedNotifier<ConfigController> {
  const _ConfigScope({required super.notifier, required super.child});
}

class _PermissionsScope extends InheritedNotifier<PermissionsController> {
  const _PermissionsScope({required super.notifier, required super.child});
}
