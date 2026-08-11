import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/app_entry.dart';
import '../../native/remapper_channel.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import 'app_icon.dart';

/// The searchable list of installed apps, shared by every screen that asks the
/// user to pick one.
class AppListView extends StatefulWidget {
  const AppListView({
    super.key,
    required this.onSelected,
    this.showPackageName = true,
    this.trailingBuilder,
  });

  final ValueChanged<AppEntry> onSelected;

  /// Package names are useful when the choice is technical (an activity, a
  /// shortcut) and noise when it is not.
  final bool showPackageName;

  final Widget? Function(BuildContext context, AppEntry app)? trailingBuilder;

  @override
  State<AppListView> createState() => _AppListViewState();
}

class _AppListViewState extends State<AppListView> {
  final RemapperChannel _channel = RemapperChannel();

  List<AppEntry> _apps = const [];
  List<AppEntry> _visible = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await _channel.installedApps();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _visible = apps;
      _loading = false;
    });
  }

  void _filter(String query) {
    final needle = query.trim().toLowerCase();
    setState(() {
      _visible = needle.isEmpty ? _apps : _apps.where((a) => a.matches(needle)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            onChanged: _filter,
            style: NothingType.archivo(fontSize: 14, color: NothingTheme.txtPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Search apps',
              hintStyle: NothingType.archivo(fontSize: 14, color: NothingTheme.txtMuted(context)),
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(),
                color: NothingTheme.txtMuted(context),
                size: 18,
              ),
              filled: true,
              fillColor: NothingTheme.slab(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed));
    }
    if (_visible.isEmpty) {
      return Center(
        child: Text(
          _apps.isEmpty ? 'No launchable apps found.' : 'No app matches that search.',
          style: NothingType.archivo(color: NothingTheme.txtSecondary(context)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) {
        final app = _visible[index];
        return ListTile(
          leading: AppIcon(packageName: app.packageName),
          title: Text(
            app.label,
            style: NothingType.archivo(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: NothingTheme.txtPrimary(context),
            ),
          ),
          subtitle: widget.showPackageName
              ? Text(
                  app.packageName,
                  style: NothingType.archivo(fontSize: 12, color: NothingTheme.txtMuted(context)),
                )
              : null,
          trailing: widget.trailingBuilder?.call(context, app),
          onTap: () => widget.onSelected(app),
        );
      },
    );
  }
}
