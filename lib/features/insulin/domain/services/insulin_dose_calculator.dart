import 'package:doce_equilibrio/features/insulin/domain/entities/insulin_calculation.dart';

/// Implementa literalmente as formulas da secao 5 de requisitos.
class InsulinDoseCalculator {
  const InsulinDoseCalculator._();

  static InsulinCalculation calculate({
    int? currentGlycemia,
    double? carbohydratesGrams,
    required int glycemiaTarget,
    required double correctionFactor,
    required double insulinCarbohydrateRatio,
  }) {
    if (correctionFactor <= 0 || insulinCarbohydrateRatio <= 0) {
      throw ArgumentError('Fatores de insulina devem ser maiores que zero.');
    }

    final correctionDose =
        currentGlycemia != null && currentGlycemia > glycemiaTarget
        ? (currentGlycemia - glycemiaTarget) / correctionFactor
        : 0.0;
    final carbohydrateDose =
        carbohydratesGrams != null && carbohydratesGrams > 0
        ? carbohydratesGrams / insulinCarbohydrateRatio
        : 0.0;

    return InsulinCalculation(
      correctionDose: correctionDose,
      carbohydrateDose: carbohydrateDose,
      totalDose: correctionDose + carbohydrateDose,
    );
  }
}
