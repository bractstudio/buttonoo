/// One launcher-visible app, as reported by the platform.
///
/// Icons are not part of this: they are fetched per package through
/// `RemapperChannel.appIcon` only for the rows actually on screen.
class AppEntry {
  const AppEntry({required this.packageName, required this.label});

  final String packageName;
  final String label;

  factory AppEntry.fromMap(Map<dynamic, dynamic> map) => AppEntry(
    packageName: map['packageName'] as String? ?? '',
    label: map['label'] as String? ?? '',
  );

  bool matches(String query) =>
      label.toLowerCase().contains(query) || packageName.toLowerCase().contains(query);
}
