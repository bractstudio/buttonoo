import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_config.dart';
import '../../native/remapper_channel.dart';
import '../../state/app_scope.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/nothing_button.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final RemapperChannel _channel = RemapperChannel();
  final TextEditingController _jsonController = TextEditingController();

  Future<void> _exportJson() async {
    final cfg = await _channel.getConfig();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(cfg.toJson());
    setState(() => _jsonController.text = jsonStr);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration exported & copied to clipboard!')),
      );
    }
  }

  Future<void> _importJson() async {
    try {
      final jsonMap = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      final config = AppConfig.fromJson(jsonMap);
      await _channel.setEnabled(config.enabled);
      await _channel.setScanCode(config.scanCode);
      await _channel.setAnchor(config.anchorEdge, config.anchorFraction);
      await _channel.setTiming(longPressMs: config.longPressMs, multiTapMs: config.multiTapMs);
      await _channel.setOverlay(config.overlay);
      await _channel.setLockPolicy(config.lockPolicy);
      await _channel.setHaptics(enabled: config.hapticsEnabled, intensity: config.hapticsIntensity);
      for (final entry in config.actions.entries) {
        await _channel.setAction(entry.key, entry.value);
      }
      // Written straight through the channel, so the controller still holds the
      // pre-import config until it re-reads.
      if (mounted) await AppScope.configReadOf(context).load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configuration imported successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      appBar: AppBar(title: Text('BACKUP & RESTORE', style: NothingType.doto(fontSize: 18))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export or import your full buttonoo configuration as JSON.',
              style: NothingType.archivo(color: NothingTheme.txtSecondary(context), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                style: NothingType.archivo(color: NothingTheme.txtPrimary(context), fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Paste JSON backup here...',
                  hintStyle: NothingType.archivo(
                    color: NothingTheme.txtMuted(context),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: NothingTheme.slab(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NothingButton(text: 'Export JSON', isRed: true, onPressed: _exportJson),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NothingButton(
                    text: 'Import JSON',
                    isPrimary: false,
                    onPressed: _importJson,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
