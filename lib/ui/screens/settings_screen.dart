import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/section_label.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import '../widgets/app_sheet.dart';
import '../widgets/donation_sheet.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'diagnostics_screen.dart';
import 'unlock/unlock_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _setThemeMode(ThemeMode mode) async {
    String modeStr;
    if (mode == ThemeMode.light) {
      modeStr = 'light';
    } else if (mode == ThemeMode.system) {
      modeStr = 'system';
    } else {
      modeStr = 'dark';
    }

    NothingTheme.themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', modeStr);
    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    final currentThemeMode = NothingTheme.themeModeNotifier.value;

    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                    'SETTINGS',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // APPEARANCE SECTION
                    const SectionLabel(
                      text: 'APPEARANCE',
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                    ),
                    SlabGroup(
                      children: [
                        Container(
                          color: NothingTheme.slab(context),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App theme mode',
                                style: NothingType.archivo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: NothingTheme.txtPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _themePill(
                                    label: 'Dark',
                                    icon: PhosphorIcons.moon(),
                                    selected: currentThemeMode == ThemeMode.dark,
                                    onTap: () => _setThemeMode(ThemeMode.dark),
                                  ),
                                  _themePill(
                                    label: 'Light',
                                    icon: PhosphorIcons.sun(),
                                    selected: currentThemeMode == ThemeMode.light,
                                    onTap: () => _setThemeMode(ThemeMode.light),
                                  ),
                                  _themePill(
                                    label: 'System',
                                    icon: PhosphorIcons.deviceMobile(),
                                    selected: currentThemeMode == ThemeMode.system,
                                    onTap: () => _setThemeMode(ThemeMode.system),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // APP MANAGEMENT SECTION
                    const SectionLabel(
                      text: 'APP MANAGEMENT',
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                    ),
                    SlabGroup(
                      children: [
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UnlockScreen()),
                          ),
                          leading: Icon(
                            PhosphorIcons.lockKeyOpen(),
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'Unlock key from Nothing OS',
                          subtitle: 'App Info · ADB · Shizuku',
                          trailing: Icon(
                            PhosphorIcons.caretRight(),
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                          ),
                          leading: Icon(
                            PhosphorIcons.info(),
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'Diagnostics & Learn mode',
                          subtitle: 'Permissions, key test & logs',
                          trailing: Icon(
                            PhosphorIcons.caretRight(),
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BackupScreen()),
                          ),
                          leading: Icon(
                            PhosphorIcons.arrowsDownUp(),
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'Backup & Restore',
                          subtitle: 'Export / import JSON config',
                          trailing: Icon(
                            PhosphorIcons.caretRight(),
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ABOUT & SUPPORT SECTION
                    const SectionLabel(
                      text: 'ABOUT & SUPPORT',
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                    ),
                    SlabGroup(
                      children: [
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          ),
                          leading: Image.asset(
                            'assets/images/buttonoo_logo_inverted.png',
                            width: 20,
                            height: 20,
                          ),
                          title: 'About buttonoo',
                          subtitle: 'v1.0.0 (Build 1) · Bract Studio',
                          trailing: Icon(
                            PhosphorIcons.caretRight(),
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildPremiumFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Support Links Row
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildFooterLink(
              context,
              'REPORT BUG',
              () async {
                final Uri emailUri = Uri.parse(
                  'mailto:buttonoo@bractstudio.com?subject=buttonoo%20Bug%20Report%20(v1.0.0)',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _buildFooterDot(context),
            _buildFooterLink(
              context,
              'SUPPORT US',
              () => showAppSheet(
                context: context,
                builder: (_) => const DonationSheet(),
              ),
            ),
            _buildFooterDot(context),
            _buildFooterLink(
              context,
              'SHARE APP',
              () {
                Share.share(
                  'Remap the Essential Key on Nothing phones to any action with buttonoo!\nhttps://github.com/bractstudio/buttonoo',
                );
              },
            ),
          ],
        ),
        _buildFooterLink(
          context,
          'PRIVACY POLICY',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LegalScreen()),
          ),
          opacity: 0.35,
        ),
        const SizedBox(height: 24),
        // Social Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              context,
              PhosphorIcons.redditLogo(),
              'https://www.reddit.com/r/bractstudio/',
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              context,
              PhosphorIcons.instagramLogo(),
              'https://www.instagram.com/studio.bract',
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              context,
              PhosphorIcons.telegramLogo(),
              'https://t.me/+95VoGv2FnbhiZjI1',
            ),
          ],
        ),
        const SizedBox(height: 40),
        Image.asset(
          'assets/images/bract_studio_logo.png',
          height: 40,
          color: NothingTheme.txtPrimary(context).withValues(alpha: 0.08),
          errorBuilder: (context, error, stackTrace) => Text(
            'bract studio',
            style: NothingType.doto(
              color: NothingTheme.txtPrimary(context).withValues(alpha: 0.08),
              fontSize: 18,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFooterLink(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    double opacity = 0.6,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label.toUpperCase(),
          style: NothingType.archivo(
            color: NothingTheme.txtPrimary(context).withValues(alpha: opacity),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterDot(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: NothingTheme.txtPrimary(context).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NothingTheme.txtPrimary(context).withValues(alpha: 0.03),
          border: Border.all(color: NothingTheme.divider(context).withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: NothingTheme.txtSecondary(context).withValues(alpha: 0.7),
          size: 18,
        ),
      ),
    );
  }

  Widget _themePill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? NothingTheme.pillActiveBg(context) : NothingTheme.divider(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? NothingTheme.pillActiveFg(context)
                    : NothingTheme.txtSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: NothingType.archivo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? NothingTheme.pillActiveFg(context)
                      : NothingTheme.txtSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
