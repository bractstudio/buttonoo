import 'package:flutter/material.dart';
import '../../../native/remapper_channel.dart';
import '../../theme/nothing_theme.dart';
import '../../theme/nothing_type.dart';
import '../../widgets/nothing_button.dart';

/// Wireless-debugging pairing sheet.
///
/// A StatefulWidget rather than a closure passed to the sheet builder, so it owns
/// its [TextEditingController] and disposes it after the route is gone. Disposing
/// from the caller runs while the sheet is still animating out and the TextField
/// still holds a reference. The `mounted` guards serve the same purpose for a
/// pairing result that arrives after the sheet closes.
class PairingSheet extends StatefulWidget {
  const PairingSheet({
    super.key,
    required this.channel,
    required this.logs,
    required this.onChanged,
  });

  final RemapperChannel channel;
  final ValueNotifier<List<String>> logs;
  final VoidCallback onChanged;

  @override
  State<PairingSheet> createState() => _PairingSheetState();
}

class _PairingSheetState extends State<PairingSheet> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  bool _paired = false;
  bool _checking = true;
  String? _outcome;
  bool _outcomeOk = false;

  @override
  void initState() {
    super.initState();
    _refreshPaired();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _refreshPaired() async {
    final paired = await widget.channel.adbIsPaired();
    if (!mounted) return;
    setState(() {
      _paired = paired;
      _checking = false;
    });
  }

  Future<void> _run(Future<PairingResult> Function() action) async {
    setState(() {
      _busy = true;
      _outcome = null;
    });
    final res = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = res.message;
      _outcomeOk = res.ok;
    });
    widget.onChanged();
    if (res.ok) _refreshPaired();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _paired ? 'Paired with this phone' : 'Pair over Wi-Fi',
              style: NothingType.doto(fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (_checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: NothingTheme.accentRed)),
              )
            else if (_paired)
              ..._pairedBody()
            else
              ..._pairingSteps(),
            const SizedBox(height: 12),
            _logView(),
            if (_outcome != null) ...[
              const SizedBox(height: 10),
              Text(
                _outcome!,
                style: NothingType.archivo(
                  fontSize: 13,
                  color: _outcomeOk ? NothingTheme.accentWhite : NothingTheme.accentRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _pairedBody() => [
    Text(
      'You only pair once. This phone remembers the app, so from now on you just '
      'need Wireless debugging switched on — no code.',
      style: NothingType.subtitle(),
    ),
    const SizedBox(height: 16),
    NothingButton(
      text: _busy ? 'Working…' : 'Disable Essential Space',
      isRed: true,
      onPressed: _busy ? null : () => _run(widget.channel.adbDisable),
    ),
    const SizedBox(height: 10),
    NothingButton(
      text: 'Restore Essential Space',
      isPrimary: false,
      onPressed: _busy
          ? null
          : () async {
              await widget.channel.restoreEssentialSpace();
              widget.onChanged();
              if (mounted) {
                setState(() {
                  _outcome = 'Essential Space restored.';
                  _outcomeOk = true;
                });
              }
            },
    ),
    const SizedBox(height: 10),
    TextButton(
      onPressed: _busy
          ? null
          : () async {
              await widget.channel.adbForgetPairing();
              _refreshPaired();
            },
      child: Text(
        'Forget this pairing',
        style: NothingType.archivo(fontSize: 12, color: NothingTheme.txtMuted(context)),
      ),
    ),
  ];

  List<Widget> _pairingSteps() => [
    Text(
      'This is a one-time setup. You will not need the code again.',
      style: NothingType.subtitle(),
    ),
    const SizedBox(height: 16),
    _Step(
      number: '1',
      title: 'Turn on Wireless debugging',
      body: 'Developer options → Wireless debugging → switch it on.',
      actionLabel: 'OPEN',
      onAction: widget.channel.openWirelessDebugging,
    ),
    _Step(
      number: '2',
      title: 'Tap "Pair device with pairing code"',
      body: 'A dialog shows a 6-digit code. Leave it open — closing it cancels pairing.',
    ),
    _Step(
      number: '3',
      title: 'Type the code',
      body: 'Use the notification that appears, or the box below if the dialog is still up.',
    ),
    const SizedBox(height: 10),
    TextField(
      controller: _code,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: NothingType.archivo(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: '',
        hintText: '6-digit code',
        hintStyle: NothingType.subtitle(),
        filled: true,
        fillColor: NothingTheme.bg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    const SizedBox(height: 14),
    NothingButton(
      text: _busy ? 'Pairing…' : 'Pair & free the key',
      isRed: true,
      onPressed: _busy
          ? null
          : () {
              final code = _code.text.trim();
              if (code.length != 6) {
                setState(() {
                  _outcome = 'The pairing code is 6 digits.';
                  _outcomeOk = false;
                });
                return;
              }
              _run(() => widget.channel.submitPairingCode(code));
            },
    ),
  ];

  Widget _logView() => ValueListenableBuilder<List<String>>(
    valueListenable: widget.logs,
    builder: (context, logs, child) {
      if (logs.isEmpty) return const SizedBox.shrink();
      final recent = logs.skip(logs.length > 8 ? logs.length - 8 : 0);
      return Container(
        constraints: const BoxConstraints(maxHeight: 110),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NothingTheme.bg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          reverse: true,
          child: Text(
            recent.join('\n'),
            style: NothingType.archivo(fontSize: 11, color: NothingTheme.txtMuted(context)),
          ),
        ),
      );
    },
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String number;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: NothingTheme.slab(context), shape: BoxShape.circle),
            child: Text(
              number,
              style: NothingType.archivo(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NothingType.archivo(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(body, style: NothingType.subtitle()),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: NothingType.archivo(color: NothingTheme.accentWhite),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
