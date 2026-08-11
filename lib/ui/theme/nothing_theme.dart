import 'package:flutter/material.dart';

class NothingTheme {
  // Theme state notifier
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSlabSurface = Color(0xFF1A1E1A);
  static const Color darkTextPrimary = Color(0xFFFBFBF9);
  static const Color darkTextSecondary = Color(0xFF8A9089);
  static const Color darkTextMuted = Color(0xFF6C726B);
  static const Color darkBorderDivider = Color(0xFF242824);
  static const Color darkDisabledBackground = Color(0xFF20241F);
  static const Color darkDisabledThumb = Color(0xFF3A3F39);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF4F4F2);
  static const Color lightSlabSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextMuted = Color(0xFF999999);
  static const Color lightBorderDivider = Color(0xFFE5E5EA);
  static const Color lightDisabledBackground = Color(0xFFEFEFEF);
  static const Color lightDisabledThumb = Color(0xFFCCCCCC);

  // Common Accents
  static const Color accentRed = Color(0xFFFFC107);
  static const Color accentWhite = Color(0xFFFBFBF9);

  /// Every colour is resolved against the active brightness. There are no
  /// brightness-independent constants apart from the accents above, so a widget
  /// cannot accidentally pin itself to one theme.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bg(BuildContext context) => isDark(context) ? darkBackground : lightBackground;
  static Color slab(BuildContext context) => isDark(context) ? darkSlabSurface : lightSlabSurface;
  static Color txtPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;
  static Color txtSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;
  static Color txtMuted(BuildContext context) => isDark(context) ? darkTextMuted : lightTextMuted;
  static Color divider(BuildContext context) =>
      isDark(context) ? darkBorderDivider : lightBorderDivider;
  static Color disabledBg(BuildContext context) =>
      isDark(context) ? darkDisabledBackground : lightDisabledBackground;
  static Color disabledTh(BuildContext context) =>
      isDark(context) ? darkDisabledThumb : lightDisabledThumb;
  static Color pillActiveBg(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;
  static Color pillActiveFg(BuildContext context) =>
      isDark(context) ? darkBackground : lightSlabSurface;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      // Bundled body face, so anything not styled through NothingType still matches.
      fontFamily: 'Archivo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentRed,
        surface: darkSlabSurface,
        onSurface: darkTextPrimary,
        secondary: darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Archivo',
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentRed,
        surface: lightSlabSurface,
        onSurface: lightTextPrimary,
        secondary: lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
