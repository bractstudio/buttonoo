import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/app_entry.dart';
import '../../models/key_action.dart';
import '../../native/remapper_channel.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_list_view.dart';

/// Picking a shortcut is two choices: the app, then one of its shortcuts.
///
/// The second choice is its own route so that the system back gesture and the
/// back button agree — an earlier version swapped the body in place, and only
/// the button returned to the app list.
class ShortcutPickerScreen extends StatefulWidget {
  const ShortcutPickerScreen({super.key});

  @override
  State<ShortcutPickerScreen> createState() => _ShortcutPickerScreenState();
}

class _ShortcutPickerScreenState extends State<ShortcutPickerScreen> {
  Future<void> _openShortcuts(AppEntry app) async {
    final spec = await Navigator.push<ShortcutActionSpec>(
      context,
      MaterialPageRoute(builder: (_) => _ShortcutListScreen(app: app)),
    );
    if (!mounted || spec == null) return;
    Navigator.pop(context, spec);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      appBar: AppBar(
        title: Text(
          'SELECT APP',
          style: NothingType.doto(fontSize: 18, color: NothingTheme.txtPrimary(context)),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: NothingTheme.txtPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppListView(
        showPackageName: false,
        onSelected: _openShortcuts,
        trailingBuilder: (context, _) =>
            Icon(PhosphorIcons.caretRight(), color: NothingTheme.txtMuted(context), size: 16),
      ),
    );
  }
}

class _ShortcutListScreen extends StatefulWidget {
  const _ShortcutListScreen({required this.app});

  final AppEntry app;

  @override
  State<_ShortcutListScreen> createState() => _ShortcutListScreenState();
}

class _ShortcutListScreenState extends State<_ShortcutListScreen> {
  final RemapperChannel _channel = RemapperChannel();

  List<Map<String, dynamic>> _shortcuts = const [];
  bool _hostPermission = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final canHost = await _channel.shortcutHostPermission();
    final shortcuts = canHost
        ? await _channel.shortcuts(widget.app.packageName)
        : const <Map<String, dynamic>>[];
    if (!mounted) return;
    setState(() {
      _hostPermission = canHost;
      _shortcuts = shortcuts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      appBar: AppBar(
        title: Text(
          widget.app.label.toUpperCase(),
          style: NothingType.doto(fontSize: 18, color: NothingTheme.txtPrimary(context)),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: NothingTheme.txtPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed));
    }
    if (!_hostPermission) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'App shortcuts are unavailable.\n\n'
            'Android only lets the default launcher read or open another app\'s '
            'shortcuts, and buttonoo is not a launcher. There is no permission '
            'to grant — the restriction is built into the platform.\n\n'
            'Map an app or a specific activity instead.',
            textAlign: TextAlign.center,
            style: NothingType.archivo(
              color: NothingTheme.txtSecondary(context),
              height: 1.45,
            ),
          ),
        ),
      );
    }
    if (_shortcuts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '${widget.app.label} publishes no shortcuts.',
            textAlign: TextAlign.center,
            style: NothingType.archivo(color: NothingTheme.txtSecondary(context)),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = _shortcuts[index];
        final id = shortcut['id'] as String;
        final label = shortcut['shortLabel'] as String? ?? id;

        return ListTile(
          leading: Icon(PhosphorIcons.arrowSquareOut(), color: NothingTheme.accentRed),
          title: Text(
            label,
            style: NothingType.archivo(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: NothingTheme.txtPrimary(context),
            ),
          ),
          subtitle: Text(
            id,
            style: NothingType.archivo(fontSize: 11, color: NothingTheme.txtMuted(context)),
          ),
          onTap: () => Navigator.pop(context, ShortcutActionSpec(widget.app.packageName, id)),
        );
      },
    );
  }
}
