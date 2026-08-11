import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const SectionLabel({
    super.key,
    required this.text,
    this.color,
    this.padding = const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: NothingType.sectionHeader(color: color ?? NothingTheme.txtMuted(context)),
      ),
    );
  }
}
