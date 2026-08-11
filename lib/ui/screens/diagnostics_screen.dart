import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../native/remapper_channel.dart';
import '../../state/app_scope.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/section_label.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import '../widgets/status_dot.dart';
import 'backup_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final RemapperChannel _channel = RemapperChannel();
  bool _learnMode = false;
  final List<String> _keyEvents = [];
  StreamSubscription? _keySub;

  @override
  void initState() {
    super.initState();
    _keySub = _channel.keyEvents().listen((event) {
      if (!mounted || !_learnMode) return;
      final action = event.action == 0 ? 'DOWN' : 'UP';
      setState(() {
        _keyEvents.insert(0, '$action · key ${event.scanCode} · ${event.eventTime}');
        if (_keyEvents.length > 20) _keyEvents.removeLast();
      });
    });
  }

  Future<void> _toggleLearnMode(bool v) async {
    setState(() => _learnMode = v);
    await _channel.setLearnMode(v);
  }

  @override
  void dispose() {
    _keySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = AppScope.permissionsOf(context);
    final status = permissions.status;

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: NothingTheme.txtPrimary(context),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DIAGNOSTICS',
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
              child: permissions.loading
                  ? const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Permissions Header & Counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PERMISSIONS',
                                style: NothingType.sectionHeader(
                                  color: NothingTheme.txtMuted(context),
                                ),
                              ),
                              Text(
                                '${status?.grantedCount ?? 0} of ${status?.permissionCount ?? 5}',
                                style: NothingType.sectionHeader(
                                  color: NothingTheme.txtSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Permissions Slab Group
                          SlabGroup(
                            children: [
                              SlabTile(
                                onTap: _channel.openAccessibilitySettings,
                                leading: StatusDot(
                                  active: status?.serviceRunning ?? false,
                                  activeColor: NothingTheme.pillActiveBg(context),
                                  inactiveColor: NothingTheme.accentRed,
                                  size: 7,
                                ),
                                title: 'Accessibility service',
                              ),
                              SlabTile(
                                onTap: _channel.openOverlayPermission,
                                leading: StatusDot(
                                  active: status?.overlayPermission ?? false,
                                  activeColor: NothingTheme.pillActiveBg(context),
                                  inactiveColor: NothingTheme.accentRed,
                                  size: 7,
                                ),
                                title: 'Draw over other apps',
                              ),
                              SlabTile(
                                onTap: _channel.openWriteSettings,
                                leading: StatusDot(
                                  active: status?.writeSettingsPermission ?? false,
                                  activeColor: NothingTheme.pillActiveBg(context),
                                  inactiveColor: NothingTheme.accentRed,
                                  size: 7,
                                ),
                                title: 'Write system settings',
                              ),
                              SlabTile(
                                onTap: _channel.openDndAccess,
                                leading: StatusDot(
                                  active: status?.notificationPolicyPermission ?? false,
                                  activeColor: NothingTheme.pillActiveBg(context),
                                  inactiveColor: NothingTheme.accentRed,
                                  size: 7,
                                ),
                                title: 'Do not disturb access',
                              ),
                              SlabTile(
                                onTap: _channel.openBatteryOptimization,
                                leading: StatusDot(
                                  active: status?.batteryOptimizationIgnored ?? false,
                                  activeColor: NothingTheme.pillActiveBg(context),
                                  inactiveColor: NothingTheme.accentRed,
                                  size: 7,
                                ),
                                title: 'Battery unrestricted',
                              ),
                            ],
                          ),

                          const SectionLabel(
                            text: 'KEY TEST',
                            padding: EdgeInsets.only(top: 24, bottom: 12),
                          ),

                          // Key Test Slab Group
                          SlabGroup(
                            children: [
                              SlabTile(
                                title: 'Learn mode',
                                subtitle: 'Log presses, fire nothing',
                                trailing: Switch(
                                  value: _learnMode,
                                  activeThumbColor: NothingTheme.pillActiveBg(context),
                                  activeTrackColor: NothingTheme.accentRed,
                                  onChanged: (v) => _toggleLearnMode(v),
                                ),
                              ),

                              // Terminal Monospace Event Box
                              Container(
                                color: NothingTheme.slab(context),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _keyEvents.isEmpty
                                      ? [
                                          Text(
                                            'Press Essential Key to capture raw key events...',
                                            style: NothingType.archivo(
                                              fontSize: 12,
                                              color: NothingTheme.txtMuted(context),
                                            ),
                                          ),
                                        ]
                                      : _keyEvents.map((evt) {
                                          final isDown = evt.contains('DOWN');
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11,
                                                  height: 1.9,
                                                  color: NothingTheme.txtSecondary(context),
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: isDown ? 'DOWN' : 'UP',
                                                    style: TextStyle(
                                                      color: isDown
                                                          ? NothingTheme.accentRed
                                                          : NothingTheme.txtMuted(context),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: evt.replaceFirst(
                                                      isDown ? 'DOWN' : 'UP',
                                                      '',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                ),
                              ),

                              SlabTile(
                                onTap: () => setState(() => _keyEvents.clear()),
                                title: 'Clear log',
                                titleColor: NothingTheme.txtSecondary(context),
                                trailing: Icon(
                                  PhosphorIcons.trash(),
                                  color: NothingTheme.txtSecondary(context),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),

                          const SectionLabel(
                            text: 'BACKUP',
                            padding: EdgeInsets.only(top: 24, bottom: 12),
                          ),

                          SlabGroup(
                            children: [
                              SlabTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                                ),
                                title: 'Backup & restore',
                                subtitle: 'Export or import the whole configuration',
                                trailing: Icon(
                                  PhosphorIcons.arrowsDownUp(),
                                  color: NothingTheme.txtSecondary(context),
                                  size: 18,
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
}
