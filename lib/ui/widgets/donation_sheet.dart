import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

const String kBractStudioUrl = 'https://bractstudio.com';
const String kCoffeeUrl = 'https://buymeacoffee.com/bractstudio';
const String kSupportEmail = 'buttonoo@bractstudio.com';

class DonationSheet extends StatelessWidget {
  const DonationSheet({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NothingTheme.accentRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.coffee,
                    color: NothingTheme.accentRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'buttonoo is a free, open-source project. If you find it useful, consider supporting its development!',
                    style: NothingType.archivo(
                      fontSize: 13,
                      color: NothingTheme.txtSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LinkTile(
              icon: PhosphorIcons.coffee,
              title: 'Buy me a coffee',
              subtitle: 'Opens in your browser',
              onTap: () => _open(kCoffeeUrl),
            ),
            _LinkTile(
              icon: PhosphorIcons.envelopeSimple,
              title: 'Get in touch',
              subtitle: kSupportEmail,
              onTap: () => _open('mailto:$kSupportEmail'),
            ),
            _LinkTile(
              icon: PhosphorIcons.globeSimple,
              title: 'Bract Studio',
              subtitle: 'bractstudio.com',
              onTap: () => _open(kBractStudioUrl),
            ),
            const SizedBox(height: 16),
            Text(
              'Entirely optional. Thanks for being here.',
              textAlign: TextAlign.center,
              style: NothingType.doto(
                color: NothingTheme.txtMuted(context),
                fontSize: 10,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NothingTheme.txtPrimary(context).withValues(alpha: 0.03),
        border: Border.all(color: NothingTheme.divider(context).withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: NothingTheme.txtSecondary(context),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: NothingType.archivo(
                          color: NothingTheme.txtPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: NothingType.archivo(
                          color: NothingTheme.txtMuted(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowUpRight,
                  color: NothingTheme.txtMuted(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
