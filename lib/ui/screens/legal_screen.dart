import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/nothing_card.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                    'LEGAL & LICENSES',
                    style: NothingType.doto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: NothingTheme.txtPrimary(context),
                      letterSpacing: 0.06,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                child: Column(
                  children: [
                    _CollapsibleCard(
                      icon: PhosphorIcons.shieldCheck(),
                      title: 'Privacy Policy',
                      content: Text(
                        'buttonoo operates 100% on-device:\n\n'
                        '• Zero data collection, telemetry, or analytics.\n'
                        '• No background network requests.\n'
                        '• Configurations are stored securely on-device inside local Android DataStore.\n'
                        '• Accessibility permissions are used strictly to map hardware key press events.',
                        style: NothingType.archivo(
                          color: NothingTheme.txtSecondary(context),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                    _CollapsibleCard(
                      icon: PhosphorIcons.article(),
                      title: 'Terms of Use',
                      content: Text(
                        'By using buttonoo, you agree to the following terms:\n\n'
                        '• The application is provided "as-is", without warranties or conditions of any kind.\n'
                        '• Operation is strictly local; no server-side guarantees are made.\n'
                        '• You are responsible for ensuring compliance with your device manufacture guidelines and local laws.',
                        style: NothingType.archivo(
                          color: NothingTheme.txtSecondary(context),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                    _CollapsibleCard(
                      icon: PhosphorIcons.fileCode(),
                      title: 'Open Source Licenses',
                      content: Text(
                        'buttonoo is licensed under the GPL-3.0-or-later.\n\n'
                        'Bundled third-party components:\n\n'
                        '• libadb-android, sun-security-android (MuntashirAkon) — GPL-3.0-or-later / Apache-2.0\n'
                        '• Shizuku API (RikkaApps) — Apache-2.0\n'
                        '• HiddenApiBypass (LSPosed) — Apache-2.0\n'
                        '• Phosphor Icons (phosphor_flutter) — MIT\n'
                        '• Doto, Geist Mono — SIL Open Font License 1.1\n\n'
                        'Full licence texts ship with the source at github.com/bractstudio/buttonoo.',
                        style: NothingType.archivo(
                          color: NothingTheme.txtSecondary(context),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                    _CollapsibleCard(
                      icon: PhosphorIcons.handsClapping(),
                      title: 'Credits & Acknowledgments',
                      content: Text(
                        '• Creator & Developer: Binge\n'
                        '• Design & Branding: Bract Studio\n'
                        '• Font Families: Doto and Geist Mono (SIL OFL 1.1)\n'
                        '• Icon Sets: Phosphor Icons (Phosphor Flutter)',
                        style: NothingType.archivo(
                          color: NothingTheme.txtSecondary(context),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
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

class _CollapsibleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget content;

  const _CollapsibleCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return NothingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: NothingTheme.txtPrimary(context),
                    size: 18,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: NothingType.archivo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: NothingTheme.txtPrimary(context),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
                    color: NothingTheme.txtMuted(context),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.content,
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
