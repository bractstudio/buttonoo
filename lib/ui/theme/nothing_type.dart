import 'package:flutter/material.dart';

/// Typography.
///
/// Both faces are bundled assets (see pubspec `fonts:`) rather than fetched at
/// runtime, so headings render on the first frame and the app has no reason to
/// touch the network.
class NothingType {
  /// Dot-matrix display face, used for headings, badges and numeric readouts.
  static const String dotFamily = 'Doto';

  /// Body face.
  static const String bodyFamily = 'GeistMono';

  /// Header & badge font: Doto (dot-matrix).
  static TextStyle doto({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 0.08,
  }) {
    return TextStyle(
      fontFamily: dotFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      // Callers pass a ratio, not absolute px.
      letterSpacing: fontSize * letterSpacing,
      height: 1.0,
    );
  }

  /// Body & subtitle font: Geist Mono.
  static TextStyle archivo({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Uppercase section header.
  static TextStyle sectionHeader({Color? color}) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 1.6,
      height: 1.0,
    );
  }

  /// Subtitle (12px).
  static TextStyle subtitle({Color? color}) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.3,
    );
  }
}
