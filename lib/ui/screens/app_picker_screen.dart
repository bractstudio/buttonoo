import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/key_action.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_list_view.dart';

/// Pops an [AppActionSpec] for the chosen app, or null if the user backs out.
class AppPickerScreen extends StatelessWidget {
  const AppPickerScreen({super.key});

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
          icon: Icon(PhosphorIcons.arrowLeft, color: NothingTheme.txtPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppListView(
        onSelected: (app) => Navigator.pop(context, AppActionSpec(app.packageName)),
      ),
    );
  }
}
