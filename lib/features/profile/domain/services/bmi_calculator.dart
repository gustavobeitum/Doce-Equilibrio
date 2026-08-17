enum BmiClassification { underweight, idealWeight, overweight, obesity }

class BmiResult {
  final double value;
  final BmiClassification classification;

  const BmiResult({required this.value, required this.classification});
}

/// Regra de IMC definida pelo RF-014, independente de Flutter e persistencia.
class BmiCalculator {
  const BmiCalculator._();

  static BmiResult calculate({
    required double weightKg,
    required double heightMeters,
  }) {
    if (weightKg <= 0 || heightMeters <= 0) {
      throw ArgumentError('Peso e altura devem ser maiores que zero.');
    }

    final value = weightKg / (heightMeters * heightMeters);
    final classification = switch (value) {
      < 18.5 => BmiClassification.underweight,
      < 25 => BmiClassification.idealWeight,
      < 30 => BmiClassification.overweight,
      _ => BmiClassification.obesity,
    };
    return BmiResult(value: value, classification: classification);
  }
}
