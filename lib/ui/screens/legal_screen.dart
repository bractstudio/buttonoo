import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/nothing_card.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Privacy Policy
                    NothingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.shieldCheck(),
                                color: const Color(0xFFE50000),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Privacy Policy',
                                style: NothingType.archivo(
                                  fontWeight: FontWeight.bold,
                                  color: NothingTheme.txtPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Terms of Use
                    NothingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.article(),
                                color: const Color(0xFFE50000),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Terms of Use',
                                style: NothingType.archivo(
                                  fontWeight: FontWeight.bold,
                                  color: NothingTheme.txtPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Open Source Licenses
                    NothingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.fileCode(),
                                color: const Color(0xFFE50000),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Open Source Licenses',
                                style: NothingType.archivo(
                                  fontWeight: FontWeight.bold,
                                  color: NothingTheme.txtPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Includes components under the MIT License:\n\n'
                            '• libadb-android (MuntashirAkon)\n'
                            '• Shizuku API (Rikka / LSPosed)\n'
                            '• HiddenApiBypass (LSPosed)\n\n'
                            'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to deal in the Software without restriction.',
                            style: NothingType.archivo(
                              color: NothingTheme.txtSecondary(context),
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Credits
                    NothingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.handsClapping(),
                                color: const Color(0xFFE50000),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Credits & Acknowledgments',
                                style: NothingType.archivo(
                                  fontWeight: FontWeight.bold,
                                  color: NothingTheme.txtPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
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
                        ],
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
