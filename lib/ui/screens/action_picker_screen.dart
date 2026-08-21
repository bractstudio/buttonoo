import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/gesture.dart';
import '../../models/key_action.dart';
import '../../state/app_scope.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_sheet.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import 'activity_picker_screen.dart';
import 'app_picker_screen.dart';
import 'apps_column_picker_screen.dart';
import 'shortcut_picker_screen.dart';

/// Opens the action picker over whatever is on screen.
Future<void> showActionPicker(
  BuildContext context, {
  required KeyGesture gesture,
  required ActionSpec currentAction,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => ActionPicker(gesture: gesture, currentAction: currentAction),
  );
}

class ActionPicker extends StatefulWidget {
  final KeyGesture gesture;
  final ActionSpec currentAction;

  const ActionPicker({super.key, required this.gesture, required this.currentAction});

  @override
  State<ActionPicker> createState() => _ActionPickerState();
}

class _ActionPickerState extends State<ActionPicker> {
  String _searchQuery = '';

  Future<void> _selectAction(ActionSpec spec) async {
    await AppScope.configReadOf(context).setAction(widget.gesture, spec);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Leaves the top of the screen showing, so it reads as a sheet over the
    // gesture list rather than a page that replaced it.
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gesture Name Badge
            Text(
              widget.gesture.label.toUpperCase(),
              style: NothingType.sectionHeader(color: NothingTheme.accentRed),
            ),
            const SizedBox(height: 10),

            // Header Title in Doto Font
            Text(
              'CHOOSE ACTION',
              style: NothingType.doto(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: NothingTheme.txtPrimary(context),
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar Input
            Container(
              decoration: BoxDecoration(
                color: NothingTheme.slab(context),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: TextField(
                style: NothingType.archivo(fontSize: 14, color: NothingTheme.txtPrimary(context)),
                onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
                decoration: InputDecoration(
                  icon: Icon(
                    PhosphorIcons.magnifyingGlass,
                    color: NothingTheme.txtMuted(context),
                    size: 18,
                  ),
                  hintText: 'Search actions and apps',
                  hintStyle: NothingType.archivo(
                    fontSize: 14,
                    color: NothingTheme.txtMuted(context),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Quick Actions Slab Group
            SlabGroup(
              children: [
                _buildActionTile(
                  'Toggle flashlight',
                  PhosphorIcons.flashlight,
                  const QuickActionSpec('flashlight'),
                ),
                _buildActionTile(
                  'Open camera',
                  PhosphorIcons.camera,
                  const QuickActionSpec('camera'),
                ),
                _buildActionTile(
                  'Volume up',
                  PhosphorIcons.speakerHigh,
                  const QuickActionSpec('volume_up'),
                ),
                _buildActionTile(
                  'Volume down',
                  PhosphorIcons.speakerLow,
                  const QuickActionSpec('volume_down'),
                ),
                _buildActionTile(
                  'Toggle mute',
                  PhosphorIcons.speakerSlash,
                  const QuickActionSpec('volume_mute'),
                ),
                _buildActionTile(
                  'Volume control panel',
                  PhosphorIcons.sliders,
                  const QuickActionSpec('volume_slider'),
                ),
                _buildActionTile(
                  'Increase brightness',
                  PhosphorIcons.sun,
                  const QuickActionSpec('brightness_up'),
                ),
                _buildActionTile(
                  'Decrease brightness',
                  PhosphorIcons.sunDim,
                  const QuickActionSpec('brightness_down'),
                ),
                _buildActionTile(
                  'Cycle ringer mode',
                  PhosphorIcons.bellRinging,
                  const QuickActionSpec('ring_vibrate'),
                ),
                _buildActionTile(
                  'Do not disturb',
                  PhosphorIcons.minusCircle,
                  const QuickActionSpec('dnd'),
                ),
                _buildActionTile(
                  'Voice assistant',
                  PhosphorIcons.microphone,
                  const QuickActionSpec('assistant'),
                ),
                _buildActionTile(
                  'Media play / pause',
                  PhosphorIcons.play,
                  const QuickActionSpec('media_play_pause'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Apps & Systems Slab Group
            SlabGroup(
              children: [
                SlabTile(
                  onTap: () async {
                    final currentApps = widget.currentAction is AppsColumnActionSpec
                        ? widget.currentAction as AppsColumnActionSpec
                        : const AppsColumnActionSpec([]);
                    final result = await Navigator.push<AppsColumnActionSpec>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppsColumnPickerScreen(initialSpec: currentApps),
                      ),
                    );
                    if (result != null) _selectAction(result);
                  },
                  leading: Icon(
                    PhosphorIcons.columns,
                    color: NothingTheme.txtSecondary(context),
                    size: 18,
                  ),
                  title: 'Apps Column',
                  trailing: Icon(
                    PhosphorIcons.caretRight,
                    color: NothingTheme.txtMuted(context),
                    size: 16,
                  ),
                ),
                SlabTile(
                  onTap: () async {
                    final result = await Navigator.push<AppActionSpec>(
                      context,
                      MaterialPageRoute(builder: (_) => const AppPickerScreen()),
                    );
                    if (result != null) _selectAction(result);
                  },
                  leading: Icon(
                    PhosphorIcons.squaresFour,
                    color: NothingTheme.txtSecondary(context),
                    size: 18,
                  ),
                  title: 'Launch an app',
                  trailing: Icon(
                    PhosphorIcons.caretRight,
                    color: NothingTheme.txtMuted(context),
                    size: 16,
                  ),
                ),
                SlabTile(
                  onTap: () async {
                    final result = await Navigator.push<ShortcutActionSpec>(
                      context,
                      MaterialPageRoute(builder: (_) => const ShortcutPickerScreen()),
                    );
                    if (result != null) _selectAction(result);
                  },
                  leading: Icon(
                    PhosphorIcons.arrowSquareOut,
                    color: NothingTheme.txtSecondary(context),
                    size: 18,
                  ),
                  title: 'App shortcut',
                  trailing: Icon(
                    PhosphorIcons.caretRight,
                    color: NothingTheme.txtMuted(context),
                    size: 16,
                  ),
                ),
                SlabTile(
                  onTap: () async {
                    final result = await Navigator.push<ActivityActionSpec>(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityPickerScreen()),
                    );
                    if (result != null) _selectAction(result);
                  },
                  leading: Icon(
                    PhosphorIcons.code,
                    color: NothingTheme.txtSecondary(context),
                    size: 18,
                  ),
                  title: 'Specific activity',
                  trailing: Icon(
                    PhosphorIcons.caretRight,
                    color: NothingTheme.txtMuted(context),
                    size: 16,
                  ),
                ),
                SlabTile(
                  onTap: () => _selectAction(const NoneActionSpec()),
                  leading: Icon(
                    PhosphorIcons.xCircle,
                    color: NothingTheme.txtSecondary(context),
                    size: 18,
                  ),
                  title: 'Clear this gesture',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, ActionSpec spec) {
    if (_searchQuery.isNotEmpty && !title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    final isSelected = widget.currentAction.toJson().toString() == spec.toJson().toString();

    return SlabTile(
      onTap: () => _selectAction(spec),
      backgroundColor: isSelected ? NothingTheme.accentRed : NothingTheme.slab(context),
      titleColor: isSelected ? Colors.white : NothingTheme.txtPrimary(context),
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : NothingTheme.txtSecondary(context),
        size: 18,
      ),
      title: title,
      trailing: isSelected ? Icon(PhosphorIcons.check, color: Colors.white, size: 18) : null,
    );
  }
}
