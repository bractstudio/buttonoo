import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/key_action.dart';
import '../../models/overlay_config.dart';
import '../../native/remapper_channel.dart';
import '../../state/app_scope.dart';
import '../../state/config_controller.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_sheet.dart';
import '../widgets/searcho_slider_tile.dart';
import '../widgets/section_label.dart';
import '../widgets/nothing_segmented_control.dart';
import '../widgets/slab_group.dart';

/// Overlay settings.
///
/// Every change fires the actual overlay and holds it on screen while this page is open.
class OverlaySettingsScreen extends StatefulWidget {
  const OverlaySettingsScreen({super.key});

  @override
  State<OverlaySettingsScreen> createState() => _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends State<OverlaySettingsScreen> with WidgetsBindingObserver {
  final RemapperChannel _channel = RemapperChannel();

  late ConfigController _config;

  OverlayConfig get _cfg => _config.config?.overlay ?? const OverlayConfig();
  String get _edge => _config.config?.anchorEdge ?? 'right';
  double get _fraction => _config.config?.anchorFraction ?? 0.41;

  String _model = '';
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Held so dispose can flush without looking the controller up again.
    _config = AppScope.configOf(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    // The page held the overlay on screen; hand back whatever is still queued so
    // the last edit is stored, then take the overlay down.
    _config.flush();
    _channel.dismissPreview();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _channel.dismissPreview();
    } else if (state == AppLifecycleState.resumed) {
      _showPreview();
    }
  }

  Future<void> _load() async {
    final device = await _channel.detectDevice();
    if (!mounted) return;
    setState(() {
      _model = device.model;
      _loading = false;
    });
    _showPreview();
  }

