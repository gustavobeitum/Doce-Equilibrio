enum ActivityIntensity {
  leve('Leve'),
  moderada('Moderada'),
  intensa('Intensa');

  const ActivityIntensity(this.label);

  final String label;

  static ActivityIntensity? fromValue(String? value) {
    if (value == null) return null;
    for (final intensity in values) {
      if (intensity.label == value) return intensity;
    }
    return null;
  }
}
