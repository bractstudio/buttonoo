import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_info.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/section_label.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import '../../models/status.dart';
import '../../state/app_scope.dart';
import '../widgets/app_sheet.dart';
import '../widgets/donation_sheet.dart';
import '../widgets/nothing_segmented_control.dart';
import '../widgets/diagnostics_sheet.dart';
import 'about_screen.dart';
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
    final permissions = AppScope.permissionsOf(context);
    final status = permissions.status;

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
                      PhosphorIcons.arrowLeft,
                      color: NothingTheme.txtPrimary(context),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // APPEARANCE SECTION
                    const SectionLabel(
                      text: 'APPEARANCE',
                      padding: EdgeInsets.only(bottom: 12),
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
                              NothingSegmentedControl<ThemeMode>(
                                values: const [ThemeMode.dark, ThemeMode.light, ThemeMode.system],
                                selectedValue: currentThemeMode,
                                childBuilder: (mode, selected) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      mode == ThemeMode.dark
                                          ? PhosphorIcons.moon
                                          : mode == ThemeMode.light
                                              ? PhosphorIcons.sun
                                              : PhosphorIcons.deviceMobile,
                                      size: 16,
                                      color: selected
                                          ? NothingTheme.pillActiveFg(context)
                                          : NothingTheme.txtSecondary(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      mode == ThemeMode.dark
                                          ? 'Dark'
                                          : mode == ThemeMode.light
                                              ? 'Light'
                                              : 'System',
                                      style: NothingType.archivo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? NothingTheme.pillActiveFg(context)
                                            : NothingTheme.txtSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                onChanged: _setThemeMode,
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
                      padding: EdgeInsets.only(bottom: 12),
                    ),
                    SlabGroup(
                      children: [
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UnlockScreen()),
                          ),
                          leading: Icon(
                            PhosphorIcons.lockKeyOpen,
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'Unlock key from Nothing OS',
                          subtitle: 'App Info · ADB · Shizuku',
                          trailing: Icon(
                            PhosphorIcons.caretRight,
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                        SlabTile(
                          onTap: () => showAppSheet(
                            context: context,
                            builder: (_) => const DiagnosticsSheet(),
                          ),
                          leading: Icon(
                            PhosphorIcons.info,
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'Diagnostics',
                          subtitle: 'Check permission status',
                          trailing: _buildDiagnosticsTrailing(context, status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ABOUT & SUPPORT SECTION
                    const SectionLabel(
                      text: 'ABOUT & SUPPORT',
                      padding: EdgeInsets.only(bottom: 12),
                    ),
                    SlabGroup(
                      children: [
                        SlabTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          ),
                          leading: Icon(
                            PhosphorIcons.info,
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'About buttonoo',
                          subtitle: '${AppInfo.versionLabel} · Bract Studio',
                          trailing: Icon(
                            PhosphorIcons.caretRight,
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                        SlabTile(
                          onTap: _openMoreApps,
                          leading: Icon(
                            PhosphorIcons.squaresFour,
                            color: NothingTheme.txtSecondary(context),
                            size: 18,
                          ),
                          title: 'More apps',
                          subtitle: 'Other things we have built',
                          trailing: Icon(
                            PhosphorIcons.arrowUpRight,
                            color: NothingTheme.txtMuted(context),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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

  /// Bract Studio's developer page. Tries the Play Store app first — the
  /// market: scheme opens it directly — and falls back to the web listing on
  /// devices without Play installed, which is most of the F-Droid audience.
  Future<void> _openMoreApps() async {
    const devId = '4892549832807036197';
    final market = Uri.parse('market://dev?id=$devId');
    final web = Uri.parse('https://play.google.com/store/apps/dev?id=$devId');

    if (await canLaunchUrl(market)) {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) return;
    }
    if (await canLaunchUrl(web)) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDiagnosticsTrailing(BuildContext context, ServiceStatus? status) {
    final hasMissing = status == null || status.grantedCount < status.permissionCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMissing) ...[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: NothingTheme.accentRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Icon(
          PhosphorIcons.caretRight,
          color: NothingTheme.txtMuted(context),
          size: 16,
        ),
      ],
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
                  'mailto:buttonoo@bractstudio.com?subject=buttonoo%20Bug%20Report%20(v${AppInfo.versionName})',
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
              PhosphorIcons.redditLogo,
              'https://www.reddit.com/r/bractstudio/',
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              context,
              PhosphorIcons.instagramLogo,
              'https://www.instagram.com/studio.bract',
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              context,
              PhosphorIcons.telegramLogo,
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
}


