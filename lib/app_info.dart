/// Version strings shown in the UI.
///
/// These have to match `version:` in pubspec.yaml, which is what actually
/// becomes versionName and versionCode in the APK. Keeping them in one const
/// means a release bumps two files rather than four, and the About screen, the
/// Settings subtitle and the bug-report subject can no longer disagree.
class AppInfo {
  const AppInfo._();

  /// Mirrors the part of pubspec `version:` before the `+`.
  static const String versionName = '1.0.1';

  /// Mirrors the part after the `+`.
  static const int buildNumber = 2;

  /// "v1.0.1 (Build 2)"
  static const String versionLabel = 'v$versionName (Build $buildNumber)';
}
