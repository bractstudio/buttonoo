import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';

const String kBractStudioUrl = 'https://bractstudio.com';
const String kBractStudioLogoAsset = 'assets/images/bract_studio_logo.png';

class BractStudioMark extends StatelessWidget {
  final bool isEmbedded;

  const BractStudioMark({super.key, this.isEmbedded = false});

  Future<void> _openUrl() async {
    final Uri uri = Uri.parse(kBractStudioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = NothingTheme.txtMuted(context);
    final markColor = NothingTheme.txtPrimary(context).withValues(alpha: 0.25);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: NothingTheme.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BACKED BY',
                style: NothingType.doto(
                  color: labelColor,
                  fontSize: 10,
                  letterSpacing: 0.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                kBractStudioLogoAsset,
                height: 38,
                color: markColor,
                errorBuilder: (context, error, stackTrace) => Text(
                  'bract studio',
                  style: NothingType.doto(
                    color: NothingTheme.txtPrimary(context),
                    fontSize: 18,
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.arrowUpRight,
                color: labelColor,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );

    if (isEmbedded) {
      return Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
        child: InkWell(
          onTap: _openUrl,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: NothingTheme.slab(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NothingTheme.divider(context).withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _openUrl,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }
}
