import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../native/remapper_channel.dart';
import '../../theme/nothing_theme.dart';
import '../../theme/nothing_type.dart';
import '../../widgets/key_hardware_indicator.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/slab_group.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final RemapperChannel _channel = RemapperChannel();

  bool _agreed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildStep1(), _buildStep2()],
        ),
      ),
    );
  }

  // Step 1: "ONE BUTTON. FOUR JOBS."
  Widget _buildStep1() {
    return Column(
      children: [
        // Top Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUTTONOO',
                style: NothingType.sectionHeader(color: NothingTheme.txtSecondary(context)),
              ),
              Text(
                '1 / 2',
                style: NothingType.doto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NothingTheme.accentRed,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                // Heading Title in Doto Font
                Text(
                  'ONE BUTTON.\nFOUR JOBS.',
                  style: NothingType.doto(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 22),

                // Subtitle Paragraph
                Text(
                  'Press, double, triple or hold your Essential Key to run a torch, a camera, an app — whatever you assign.',
                  style: NothingType.archivo(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: NothingTheme.txtSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 44),

                // Hardware Edge & Gesture Demo Alignment
                Stack(
                  children: [
                    const Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: KeyHardwareIndicator(height: 200, keyTop: 20, keyHeight: 70),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 36.0, top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDemoGestureRow('1×', 'torch', isSelected: false),
                          const SizedBox(height: 14),
                          _buildDemoGestureRow('2×', 'camera', isSelected: true),
                          const SizedBox(height: 14),
                          _buildDemoGestureRow('3×', '—', isSelected: false),
                          const SizedBox(height: 14),
                          _buildDemoGestureRow('hold', 'assistant', isSelected: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: NothingButton(
            text: 'Start',
            isPrimary: true,
            onPressed: () {
              _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 2: "WE WATCH ONE KEY."
  Widget _buildStep2() {
    return Column(
      children: [
        // Top Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUTTONOO',
                style: NothingType.sectionHeader(color: NothingTheme.txtSecondary(context)),
              ),
              Text(
                '2 / 2',
                style: NothingType.doto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NothingTheme.accentRed,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                // Heading Title in Doto Font
                Text(
                  'WE WATCH\nONE KEY.',
                  style: NothingType.doto(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle Paragraph
                Text(
                  'Android only exposes hardware keys through the Accessibility API. That is the whole reason we ask.',
                  style: NothingType.archivo(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: NothingTheme.txtSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Privacy Disclosure Slabs
                SlabGroup(
                  children: [
                    Container(
                      color: NothingTheme.slab(context),
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHAT WE DO',
                            style: NothingType.sectionHeader(color: NothingTheme.accentRed),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Read one key event: down, up, timestamp.',
                            style: NothingType.archivo(fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: NothingTheme.slab(context),
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHAT WE NEVER DO',
                            style: NothingType.sectionHeader(color: NothingTheme.txtMuted(context)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Read your screen. Store anything. Log any other keystroke. Talk to a network.',
                            style: NothingType.archivo(
                              fontSize: 15,
                              color: NothingTheme.txtSecondary(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Agreement Checkbox & Enable Finish Button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _agreed ? NothingTheme.accentRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _agreed
                                ? NothingTheme.accentRed
                                : NothingTheme.txtMuted(context),
                            width: 2,
                          ),
                        ),
                        child: _agreed
                            ? Icon(PhosphorIcons.check(), size: 13, color: NothingTheme.accentWhite)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I understand and agree.',
                          style: NothingType.archivo(
                            fontSize: 13,
                            color: NothingTheme.txtSecondary(context),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              NothingButton(
                text: 'Enable and finish',
                isPrimary: true,
                onPressed: _agreed
                    ? () async {
                        await _channel.openAccessibilitySettings();
                        widget.onComplete();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoGestureRow(String gestureLabel, String actionLabel, {required bool isSelected}) {
    final color = isSelected ? NothingTheme.accentRed : NothingTheme.txtMuted(context);

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            gestureLabel,
            style: NothingType.doto(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ),
        Text(
          actionLabel,
          style: NothingType.doto(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
