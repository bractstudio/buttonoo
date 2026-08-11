import 'package:flutter/material.dart';
import '../theme/nothing_theme.dart';

class NothingSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T? selectedValue;
  final Widget Function(T, bool) childBuilder;
  final ValueChanged<T> onChanged;

  const NothingSegmentedControl({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.childBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedValue == null ? -1 : values.indexOf(selectedValue as T);
    final hasSelection = selectedIndex != -1;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: NothingTheme.divider(context),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final tabWidth = (width - 8) / values.length;

          void handleTouch(Offset localPosition) {
            final fraction = localPosition.dx / width;
            final index = (fraction * values.length).floor().clamp(0, values.length - 1);
            if (values[index] != selectedValue) {
              onChanged(values[index]);
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => handleTouch(details.localPosition),
            onHorizontalDragUpdate: (details) => handleTouch(details.localPosition),
            onHorizontalDragStart: (details) => handleTouch(details.localPosition),
            child: Stack(
              children: [
                if (hasSelection)
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment(
                      -1.0 + (values.length > 1 ? selectedIndex / (values.length - 1) : 0) * 2.0,
                      0.0,
                    ),
                    child: Container(
                      width: tabWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: NothingTheme.pillActiveBg(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (int i = 0; i < values.length; i++)
                      Expanded(
                        child: IgnorePointer(
                          child: Center(
                            child: childBuilder(values[i], hasSelection && selectedIndex == i),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
