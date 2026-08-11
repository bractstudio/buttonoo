import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/bract_studio_mark.dart';
import '../widgets/nothing_card.dart';
import '../widgets/app_sheet.dart';
import '../widgets/donation_sheet.dart';
import 'legal_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});



  Future<void> _openLocation() async {
    final url = Uri.parse('https://maps.google.com/?q=Kasaragod,+Kerala');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'ABOUT',
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
                  children: [
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/buttonoo_logo_inverted.png',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BUTTONOO',
                      style: NothingType.doto(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: NothingTheme.txtPrimary(context),
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0 (Build 1)',
                      style: NothingType.archivo(
                        fontSize: 13,
                        color: NothingTheme.txtMuted(context),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Developer Binge Card
                    NothingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: NothingTheme.txtPrimary(context).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      PhosphorIcons.alien(),
                                      color: NothingTheme.txtPrimary(context),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'BINGE',
                                    style: NothingType.archivo(
                                      color: NothingTheme.txtPrimary(context),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: NothingTheme.txtPrimary(context).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: NothingTheme.txtPrimary(context).withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  'CREATOR',
                                  style: NothingType.archivo(
                                    color: NothingTheme.txtPrimary(context),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'I teach by day and build apps like this by night, for the fun of it — and also for the money.',
                            style: NothingType.archivo(
                              color: NothingTheme.txtPrimary(context).withValues(alpha: 0.85),
                              height: 1.5,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: NothingTheme.divider(context).withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CRAFTED WITH LOVE FROM',
                                style: NothingType.archivo(
                                  color: NothingTheme.txtMuted(context),
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: _openLocation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: NothingTheme.txtPrimary(context).withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PhosphorIcons.mapPin(),
                                        color: NothingTheme.txtPrimary(context),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Kasaragod, Kerala',
                                        style: NothingType.archivo(
                                          color: NothingTheme.txtPrimary(context),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Support & Backed By Card
                    NothingCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: NothingTheme.pillActiveBg(context),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: InkWell(
                              onTap: () {
                                showAppSheet(
                                  context: context,
                                  builder: (_) => const DonationSheet(),
                                );
                              },
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIcons.coffee(),
                                      color: NothingTheme.pillActiveFg(context),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SUPPORT DEVELOPMENT',
                                      style: NothingType.doto(
                                        color: NothingTheme.pillActiveFg(context),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.08,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: NothingTheme.divider(context).withValues(alpha: 0.1),
                          ),
                          const BractStudioMark(isEmbedded: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Legal & Open Source Navigation Card
                    NothingCard(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LegalScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.shieldCheck(),
                                color: NothingTheme.txtSecondary(context),
                                size: 18,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Legal & Open Source',
                                      style: NothingType.archivo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: NothingTheme.txtPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Privacy policy, terms, licenses & credits',
                                      style: NothingType.archivo(
                                        fontSize: 12,
                                        color: NothingTheme.txtSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                PhosphorIcons.caretRight(),
                                color: NothingTheme.txtMuted(context),
                                size: 16,
                              ),
                            ],
                          ),
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
