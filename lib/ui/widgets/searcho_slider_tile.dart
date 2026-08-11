import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

class SearchoSliderTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const SearchoSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 0,
    required this.label,
    required this.onChanged,
  });

  @override
  State<SearchoSliderTile> createState() => _SearchoSliderTileState();
}

class _SearchoSliderTileState extends State<SearchoSliderTile> {
  late double _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _dragValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant SearchoSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.value != widget.value) {
      _dragValue = widget.value;
    }
  }

  void _updateValue(double localX, double width) {
    if (width <= 0) return;
    final double fraction = (localX / width).clamp(0.0, 1.0);
    double newValue = widget.min + fraction * (widget.max - widget.min);

    if (widget.divisions > 0) {
      final double step = (widget.max - widget.min) / widget.divisions;
      final int steps = ((newValue - widget.min) / step).round();
      newValue = widget.min + steps * step;
    }

    newValue = newValue.clamp(widget.min, widget.max);
    setState(() {
      _dragValue = newValue;
    });

    if (newValue != widget.value) {
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = NothingTheme.isDark(context);

    // Track colors
    final Color inactiveBg = isDark ? NothingTheme.slab(context) : NothingTheme.divider(context);

    // Active pill color: high-contrast fill (white in dark mode, black in light mode, or accent red)
    final Color activeBg = isDark ? Colors.white : Colors.black;

    // Text colors
    final Color inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.7);

    final Color activeTextColor = isDark ? Colors.black : Colors.white;

    final double range = widget.max - widget.min;
    final double percentage = range > 0 ? ((_dragValue - widget.min) / range).clamp(0.0, 1.0) : 0.0;

    Widget buildTextLayer(Color textColor, double activeW) {
      final bool showCombined = activeW < 130;
      final String leftText = showCombined ? '' : widget.title.toUpperCase();
      final String rightText = showCombined
          ? '${widget.title} ${widget.label}'.toUpperCase()
          : widget.label.toUpperCase();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftText,
              style: NothingType.doto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.08,
              ),
            ),
            Text(
              rightText,
              style: NothingType.doto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.08,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: NothingTheme.slab(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            Text(
              widget.subtitle!,
              style: NothingType.subtitle(color: NothingTheme.txtSecondary(context)),
            ),
            const SizedBox(height: 10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double activeWidth = percentage * totalWidth;
              final double displayActiveWidth = activeWidth.clamp(32.0, totalWidth);

              return GestureDetector(
                onHorizontalDragStart: (_) {
                  _isDragging = true;
                  HapticFeedback.selectionClick();
                },
                onHorizontalDragUpdate: (details) {
                  _updateValue(details.localPosition.dx, totalWidth);
                  HapticFeedback.selectionClick();
                },
                onHorizontalDragEnd: (_) {
                  _isDragging = false;
                  HapticFeedback.mediumImpact();
                },
                onTapDown: (details) {
                  _updateValue(details.localPosition.dx, totalWidth);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // 1. Inactive background
                        Container(color: inactiveBg),

                        // 2. Inactive text layer
                        Positioned.fill(
                          child: Center(child: buildTextLayer(inactiveTextColor, activeWidth)),
                        ),

                        // 3. Active background pill
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: displayActiveWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: activeBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // 4. Active text layer (clipped)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: displayActiveWidth,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: totalWidth,
                              maxWidth: totalWidth,
                              minHeight: 56,
                              maxHeight: 56,
                              child: Center(child: buildTextLayer(activeTextColor, activeWidth)),
                            ),
                          ),
                        ),

                        // 5. Thumb indicator pill
                        Positioned(
                          left: (displayActiveWidth - 14 - 2).clamp(16.0, totalWidth - 20),
                          top: 14,
                          bottom: 14,
                          width: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
