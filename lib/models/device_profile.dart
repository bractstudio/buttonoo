class DeviceProfile {
  final String device;
  final String model;
  final String anchorEdge;
  final double anchorFraction;

  const DeviceProfile({
    required this.device,
    required this.model,
    required this.anchorEdge,
    required this.anchorFraction,
  });

  factory DeviceProfile.fromMap(Map<dynamic, dynamic> map) {
    return DeviceProfile(
      device: map['device'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      anchorEdge: map['anchorEdge'] as String? ?? 'left',
      anchorFraction: (map['anchorFraction'] as num?)?.toDouble() ?? 0.34,
    );
  }
}
