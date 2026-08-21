import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/gesture.dart';
import '../../models/key_action.dart';
import '../../models/status.dart';
import '../../native/remapper_channel.dart';
import '../../state/app_scope.dart';
import '../../state/permissions_controller.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import '../widgets/status_dot.dart';
import 'action_picker_screen.dart';
import 'gesture_timing_screen.dart';
import 'overlay_settings_screen.dart';
import 'settings_screen.dart';
import 'unlock/unlock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Map<String, String> _accentNames = {
    'D71921': 'Red',
    'FBFBF9': 'White',
    'FFD300': 'Yellow',
  };

  String _colorHexToName(String hex) =>
      _accentNames[hex.replaceAll('#', '').toUpperCase()] ?? 'Custom';

  /// What a gesture tile says it will do. Falls back to the package name when a
  /// label is missing, which happens if the app was uninstalled after assignment.
  static String _actionTitle(ActionSpec action, Map<String, String> appNames) {
    String name(String package) => appNames[package] ?? package;

    return switch (action) {
      NoneActionSpec() => 'Not assigned',
      AppActionSpec(:final packageName) => 'Open ${name(packageName)}',
      ShortcutActionSpec(:final packageName, :final shortcutId) =>
        '${name(packageName)}: $shortcutId',
      ActivityActionSpec(:final className) => 'Activity: ${className.split('.').last}',
      AppsColumnActionSpec(:final packageNames) => 'Apps: ${packageNames.map(name).join(', ')}',
      _ => action.displayTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = AppScope.configOf(context);
    final permissions = AppScope.permissionsOf(context);

    final cfg = config.config;
    final status = permissions.status;
    final enabled = cfg?.enabled ?? true;
    final running = status?.serviceRunning ?? false;
    final isFreed = status?.isFreed ?? false;

    Future<void> reload() async {
      await Future.wait([config.load(), permissions.refresh()]);
    }

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: config.loading
            ? const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed))
            : RefreshIndicator(
                color: NothingTheme.accentRed,
                onRefresh: reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      // Header Row with App Title & Settings Gear Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BUTTONOO',
                            style: NothingType.doto(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: NothingTheme.txtPrimary(context),
                              letterSpacing: 0.08,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.gear,
                              color: NothingTheme.txtPrimary(context),
                              size: 24,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                              permissions.refresh();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (status != null && (!status.serviceRunning || !status.overlayPermission)) ...[
                        _buildPermissionWarningBanner(context, status, permissions),
                        const SizedBox(height: 22),
                      ],

                      // Status & Lock Slab Group
                      SlabGroup(
                        children: [
                          // Master Service Switch Row
                          SlabTile(
                            leading: StatusDot(
                              active: running && enabled,
                              activeColor: NothingTheme.accentRed,
                              inactiveColor: NothingTheme.txtSecondary(context),
                            ),
                            title: enabled ? 'Remapper running' : 'Remapper disabled',
                            trailing: Switch(
                              value: enabled,
                              activeThumbColor: NothingTheme.pillActiveBg(context),
                              activeTrackColor: NothingTheme.accentRed,
                              inactiveThumbColor: NothingTheme.txtMuted(context),
                              inactiveTrackColor: NothingTheme.disabledBg(context),
                              onChanged: (v) async {
                                await config.setEnabled(v);
                                permissions.refresh();
                              },
                            ),
                          ),
                          // Unlock / Tier Status Row
                          SlabTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UnlockScreen()),
                              );
                              permissions.refresh();
                            },
                            leading: Icon(
                              isFreed ? PhosphorIcons.lockKeyOpen : PhosphorIcons.lockKey,
                              color: NothingTheme.txtSecondary(context),
                              size: 18,
                            ),
                            title: isFreed ? 'Single press is yours' : 'Single press is shared',
                            subtitle: isFreed
                                ? '3 system apps disabled'
                                : 'Tap to free key from Nothing OS',
                            trailing: Icon(
                              PhosphorIcons.caretRight,
                              color: NothingTheme.txtMuted(context),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Gestures Slab Group
                      SlabGroup(
                        children: [
                          _buildGestureTile(
                            context,
                            gesture: KeyGesture.singlePress,
                            badgeText: '1×',
                            badgeColor: NothingTheme.accentRed,
                            subtitle: 'Single press',
                          ),
                          _buildGestureTile(
                            context,
                            gesture: KeyGesture.doublePress,
                            badgeText: '2×',
                            badgeColor: NothingTheme.accentRed,
                            subtitle: 'Double press',
                          ),
                          _buildGestureTile(
                            context,
                            gesture: KeyGesture.triplePress,
                            badgeText: '3×',
                            badgeColor: NothingTheme.txtMuted(context),
                            subtitle: 'Triple press',
                          ),
                          _buildGestureTile(
                            context,
                            gesture: KeyGesture.quadruplePress,
                            badgeText: '4×',
                            badgeColor: NothingTheme.accentRed,
                            subtitle: 'Quadruple press',
                          ),
                          _buildGestureTile(
                            context,
                            gesture: KeyGesture.longPress,
                            badgeText: 'Hold',
                            badgeColor: NothingTheme.accentRed,
                            subtitle: 'After 500 ms',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Settings & Navigation Slab Group
                      SlabGroup(
                        children: [
                          SlabTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OverlaySettingsScreen()),
                              );
                              permissions.refresh();
                            },
                            leading: Icon(
                              PhosphorIcons.stack,
                              color: NothingTheme.txtSecondary(context),
                              size: 18,
                            ),
                            title: 'Overlay',
                            subtitle: cfg == null
                                ? 'Glow · Red · 34%'
                                : '${cfg.overlay.glow ? "Glow" : "Minimal"} · ${_colorHexToName(cfg.overlay.accentHex)} · ${(cfg.anchorFraction * 100).round()}%',
                            trailing: Icon(
                              PhosphorIcons.caretRight,
                              color: NothingTheme.txtMuted(context),
                              size: 16,
                            ),
                          ),
                          SlabTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GestureTimingScreen()),
                              );
                              permissions.refresh();
                            },
                            leading: Icon(
                              PhosphorIcons.clock,
                              color: NothingTheme.txtSecondary(context),
                              size: 18,
                            ),
                            title: 'Behaviour',
                            subtitle: 'Timing, lock screen, haptics',
                            trailing: Icon(
                              PhosphorIcons.caretRight,
                              color: NothingTheme.txtMuted(context),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGestureTile(
    BuildContext context, {
    required KeyGesture gesture,
    required String badgeText,
    required Color badgeColor,
    required String subtitle,
  }) {
    final config = AppScope.configOf(context);
    final action = config.config?.actions[gesture] ?? const NoneActionSpec();
    final isUnassigned = action is NoneActionSpec;

    return SlabTile(
      onTap: () => showActionPicker(context, gesture: gesture, currentAction: action),
      leading: SizedBox(
        width: 48,
        child: Text(
          badgeText,
          style: NothingType.doto(
            fontSize: badgeText == 'Hold' ? 16 : 20,
            fontWeight: FontWeight.w800,
            color: isUnassigned ? NothingTheme.txtMuted(context) : badgeColor,
          ),
        ),
      ),
      title: _actionTitle(action, config.appNames),
      titleColor: isUnassigned ? NothingTheme.txtMuted(context) : NothingTheme.txtPrimary(context),
      subtitle: subtitle,
    );
  }

  Widget _buildPermissionWarningBanner(
    BuildContext context,
    ServiceStatus status,
    PermissionsController permissions,
  ) {
    final hasAccessibility = status.serviceRunning;
    final hasOverlay = status.overlayPermission;
    final channel = RemapperChannel();

    List<Widget> actions = [];
    if (!hasAccessibility) {
      actions.add(
        _buildBannerButton(
          context,
          text: 'Grant Accessibility',
          onTap: () async {
            await channel.openAccessibilitySettings();
            permissions.refresh();
          },
        ),
      );
    }
    if (!hasOverlay) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        _buildBannerButton(
          context,
          text: 'Grant Overlay',
          onTap: () async {
            await channel.openOverlayPermission();
            permissions.refresh();
          },
        ),
      );
    }

    String message = '';
    if (!hasAccessibility && !hasOverlay) {
      message = 'Accessibility service & Draw over other apps permissions are required for BUTTONOO to work.';
    } else if (!hasAccessibility) {
      message = 'Accessibility service permission is required to detect button presses.';
    } else {
      message = 'Draw over other apps permission is required to display the custom overlays.';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: NothingTheme.slab(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NothingTheme.accentRed.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.warning,
                color: NothingTheme.accentRed,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'COMPULSORY PERMISSIONS MISSING',
                  style: NothingType.doto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NothingTheme.accentRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: NothingType.archivo(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: NothingTheme.txtPrimary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerButton(
    BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: NothingTheme.accentRed,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            text,
            style: NothingType.archivo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
