import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../native/remapper_channel.dart';
import '../../state/app_scope.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import 'slab_group.dart';
import 'slab_tile.dart';
import 'status_dot.dart';

class DiagnosticsSheet extends StatelessWidget {
  const DiagnosticsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = AppScope.permissionsOf(context);
    final status = permissions.status;
    final channel = RemapperChannel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIAGNOSTICS',
                style: NothingType.doto(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: NothingTheme.txtPrimary(context),
                  letterSpacing: 0.08,
                ),
              ),
              if (status != null)
                Text(
                  '${status.grantedCount} OF ${status.permissionCount}',
                  style: NothingType.doto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: NothingTheme.txtSecondary(context),
                    letterSpacing: 0.05,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          permissions.loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(color: NothingTheme.accentRed),
                  ),
                )
              : SlabGroup(
                  children: [
                    SlabTile(
                      onTap: () async {
                        await channel.openAccessibilitySettings();
                        permissions.refresh();
                      },
                      leading: StatusDot(
                        active: status?.serviceRunning ?? false,
                        activeColor: NothingTheme.pillActiveBg(context),
                        inactiveColor: NothingTheme.accentRed,
                        size: 7,
                      ),
                      title: 'Accessibility service',
                      trailing: Icon(
                        PhosphorIcons.caretRight(),
                        color: NothingTheme.txtMuted(context),
                        size: 16,
                      ),
                    ),
                    SlabTile(
                      onTap: () async {
                        await channel.openOverlayPermission();
                        permissions.refresh();
                      },
                      leading: StatusDot(
                        active: status?.overlayPermission ?? false,
                        activeColor: NothingTheme.pillActiveBg(context),
                        inactiveColor: NothingTheme.accentRed,
                        size: 7,
                      ),
                      title: 'Draw over other apps',
                      trailing: Icon(
                        PhosphorIcons.caretRight(),
                        color: NothingTheme.txtMuted(context),
                        size: 16,
                      ),
                    ),
                    SlabTile(
                      onTap: () async {
                        await channel.openWriteSettings();
                        permissions.refresh();
                      },
                      leading: StatusDot(
                        active: status?.writeSettingsPermission ?? false,
                        activeColor: NothingTheme.pillActiveBg(context),
                        inactiveColor: NothingTheme.accentRed,
                        size: 7,
                      ),
                      title: 'Write system settings',
                      trailing: Icon(
                        PhosphorIcons.caretRight(),
                        color: NothingTheme.txtMuted(context),
                        size: 16,
                      ),
                    ),
                    SlabTile(
                      onTap: () async {
                        await channel.openDndAccess();
                        permissions.refresh();
                      },
                      leading: StatusDot(
                        active: status?.notificationPolicyPermission ?? false,
                        activeColor: NothingTheme.pillActiveBg(context),
                        inactiveColor: NothingTheme.accentRed,
                        size: 7,
                      ),
                      title: 'Do not disturb access',
                      trailing: Icon(
                        PhosphorIcons.caretRight(),
                        color: NothingTheme.txtMuted(context),
                        size: 16,
                      ),
                    ),
                    SlabTile(
                      onTap: () async {
                        await channel.openBatteryOptimization();
                        permissions.refresh();
                      },
                      leading: StatusDot(
                        active: status?.batteryOptimizationIgnored ?? false,
                        activeColor: NothingTheme.pillActiveBg(context),
                        inactiveColor: NothingTheme.accentRed,
                        size: 7,
                      ),
                      title: 'Battery unrestricted',
                      trailing: Icon(
                        PhosphorIcons.caretRight(),
                        color: NothingTheme.txtMuted(context),
                        size: 16,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
