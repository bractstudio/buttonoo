import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/app_entry.dart';
import '../../models/key_action.dart';
import '../../native/remapper_channel.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_list_view.dart';

/// Picking an activity is two choices: the app, then one of its exported
/// activities. The second choice is its own route so both back affordances agree.
class ActivityPickerScreen extends StatefulWidget {
  const ActivityPickerScreen({super.key});

  @override
  State<ActivityPickerScreen> createState() => _ActivityPickerScreenState();
}

class _ActivityPickerScreenState extends State<ActivityPickerScreen> {
  Future<void> _openActivities(AppEntry app) async {
    final spec = await Navigator.push<ActivityActionSpec>(
      context,
      MaterialPageRoute(builder: (_) => _ActivityListScreen(app: app)),
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
        onSelected: _openActivities,
        trailingBuilder: (context, _) =>
            Icon(PhosphorIcons.caretRight(), color: NothingTheme.txtMuted(context), size: 16),
      ),
    );
  }
}

class _ActivityListScreen extends StatefulWidget {
  const _ActivityListScreen({required this.app});

  final AppEntry app;

  @override
  State<_ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<_ActivityListScreen> {
  final RemapperChannel _channel = RemapperChannel();

  List<Map<String, dynamic>> _activities = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final activities = await _channel.activities(widget.app.packageName);
    if (!mounted) return;
    setState(() {
      _activities = activities;
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
    if (_activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '${widget.app.label} exports no launchable activities.',
            textAlign: TextAlign.center,
            style: NothingType.archivo(color: NothingTheme.txtSecondary(context)),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        // The action needs the fully qualified class for its ComponentName;
        // 'name' is only the last segment, for display.
        final className = activity['className'] as String;
        final shortName = activity['name'] as String? ?? className.split('.').last;

        return ListTile(
          leading: Icon(PhosphorIcons.code(), color: NothingTheme.accentRed),
          title: Text(
            shortName,
            style: NothingType.archivo(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: NothingTheme.txtPrimary(context),
            ),
          ),
          subtitle: Text(
            className,
            style: NothingType.archivo(fontSize: 11, color: NothingTheme.txtMuted(context)),
          ),
          onTap: () =>
              Navigator.pop(context, ActivityActionSpec(widget.app.packageName, className)),
        );
      },
    );
  }
}
