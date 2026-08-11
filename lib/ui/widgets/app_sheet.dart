import 'package:flutter/material.dart';

import '../theme/nothing_theme.dart';

/// The app's one bottom-sheet presentation.
///
/// Sheets used to come in three shapes: two screens drew a rounded container
/// with a handle inside a full page — which looked like a sheet but could not be
/// dragged and had nothing behind it — while the genuine sheets used a different
/// radius. Anything that should feel like a sheet goes through here.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    builder: (context) => AppSheet(child: Builder(builder: builder)),
  );
}

/// The sheet chrome: background, corners, and the grab handle.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child});

  static const double cornerRadius = 28;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NothingTheme.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(cornerRadius)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: NothingTheme.divider(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
