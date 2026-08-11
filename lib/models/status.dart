class ServiceStatus {
  final bool serviceRunning;
  final String unlockStatus;
  final bool overlayPermission;
  final bool writeSettingsPermission;
  final bool notificationPolicyPermission;
  final bool batteryOptimizationIgnored;
  final bool developerOptionsEnabled;

  const ServiceStatus({
    required this.serviceRunning,
    required this.unlockStatus,
    required this.overlayPermission,
    required this.writeSettingsPermission,
    required this.notificationPolicyPermission,
    required this.batteryOptimizationIgnored,
    required this.developerOptionsEnabled,
  });

  factory ServiceStatus.fromMap(Map<dynamic, dynamic> map) {
    return ServiceStatus(
      serviceRunning: map['serviceRunning'] as bool? ?? false,
      unlockStatus: map['unlockStatus'] as String? ?? 'LOCKED',
      overlayPermission: map['overlayPermission'] as bool? ?? false,
      writeSettingsPermission: map['writeSettingsPermission'] as bool? ?? false,
      notificationPolicyPermission: map['notificationPolicyPermission'] as bool? ?? false,
      batteryOptimizationIgnored: map['batteryOptimizationIgnored'] as bool? ?? false,
      developerOptionsEnabled: map['developerOptionsEnabled'] as bool? ?? false,
    );
  }

  bool get isFreed => unlockStatus == 'FREED';

  /// Every permission the app can check, in the order the UI lists them.
  List<bool> get permissionFlags => [
    serviceRunning,
    overlayPermission,
    writeSettingsPermission,
    notificationPolicyPermission,
    batteryOptimizationIgnored,
  ];

  int get grantedCount => permissionFlags.where((granted) => granted).length;
  int get permissionCount => permissionFlags.length;
}

class PackageState {
  final String packageName;
  final bool installed;
  final bool freed;

  const PackageState({required this.packageName, required this.installed, required this.freed});

  factory PackageState.fromMap(Map<dynamic, dynamic> map) {
    return PackageState(
      packageName: map['packageName'] as String? ?? '',
      installed: map['installed'] as bool? ?? false,
      freed: map['freed'] as bool? ?? false,
    );
  }
}
