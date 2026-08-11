import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';

class NothingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;

  const NothingCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? NothingTheme.slab(context);
    final borderColor = NothingTheme.divider(context);

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor.withValues(alpha: 0.1)),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardWidget,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: cardWidget,
    );
  }
}
