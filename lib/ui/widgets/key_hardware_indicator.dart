import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

class KeyHardwareIndicator extends StatelessWidget {
  final double height;
  final double keyTop;
  final double keyHeight;

  const KeyHardwareIndicator({
    super.key,
    this.height = 300.0,
    this.keyTop = 110.0,
    this.keyHeight = 78.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Vertical guide line
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: Container(color: NothingTheme.divider(context)),
          ),
          // Red hardware key pill
          Positioned(
            right: 0,
            top: keyTop,
            width: 7,
            height: keyHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: NothingTheme.accentRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          // Vertical "KEY" label
          Positioned(
            right: 12,
            top: keyTop + 14,
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'KEY',
                style: NothingType.archivo(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: NothingTheme.txtSecondary(context),
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
