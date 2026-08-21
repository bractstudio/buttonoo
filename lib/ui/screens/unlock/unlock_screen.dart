import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../models/status.dart';
import '../../../native/remapper_channel.dart';
import '../../theme/nothing_theme.dart';
import '../../theme/nothing_type.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/section_label.dart';
import '../../widgets/slab_group.dart';
import '../../widgets/slab_tile.dart';
import '../../widgets/status_dot.dart';
import 'pairing_sheet.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> with WidgetsBindingObserver {
  final RemapperChannel _channel = RemapperChannel();
  List<PackageState> _packageStates = [];
  ShizukuState _shizuku = ShizukuState.notInstalled;
  bool _loading = true;
  // A ValueNotifier rather than setState: the pairing sheet is its own route, so
  // calling setState here would never rebuild it.
  final ValueNotifier<List<String>> _adbLogs = ValueNotifier<List<String>>([]);
  StreamSubscription<String>? _adbSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnlockStatus();
    _channel.startAdbDiscovery();
    _adbSub = _channel.adbProgress().listen((log) {
      _adbLogs.value = [..._adbLogs.value, log];
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.stopAdbDiscovery();
    _adbSub?.cancel();
    _adbLogs.dispose();
    super.dispose();
  }

  /// The user leaves this screen to toggle things in Settings, and an OS update
  /// can silently re-enable the packages. Re-read on every resume so the UI
  /// self-heals rather than showing a stale snapshot.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnlockStatus();
  }

  Future<void> _loadUnlockStatus() async {
    final states = await _channel.unlockStates();
    final shizuku = await _channel.shizukuState();
    if (!mounted) return;
    setState(() {
      _packageStates = states;
      _shizuku = shizuku;
      _loading = false;
    });
  }

  List<PackageState> get _installed => _packageStates.where((p) => p.installed).toList();

  List<PackageState> get _stillActive => _installed.where((p) => !p.freed).toList();

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: NothingType.archivo(fontSize: 13)),
          backgroundColor: NothingTheme.slab(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _onShizukuTap() async {
    switch (_shizuku) {
      case ShizukuState.notInstalled:
        _toast('Shizuku is not installed. Use Settings or Wi-Fi pairing instead.');
      case ShizukuState.notRunning:
        _toast('Shizuku is installed but not running. Start it, then come back.');
      case ShizukuState.needsPermission:
        final asked = await _channel.requestShizukuPermission();
        if (!asked) {
          _toast('Shizuku denied the request. Grant it inside the Shizuku app.');
        }
        await _loadUnlockStatus();
      case ShizukuState.ready:
        final ok = await _channel.runShizukuUnlock();
        _toast(ok ? 'Single press is free.' : 'Shizuku could not disable the packages.');
        await _loadUnlockStatus();
    }
  }

  Future<void> _onRestore() async {
    final route = await _channel.restoreEssentialSpace();
    _toast(switch (route) {
      'shizuku' => 'Essential Space restored via Shizuku.',
      'adb' => 'Essential Space restored over Wi-Fi ADB.',
      _ => 'Tap Enable on each App Info page to restore.',
    });
    await _loadUnlockStatus();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _stillActive.length;
    final allFreed = _installed.isNotEmpty && remaining == 0;

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
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
                    allFreed ? 'KEY FREED' : 'FREE THE KEY',
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allFreed ? 'SINGLE PRESS IS YOURS' : 'SINGLE PRESS IS SHARED',
                                  style: NothingType.sectionHeader(
                                    color: allFreed
                                        ? NothingTheme.accentWhite
                                        : NothingTheme.accentRed,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  allFreed
                                      ? 'Essential Space is disabled, so single press runs your action. An OS update can turn it back on — this screen re-checks every time you open it.'
                                      : 'Nothing OS keeps single press for Essential Space. Disable those system apps and it is yours — nothing is uninstalled, and you can put them back.',
                                  style: NothingType.archivo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: NothingTheme.txtSecondary(context),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SlabGroup(children: _packageTiles()),
                                const SectionLabel(
                                  text: 'IF THAT IS BLOCKED',
                                  padding: EdgeInsets.only(top: 22, bottom: 12),
                                ),
                                SlabGroup(
                                  children: [
                                    SlabTile(
                                      onTap: () => _showAdbSheet(context),
                                      title: 'Pair over Wi-Fi',
                                      trailing: _trailing('ADB'),
                                    ),
                                    SlabTile(
                                      onTap: _onShizukuTap,
                                      title: 'Use Shizuku',
                                      trailing: _trailing(_shizuku.label),
                                    ),
                                    SlabTile(
                                      onTap: () => _showPcCommandsDialog(context),
                                      title: 'Commands for a PC',
                                      trailing: _trailing(null),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                if (!allFreed)
                                  NothingButton(
                                    text: 'Open App Info · $remaining left',
                                    isRed: true,
                                    onPressed: _stillActive.isEmpty
                                        ? null
                                        : () async {
                                            await _channel.openAppInfo(
                                              _stillActive.first.packageName,
                                            );
                                          },
                                  ),
                                if (allFreed)
                                  NothingButton(
                                    text: 'Restore Essential Space',
                                    isRed: false,
                                    onPressed: _onRestore,
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _packageTiles() {
    final tiles = <Widget>[
      SlabTile(
        title: 'Do it from Settings',
        trailing: Text(
          'RECOMMENDED',
          style: NothingType.archivo(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: NothingTheme.accentRed,
            letterSpacing: 1.4,
          ),
        ),
      ),
    ];

    if (_installed.isEmpty) {
      tiles.add(
        SlabTile(
          title: 'No consumer packages',
          subtitle: 'This device has nothing holding the single press.',
        ),
      );
      return tiles;
    }

    for (final pkg in _installed) {
      tiles.add(
        SlabTile(
          onTap: () => _channel.openAppInfo(pkg.packageName),
          leading: StatusDot(
            active: !pkg.freed,
            activeColor: NothingTheme.accentRed,
            inactiveColor: NothingTheme.accentWhite,
            size: 7,
          ),
          title: pkg.packageName.split('.').last,
          trailing: Text(
            pkg.freed ? 'DISABLED' : 'OPEN',
            style: NothingType.archivo(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: pkg.freed ? NothingTheme.txtMuted(context) : NothingTheme.accentRed,
              letterSpacing: 1.4,
            ),
          ),
        ),
      );
    }
    return tiles;
  }

  Widget _trailing(String? label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null)
        Text(
          label,
          style: NothingType.archivo(fontSize: 12, color: NothingTheme.txtMuted(context)),
        ),
      if (label != null) const SizedBox(width: 8),
      Icon(PhosphorIcons.caretRight, color: NothingTheme.txtMuted(context), size: 16),
    ],
  );

  /// Pairing sheet lives in its own StatefulWidget so it owns (and disposes)
  /// its controller — see pairing_sheet.dart.
  void _showAdbSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => PairingSheet(channel: _channel, logs: _adbLogs, onChanged: _loadUnlockStatus),
    );
  }

  void _showPcCommandsDialog(BuildContext context) {
    // Built from the packages the platform actually reports, so the commands can
    // never name something that is not on this device.
    final targets = _installed.isEmpty ? _packageStates : _installed;
    final commands = targets
        .map((p) => 'adb shell pm disable-user --user 0 ${p.packageName}')
        .join('\n');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NothingTheme.slab(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('PC ADB Commands', style: NothingType.doto(fontSize: 18)),
        content: SelectableText(
          commands.isEmpty ? 'Nothing to disable on this device.' : commands,
          style: NothingType.archivo(fontSize: 11, color: NothingTheme.txtSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: commands));
              if (ctx.mounted) Navigator.pop(ctx);
              _toast('Commands copied.');
            },
            child: Text(
              'COPY',
              style: NothingType.archivo(
                color: NothingTheme.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: NothingType.archivo(color: NothingTheme.accentWhite)),
          ),
        ],
      ),
    );
  }
}
