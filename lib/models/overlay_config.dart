class OverlayConfig {
  final bool enabled;
  final String style; // 'nothing' or 'stock'
  final String accentHex;
  final bool glow;
  final int holdMs;
  final String panelSize; // 'Small', 'Regular', 'Large'
  final String cardStyle; // 'filled', 'stroke', 'transparent'

  // Explicit geometry, in dp. The small card is what most actions show; only the
  // volume track, brightness track and shortcut column extend into the tall panel.
  final int cardWidth;
  final int cardHeight;
  final int panelWidth;
  final int panelHeight;
  final int edgeMargin;
  final int cornerRadius;

  const OverlayConfig({
    this.enabled = true,
    this.style = 'nothing',
    this.accentHex = '#D71921',
    this.glow = true,
    this.holdMs = 700,
    this.panelSize = 'Regular',
    this.cardWidth = 46,
    this.cardHeight = 80,
    this.panelWidth = 56,
    this.panelHeight = 148,
    this.edgeMargin = 9,
    this.cardStyle = 'filled',
    this.cornerRadius = 18,
  });

  factory OverlayConfig.fromJson(Map<String, dynamic> json) {
    return OverlayConfig(
      enabled: json['enabled'] as bool? ?? true,
      style: json['style'] as String? ?? 'nothing',
      accentHex: json['accent'] as String? ?? '#D71921',
      glow: json['glow'] as bool? ?? true,
      holdMs: json['holdMs'] as int? ?? 700,
      panelSize: json['panelSize'] as String? ?? 'Regular',
      cardWidth: json['cardW'] as int? ?? 46,
      cardHeight: json['cardH'] as int? ?? 80,
      panelWidth: json['panelW'] as int? ?? 56,
      panelHeight: json['panelH'] as int? ?? 148,
      edgeMargin: json['edgeMargin'] as int? ?? 9,
      cardStyle: json['cardStyle'] as String? ?? 'filled',
      cornerRadius: json['cornerRadius'] as int? ?? 18,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'style': style,
    'accent': accentHex,
    'glow': glow,
    'holdMs': holdMs,
    'panelSize': panelSize,
    'cardW': cardWidth,
    'cardH': cardHeight,
    'panelW': panelWidth,
    'panelH': panelHeight,
    'edgeMargin': edgeMargin,
    'cardStyle': cardStyle,
    'cornerRadius': cornerRadius,
  };

  OverlayConfig copyWith({
    bool? enabled,
    String? style,
    String? accentHex,
    bool? glow,
    int? holdMs,
    String? panelSize,
    int? cardWidth,
    int? cardHeight,
    int? panelWidth,
    int? panelHeight,
    int? edgeMargin,
    String? cardStyle,
    int? cornerRadius,
  }) {
    return OverlayConfig(
      enabled: enabled ?? this.enabled,
      style: style ?? this.style,
      accentHex: accentHex ?? this.accentHex,
      glow: glow ?? this.glow,
      holdMs: holdMs ?? this.holdMs,
      panelSize: panelSize ?? this.panelSize,
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      panelWidth: panelWidth ?? this.panelWidth,
      panelHeight: panelHeight ?? this.panelHeight,
      edgeMargin: edgeMargin ?? this.edgeMargin,
      cardStyle: cardStyle ?? this.cardStyle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }
}
