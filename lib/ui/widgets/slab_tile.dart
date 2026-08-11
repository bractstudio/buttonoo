import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

class SlabTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;

  const SlabTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.onTap,
    this.borderRadius = 0.0,
    this.customBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? NothingTheme.slab(context);
    final effectiveTitleColor = titleColor ?? NothingTheme.txtPrimary(context);
    final effectiveSubtitleColor = subtitleColor ?? NothingTheme.txtSecondary(context);
    final borderColor = NothingTheme.divider(context);
    final effectiveBorderRadius = customBorderRadius ?? BorderRadius.circular(borderRadius);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: effectiveBorderRadius,
          border: Border.all(color: borderColor.withValues(alpha: 0.08), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius is BorderRadius ? effectiveBorderRadius : null,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: NothingType.archivo(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: effectiveTitleColor,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: NothingType.archivo(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: effectiveSubtitleColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
