import 'gesture.dart';
import 'key_action.dart';
import 'overlay_config.dart';

class AppConfig {
  final int version;
  final bool enabled;
  final int scanCode;
  final String anchorEdge;
  final double anchorFraction;
  final int longPressMs;
  final int multiTapMs;
  final Map<KeyGesture, ActionSpec> actions;
  final OverlayConfig overlay;
  final Map<KeyGesture, bool> lockPolicy;
  final bool hapticsEnabled;
  final String hapticsIntensity;

  const AppConfig({
    this.version = 1,
    this.enabled = true,
    this.scanCode = 250,
    this.anchorEdge = 'left',
    this.anchorFraction = 0.34,
    this.longPressMs = 500,
    this.multiTapMs = 400,
    required this.actions,
    required this.overlay,
    required this.lockPolicy,
    this.hapticsEnabled = true,
    this.hapticsIntensity = 'medium',
  });

  AppConfig copyWith({
    bool? enabled,
    int? scanCode,
    String? anchorEdge,
    double? anchorFraction,
    int? longPressMs,
    int? multiTapMs,
    Map<KeyGesture, ActionSpec>? actions,
    OverlayConfig? overlay,
    Map<KeyGesture, bool>? lockPolicy,
    bool? hapticsEnabled,
    String? hapticsIntensity,
  }) {
    return AppConfig(
      version: version,
      enabled: enabled ?? this.enabled,
      scanCode: scanCode ?? this.scanCode,
      anchorEdge: anchorEdge ?? this.anchorEdge,
      anchorFraction: anchorFraction ?? this.anchorFraction,
      longPressMs: longPressMs ?? this.longPressMs,
      multiTapMs: multiTapMs ?? this.multiTapMs,
      actions: actions ?? this.actions,
      overlay: overlay ?? this.overlay,
      lockPolicy: lockPolicy ?? this.lockPolicy,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticsIntensity: hapticsIntensity ?? this.hapticsIntensity,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final actionsMap = <KeyGesture, ActionSpec>{};
    final actionsJson = json['actions'] as Map<String, dynamic>? ?? {};
    for (final gesture in KeyGesture.values) {
      if (actionsJson.containsKey(gesture.key)) {
        actionsMap[gesture] = ActionSpec.fromJson(actionsJson[gesture.key] as Map<String, dynamic>);
      } else {
        actionsMap[gesture] = const NoneActionSpec();
      }
    }

    final lockMap = <KeyGesture, bool>{};
    final lockJson = json['lockPolicy'] as Map<String, dynamic>? ?? {};
    for (final gesture in KeyGesture.values) {
      lockMap[gesture] = lockJson[gesture.key] as bool? ?? false;
    }

    final hapticsJson = json['haptics'] as Map<String, dynamic>? ?? {};

    return AppConfig(
      version: json['version'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? true,
      scanCode: json['scanCode'] as int? ?? 250,
      anchorEdge: json['anchorEdge'] as String? ?? 'left',
      anchorFraction: (json['anchorFraction'] as num?)?.toDouble() ?? 0.34,
      longPressMs: json['longPressMs'] as int? ?? 500,
      multiTapMs: json['multiTapMs'] as int? ?? 400,
      actions: actionsMap,
      overlay: json['overlay'] != null
          ? OverlayConfig.fromJson(json['overlay'] as Map<String, dynamic>)
          : const OverlayConfig(),
      lockPolicy: lockMap,
      hapticsEnabled: hapticsJson['enabled'] as bool? ?? true,
      hapticsIntensity: hapticsJson['intensity'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'enabled': enabled,
    'scanCode': scanCode,
    'anchorEdge': anchorEdge,
    'anchorFraction': anchorFraction,
    'longPressMs': longPressMs,
    'multiTapMs': multiTapMs,
    'actions': actions.map((g, a) => MapEntry(g.key, a.toJson())),
    'overlay': overlay.toJson(),
    'lockPolicy': lockPolicy.map((g, v) => MapEntry(g.key, v)),
    'haptics': {'enabled': hapticsEnabled, 'intensity': hapticsIntensity},
  };
}
