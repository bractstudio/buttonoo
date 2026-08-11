import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';

class StatusDot extends StatelessWidget {
  final bool active;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const StatusDot({
    super.key,
    this.active = true,
    this.activeColor,
    this.inactiveColor,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? NothingTheme.accentRed)
        : (inactiveColor ?? NothingTheme.accentWhite);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
