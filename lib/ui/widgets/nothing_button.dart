import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

class NothingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isRed;
  final EdgeInsetsGeometry padding;
  final double height;

  const NothingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isRed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isRed
        ? NothingTheme.accentRed
        : (isPrimary ? NothingTheme.pillActiveBg(context) : NothingTheme.slab(context));
    final fgColor = isRed
        ? Colors.white
        : (isPrimary ? NothingTheme.pillActiveFg(context) : NothingTheme.txtPrimary(context));

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: padding,
          alignment: Alignment.center,
          child: Text(
            text,
            style: NothingType.archivo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: fgColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