  /// Edits are shown on the real overlay rather than an in-page drawing, so the
  /// preview cannot drift from what actually fires.
  void _showPreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 16), () async {
      await _channel.previewOverlay(
        const QuickActionSpec('flashlight'),
        sticky: true,
        overlay: _cfg,
        edge: _edge,
        fraction: _fraction,
      );
    });
  }

  void _push(OverlayConfig next) {
    _config.setOverlay(next);
    _showPreview();
  }

  void _pushAnchor({String? edge, double? fraction}) {
    _config.setAnchor(edge ?? _edge, (fraction ?? _fraction).clamp(0.02, 0.98));
    _showPreview();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _config.loading) {
      return Scaffold(
        backgroundColor: NothingTheme.bg(context),
        body: const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed)),
      );
    }

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: NothingTheme.txtPrimary(context),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'OVERLAY',
                    style: NothingType.doto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: NothingTheme.txtPrimary(context),
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                '${_model.isEmpty ? 'Device' : _model} · $_edge edge · '
                '${(_fraction * 100).round()}% · ${_cfg.edgeMargin}dp',
                style: NothingType.archivo(fontSize: 11, color: NothingTheme.txtMuted(context)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  const SectionLabel(text: 'POSITION', padding: EdgeInsets.only(bottom: 12)),
                  SlabGroup(
                    children: [
                      _edgeTile(),
                      SearchoSliderTile(
                        title: 'Position Y',
                        subtitle: 'Along the edge',
                        label: '${(_fraction * 100).round()}%',
                        value: _fraction * 100,
                        min: 2,
                        max: 98,
                        onChanged: (v) => _pushAnchor(fraction: v / 100),
                      ),
                      SearchoSliderTile(
                        title: 'Distance X',
                        subtitle: 'From the screen edge',
                        label: '${_cfg.edgeMargin} dp',
                        value: _cfg.edgeMargin.toDouble(),
                        min: 0,
                        max: 60,
                        onChanged: (v) => _push(_cfg.copyWith(edgeMargin: v.round())),
                      ),
                    ],
                  ),
                  const SectionLabel(
                    text: 'CARD & ACCENT',
                    padding: EdgeInsets.only(top: 22, bottom: 12),
                  ),
                  SlabGroup(
                    children: [
                      SearchoSliderTile(
                        title: 'Width',
                        label: '${_cfg.cardWidth} dp',
                        value: _cfg.cardWidth.toDouble(),
                        min: 30,
                        max: 90,
                        onChanged: (v) => _push(_cfg.copyWith(cardWidth: v.round())),
                      ),
                      SearchoSliderTile(
                        title: 'Height',
                        label: '${_cfg.cardHeight} dp',
                        value: _cfg.cardHeight.toDouble(),
                        min: 40,
                        max: 180,
                        onChanged: (v) => _push(_cfg.copyWith(cardHeight: v.round())),
                      ),
                      SearchoSliderTile(
                        title: 'Corner Radius',
                        label: '${_cfg.cornerRadius} dp',
                        value: _cfg.cornerRadius.toDouble(),
                        min: 0,
                        max: 40,
                        onChanged: (v) => _push(_cfg.copyWith(cornerRadius: v.round())),
                      ),
                      _accentTile(),
                      _cardStyleTile(),
                      SearchoSliderTile(
                        title: 'Hold on screen',
                        subtitle: 'Before it fades out',
                        label: '${_cfg.holdMs} ms',
                        value: _cfg.holdMs.toDouble(),
                        min: 300,
                        max: 3000,
                        onChanged: (v) => _push(_cfg.copyWith(holdMs: v.round())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _edgeTile() => Container(
    color: NothingTheme.slab(context),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edge',
          style: NothingType.archivo(fontSize: 15, color: NothingTheme.txtPrimary(context)),
        ),
        const SizedBox(height: 3),
        Text(
          'Which side your key is on',
          style: NothingType.subtitle(color: NothingTheme.txtSecondary(context)),
        ),
        const SizedBox(height: 14),
        NothingSegmentedControl<String>(
          values: const ['left', 'right'],
          selectedValue: _edge,
          childBuilder: (side, selected) => Text(
            side == 'left' ? 'Left' : 'Right',
            style: NothingType.archivo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? NothingTheme.pillActiveFg(context)
                  : NothingTheme.txtSecondary(context),
            ),
          ),
          onChanged: (side) => _pushAnchor(edge: side),
        ),
      ],
    ),
  );

  Widget _accentTile() {
    final presets = const [
      ('Red', '#D71921'),
      ('White', '#FBFBF9'),
      ('Yellow', '#FFD300'),
    ];
    final currentPreset = presets.firstWhere(
      (p) => p.$2.toUpperCase() == _cfg.accentHex.toUpperCase(),
      orElse: () => ('', ''),
    );
    final selectedPreset = currentPreset.$1.isEmpty ? null : currentPreset;

    return Container(
      color: NothingTheme.slab(context),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accent',
                style: NothingType.archivo(fontSize: 15, color: NothingTheme.txtPrimary(context)),
              ),
              Row(
                children: [
                  Text(
                    'Edge glow',
                    style: NothingType.archivo(
                      fontSize: 12,
                      color: NothingTheme.txtSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: _cfg.glow,
                    activeThumbColor: NothingTheme.pillActiveBg(context),
                    activeTrackColor: NothingTheme.accentRed,
                    onChanged: (v) => _push(_cfg.copyWith(glow: v)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NothingSegmentedControl<(String, String)>(
                  values: presets,
                  selectedValue: selectedPreset,
                  childBuilder: (p, selected) => Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${p.$2.replaceAll('#', '')}', radix: 16)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.$1,
                        style: NothingType.archivo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? NothingTheme.pillActiveFg(context)
                              : NothingTheme.txtSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  onChanged: (p) => _push(_cfg.copyWith(accentHex: p.$2)),
                ),
              ),
              const SizedBox(width: 8),
              _customColorIconButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardStyleTile() => Container(
    color: NothingTheme.slab(context),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Style',
          style: NothingType.archivo(fontSize: 15, color: NothingTheme.txtPrimary(context)),
        ),
        const SizedBox(height: 3),
        Text(
          'Popup background appearance',
          style: NothingType.subtitle(color: NothingTheme.txtSecondary(context)),
        ),
        const SizedBox(height: 14),
        NothingSegmentedControl<String>(
          values: const ['filled', 'stroke', 'transparent'],
          selectedValue: _cfg.cardStyle,
          childBuilder: (style, selected) => Text(
            style == 'filled'
                ? 'Filled'
                : style == 'stroke'
                    ? 'Stroke'
                    : 'Transparent',
            style: NothingType.archivo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? NothingTheme.pillActiveFg(context)
                  : NothingTheme.txtSecondary(context),
            ),
          ),
          onChanged: (style) => _push(_cfg.copyWith(cardStyle: style)),
        ),
      ],
    ),
  );

  Widget _customColorIconButton() {
    final presets = const ['#D71921', '#FBFBF9', '#FFD300'];
    final isCustom = !presets.contains(_cfg.accentHex.toUpperCase());
    final customColor = isCustom
        ? Color(int.parse('FF${_cfg.accentHex.replaceAll('#', '')}', radix: 16))
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        showAppSheet<void>(
          context: context,
          builder: (sheetContext) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: CustomColorPicker(
              initialHex: _cfg.accentHex,
              onColorSelected: (hex) => _push(_cfg.copyWith(accentHex: hex)),
            ),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isCustom ? NothingTheme.pillActiveBg(context) : NothingTheme.divider(context),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              PhosphorIcons.palette(),
              size: 20,
              color: isCustom
                  ? NothingTheme.pillActiveFg(context)
                  : NothingTheme.txtSecondary(context),
            ),
            if (isCustom)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: customColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NothingTheme.pillActiveBg(context),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class CustomColorPicker extends StatefulWidget {
  final String initialHex;
  final ValueChanged<String> onColorSelected;

  const CustomColorPicker({super.key, required this.initialHex, required this.onColorSelected});

  @override
  State<CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  late double _hue;
  late double _brightness;
  final TextEditingController _hexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Color color;
    try {
      color = Color(int.parse('FF${widget.initialHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      color = const Color(0xFFD71921);
    }
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _brightness = hsv.value;
    _hexController.text = widget.initialHex.toUpperCase();
  }

  void _onHueChanged(double hue) {
    setState(() {
      _hue = hue;
      _updateColorFromHSV();
    });
  }

  void _updateColorFromHSV() {
    final color = HSVColor.fromAHSV(1.0, _hue, 1.0, _brightness).toColor();
    final hexString = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    if (_hexController.text != hexString) {
      _hexController.text = hexString;
    }
  }

  void _updateColorFromHex(String hex) {
    final clean = hex.replaceAll('#', '').trim().toUpperCase();
    if (clean.length == 6) {
      try {
        final color = Color(int.parse('FF$clean', radix: 16));
        final hsv = HSVColor.fromColor(color);
        setState(() {
          _hue = hsv.hue;
          _brightness = hsv.value;
        });
      } catch (_) {
        // ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = HSVColor.fromAHSV(1.0, _hue, 1.0, _brightness).toColor();

    // Chrome and grab handle come from AppSheet; this is only the contents.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CUSTOM ACCENT',
            style: NothingType.doto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: NothingTheme.txtPrimary(context),
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 24),

          // Color wheel
          Center(
            child: ColorWheel(currentHue: _hue, onHueChanged: _onHueChanged),
          ),
          const SizedBox(height: 24),

          // Brightness Slider
          Row(
            children: [
              Icon(PhosphorIcons.sunDim(), color: NothingTheme.txtSecondary(context), size: 18),
              Expanded(
                child: Slider(
                  value: _brightness,
                  onChanged: (v) {
                    setState(() {
                      _brightness = v;
                      _updateColorFromHSV();
                    });
                  },
                  activeColor: currentColor,
                  inactiveColor: NothingTheme.slab(context),
                ),
              ),
              Icon(PhosphorIcons.sun(), color: NothingTheme.txtSecondary(context), size: 18),
            ],
          ),
          const SizedBox(height: 16),

          // Hex Input and Preview
          Row(
            children: [
              // Color preview box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NothingTheme.divider(context).withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: 16),

              // Input field
              Expanded(
                child: TextField(
                  controller: _hexController,
                  style: NothingType.archivo(fontSize: 14, color: NothingTheme.txtPrimary(context)),
                  onChanged: _updateColorFromHex,
                  decoration: InputDecoration(
                    hintText: 'HEX CODE (e.g. #D71921)',
                    hintStyle: NothingType.archivo(
                      fontSize: 14,
                      color: NothingTheme.txtMuted(context),
                    ),
                    filled: true,
                    fillColor: NothingTheme.slab(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onColorSelected(_hexController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                foregroundColor: ThemeData.estimateBrightnessForColor(currentColor) == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'APPLY COLOR',
                style: NothingType.archivo(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorWheel extends StatefulWidget {
  final double currentHue;
  final ValueChanged<double> onHueChanged;

  const ColorWheel({super.key, required this.currentHue, required this.onHueChanged});

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handleDrag,
      onPanDown: _handleTap,
      child: CustomPaint(
        size: const Size(200, 200),
        painter: _ColorWheelPainter(currentHue: widget.currentHue),
      ),
    );
  }

  void _handleDrag(DragUpdateDetails details) {
    _updateColor(details.localPosition);
  }

  void _handleTap(DragDownDetails details) {
    _updateColor(details.localPosition);
  }

  void _updateColor(Offset localPosition) {
    final center = const Offset(100, 100);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    final hue = angle * 180 / math.pi;
    widget.onHueChanged(hue);
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double currentHue;
  _ColorWheelPainter({required this.currentHue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: List.generate(
          360,
          (index) => HSVColor.fromAHSV(1.0, index.toDouble(), 1.0, 1.0).toColor(),
        ),
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 10, paint);

    final angle = currentHue * math.pi / 180;
    final indicatorRadius = radius - 10;
    final indicatorCenter = Offset(
      center.dx + math.cos(angle) * indicatorRadius * 0.75,
      center.dy + math.sin(angle) * indicatorRadius * 0.75,
    );

    final cursorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(indicatorCenter, 10, cursorPaint);

    final cursorBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(indicatorCenter, 11, cursorBgPaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.currentHue != currentHue;
  }
}
