import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'app.dart';

// These icons are used by the native Android overlay (NothingGlowView.kt).
// Referencing them here ensures the Flutter tree-shaker doesn't remove them from the font asset in release builds.
final List<IconData> _nativeIconsToKeep = [
  PhosphorIcons.flashlight,
  PhosphorIcons.deviceMobile,
  PhosphorIcons.bellSimpleSlash,
  PhosphorIcons.vibrate,
  PhosphorIcons.bellRinging,
  PhosphorIcons.minusCircle,
  PhosphorIcons.microphone,
  PhosphorIcons.camera,
  PhosphorIcons.speakerHigh,
  PhosphorIcons.speakerLow,
  PhosphorIcons.speakerSlash,
  PhosphorIcons.sunDim,
  PhosphorIcons.sun,
  PhosphorIcons.lockKey,
  PhosphorIcons.pause,
  PhosphorIcons.play,
  PhosphorIcons.skipForward,
  PhosphorIcons.skipBack,
  PhosphorIcons.squaresFour,
  PhosphorIcons.sparkle,
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent tree-shaking of these icons
  if (_nativeIconsToKeep.isEmpty) debugPrint('No native icons');
  runApp(const EssentialKeyApp());
}
