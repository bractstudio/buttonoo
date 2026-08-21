import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/gesture.dart';
import '../../models/key_action.dart';
import '../../state/app_scope.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/nothing_segmented_control.dart';
import '../widgets/searcho_slider_tile.dart';
import '../widgets/section_label.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';

class GestureTimingScreen extends StatelessWidget {
  const GestureTimingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.configOf(context);
    final config = controller.config;

    final longPressMs = config?.longPressMs ?? 500;
    final multiTapMs = config?.multiTapMs ?? 400;
    final hapticsEnabled = config?.hapticsEnabled ?? true;
    final hapticIntensity = config?.hapticsIntensity ?? 'medium';

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowLeft,
                      color: NothingTheme.txtPrimary(context),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BEHAVIOUR',
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

            Expanded(
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timing Slab Group
                          SlabGroup(
                            children: [
                              SearchoSliderTile(
                                title: 'Long press after',
                                label: '$longPressMs ms',
                                value: longPressMs.toDouble(),
                                min: 300,
                                max: 1200,
                                divisions: 18,
                                onChanged: (v) => controller.setTiming(
                                  longPressMs: v.toInt(),
                                  multiTapMs: multiTapMs,
                                ),
                              ),
                              SearchoSliderTile(
                                title: 'Multi-tap window',
                                label: '$multiTapMs ms',
                                value: multiTapMs.toDouble(),
                                min: 200,
                                max: 800,
                                divisions: 12,
                                onChanged: (v) => controller.setTiming(
                                  longPressMs: longPressMs,
                                  multiTapMs: v.toInt(),
                                ),
                              ),
                              // Explanatory Note Tile
                              Container(
                                color: NothingTheme.slab(context),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                child: Text(
                                  'With double and triple press unassigned, single press fires the moment you let go.',
                                  style: NothingType.archivo(
                                    fontSize: 12.5,
                                    color: NothingTheme.txtSecondary(context),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SectionLabel(
                            text: 'ALLOWED WHILE LOCKED',
                            padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                          ),

                          // Lock Screen Policy Slab Group
                          SlabGroup(
                            children: [
                              _buildLockTile(context, badge: '1×', gesture: KeyGesture.singlePress),
                              _buildLockTile(context, badge: '2×', gesture: KeyGesture.doublePress),
                              _buildLockTile(context, badge: '3×', gesture: KeyGesture.triplePress),
                              _buildLockTile(
                                context,
                                badge: '4×',
                                gesture: KeyGesture.quadruplePress,
                              ),
                              _buildLockTile(context, badge: 'Hold', gesture: KeyGesture.longPress),
                            ],
                          ),

                          const SectionLabel(
                            text: 'HAPTICS',
                            padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                          ),

                          // Haptics Slab Group
                          SlabGroup(
                            children: [
                              SlabTile(
                                title: 'Buzz when an action fires',
                                trailing: Switch(
                                  value: hapticsEnabled,
                                  activeThumbColor: NothingTheme.pillActiveBg(context),
                                  activeTrackColor: NothingTheme.accentRed,
                                  onChanged: (v) =>
                                      controller.setHaptics(enabled: v, intensity: hapticIntensity),
                                ),
                              ),
                              Container(
                                color: NothingTheme.slab(context),
                                padding: const EdgeInsets.all(16.0),
                                child: NothingSegmentedControl<String>(
                                  values: const ['light', 'medium', 'heavy'],
                                  selectedValue: hapticIntensity.toLowerCase(),
                                  childBuilder: (level, selected) => Text(
                                    level.toUpperCase(),
                                    style: NothingType.archivo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? NothingTheme.pillActiveFg(context)
                                          : NothingTheme.txtSecondary(context),
                                    ),
                                  ),
                                  onChanged: (level) => controller.setHaptics(
                                    enabled: hapticsEnabled,
                                    intensity: level,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockTile(
    BuildContext context, {
    required String badge,
    required KeyGesture gesture,
  }) {
    final controller = AppScope.configOf(context);
    final config = controller.config;
    final action = config?.actions[gesture] ?? const NoneActionSpec();
    final isUnassigned = action is NoneActionSpec;
    final title = isUnassigned ? 'Not assigned' : action.displayTitle;
    final allowed = config?.lockPolicy[gesture] ?? false;

    return SlabTile(
      leading: SizedBox(
        width: 34,
        child: Text(
          badge,
          style: NothingType.doto(
            fontSize: badge == 'Hold' ? 12 : 14,
            color: isUnassigned
                ? NothingTheme.txtMuted(context)
                : NothingTheme.txtSecondary(context),
          ),
        ),
      ),
      title: title,
      titleColor: isUnassigned ? NothingTheme.txtMuted(context) : NothingTheme.txtPrimary(context),
      trailing: Switch(
        value: allowed,
        activeThumbColor: NothingTheme.pillActiveBg(context),
        activeTrackColor: NothingTheme.accentRed,
        inactiveThumbColor: isUnassigned
            ? NothingTheme.disabledTh(context)
            : NothingTheme.txtMuted(context),
        inactiveTrackColor: isUnassigned
            ? NothingTheme.disabledBg(context)
            : NothingTheme.divider(context),
        onChanged: isUnassigned
            ? null
            : (v) => controller.setLockPolicy({...?config?.lockPolicy, gesture: v}),
      ),
    );
  }
}
