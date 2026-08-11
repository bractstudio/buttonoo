abstract class ActionSpec {
  final String type;
  const ActionSpec(this.type);

  Map<String, dynamic> toJson();
  String get displayTitle;
  String get displaySubtitle;

  static ActionSpec fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'none';
    switch (type) {
      case 'quick':
        return QuickActionSpec(json['id'] as String? ?? 'none');
      case 'app':
        return AppActionSpec(json['package'] as String? ?? '');
      case 'shortcut':
        return ShortcutActionSpec(
          json['package'] as String? ?? '',
          json['shortcutId'] as String? ?? '',
        );
      case 'activity':
        return ActivityActionSpec(
          json['package'] as String? ?? '',
          json['className'] as String? ?? '',
        );
      case 'apps_column':
        final List<dynamic> pkgs = json['packageNames'] as List<dynamic>? ?? [];
        return AppsColumnActionSpec(pkgs.map((e) => e.toString()).toList());
      default:
        return const NoneActionSpec();
    }
  }
}

class NoneActionSpec extends ActionSpec {
  const NoneActionSpec() : super('none');

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  String get displayTitle => 'No Action';

  @override
  String get displaySubtitle => 'Key press ignored';
}

class QuickActionSpec extends ActionSpec {
  final String id;
  const QuickActionSpec(this.id) : super('quick');

  @override
  Map<String, dynamic> toJson() => {'type': 'quick', 'id': id};

  @override
  String get displayTitle => _quickTitles[id] ?? id;

  @override
  String get displaySubtitle => 'System Quick Action';

  static const Map<String, String> _quickTitles = {
    'flashlight': 'Toggle Flashlight',
    'rotation_lock': 'Toggle Rotation Lock',
    'ring_vibrate': 'Cycle Ringer (Ring/Vibrate/Silent)',
    'dnd': 'Toggle Do Not Disturb',
    'assistant': 'Voice Assistant',
    'volume_up': 'Volume Up',
    'volume_down': 'Volume Down',
    'volume_mute': 'Toggle Mute',
    'volume_slider': 'Volume Control Panel',
    'brightness_up': 'Increase Brightness',
    'brightness_down': 'Decrease Brightness',
    'media_play_pause': 'Media Play / Pause',
    'media_next': 'Media Next Track',
    'media_prev': 'Media Previous Track',
    'screenshot': 'Take Screenshot',
    'lock_screen': 'Lock Screen',
  };
}

class AppActionSpec extends ActionSpec {
  final String packageName;
  const AppActionSpec(this.packageName) : super('app');

  @override
  Map<String, dynamic> toJson() => {'type': 'app', 'package': packageName};

  @override
  String get displayTitle => 'Launch App';

  @override
  String get displaySubtitle => packageName;
}

class ShortcutActionSpec extends ActionSpec {
  final String packageName;
  final String shortcutId;
  const ShortcutActionSpec(this.packageName, this.shortcutId) : super('shortcut');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'shortcut',
    'package': packageName,
    'shortcutId': shortcutId,
  };

  @override
  String get displayTitle => 'App Shortcut';

  @override
  String get displaySubtitle => '$packageName ($shortcutId)';
}

class ActivityActionSpec extends ActionSpec {
  final String packageName;
  final String className;
  const ActivityActionSpec(this.packageName, this.className) : super('activity');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'activity',
    'package': packageName,
    'className': className,
  };

  @override
  String get displayTitle => 'Specific Activity';

  @override
  String get displaySubtitle => className.split('.').last;
}

class AppsColumnActionSpec extends ActionSpec {
  final List<String> packageNames;
  const AppsColumnActionSpec(this.packageNames) : super('apps_column');

  @override
  Map<String, dynamic> toJson() => {'type': 'apps_column', 'packageNames': packageNames};

  @override
  String get displayTitle => 'Apps Column';

  @override
  String get displaySubtitle => '${packageNames.length} apps';
}
