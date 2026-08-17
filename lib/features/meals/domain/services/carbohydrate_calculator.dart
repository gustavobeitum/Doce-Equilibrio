class CarbohydrateCalculator {
  const CarbohydrateCalculator._();

  /// Formula do RF-005/UC-13. Um valor nutricional ausente equivale a zero.
  static double forItem({
    double? carbohydratesPerServing,
    required double standardServing,
    required double consumedQuantity,
  }) {
    if (standardServing <= 0 || consumedQuantity < 0) {
      throw ArgumentError(
        'Porcao deve ser positiva e quantidade nao negativa.',
      );
    }
    return ((carbohydratesPerServing ?? 0) / standardServing) *
        consumedQuantity;
  }

  static double total(Iterable<double> itemCarbohydrates) =>
      itemCarbohydrates.fold(0, (sum, value) => sum + value);
}
