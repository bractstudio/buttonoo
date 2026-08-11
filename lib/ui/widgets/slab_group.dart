import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';
import 'slab_tile.dart';

class SlabGroup extends StatelessWidget {
  final List<Widget> children;
  final double borderRadius;
  final double innerBorderRadius;
  final EdgeInsetsGeometry? margin;
  final double spacing;

  const SlabGroup({
    super.key,
    required this.children,
    this.borderRadius = 18.0,
    this.innerBorderRadius = 8.0,
    this.margin,
    this.spacing = 4.0,
  });

  BorderRadiusGeometry _getTileBorderRadius(int index, int total) {
    if (total <= 1) {
      return BorderRadius.circular(borderRadius);
    }
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
        bottomLeft: Radius.circular(innerBorderRadius),
        bottomRight: Radius.circular(innerBorderRadius),
      );
    }
    if (index == total - 1) {
      return BorderRadius.only(
        topLeft: Radius.circular(innerBorderRadius),
        topRight: Radius.circular(innerBorderRadius),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      );
    }
    return BorderRadius.circular(innerBorderRadius);
  }

  @override
  Widget build(BuildContext context) {
    final int count = children.length;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: NothingTheme.bg(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            _buildTile(children[i], _getTileBorderRadius(i, count)),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(Widget child, BorderRadiusGeometry radius) {
    if (child is SlabTile) {
      return SlabTile(
        key: child.key,
        leading: child.leading,
        title: child.title,
        subtitle: child.subtitle,
        trailing: child.trailing,
        backgroundColor: child.backgroundColor,
        titleColor: child.titleColor,
        subtitleColor: child.subtitleColor,
        padding: child.padding,
        onTap: child.onTap,
        customBorderRadius: radius,
      );
    }
    return ClipRRect(
      borderRadius: radius is BorderRadius ? radius : BorderRadius.zero,
      child: child,
    );
  }
}
