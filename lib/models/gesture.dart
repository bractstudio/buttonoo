enum KeyGesture {
  singlePress('single', 'Single Press'),
  doublePress('double', 'Double Press'),
  triplePress('triple', 'Triple Press'),
  quadruplePress('quadruple', 'Quadruple Press'),
  longPress('long', 'Long Press');

  final String key;
  final String label;
  const KeyGesture(this.key, this.label);

  static KeyGesture fromKey(String key) {
    return KeyGesture.values.firstWhere((e) => e.key == key, orElse: () => KeyGesture.singlePress);
  }
}
