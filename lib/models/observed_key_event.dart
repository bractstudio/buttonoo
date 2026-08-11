class ObservedKeyEvent {
  final int keyCode;
  final int scanCode;
  final int action;
  final int eventTime;

  const ObservedKeyEvent({
    required this.keyCode,
    required this.scanCode,
    required this.action,
    required this.eventTime,
  });

  factory ObservedKeyEvent.fromMap(Map<dynamic, dynamic> map) {
    return ObservedKeyEvent(
      keyCode: map['keyCode'] as int? ?? 0,
      scanCode: map['scanCode'] as int? ?? 0,
      action: map['action'] as int? ?? 0,
      eventTime: map['eventTime'] as int? ?? 0,
    );
  }
}
