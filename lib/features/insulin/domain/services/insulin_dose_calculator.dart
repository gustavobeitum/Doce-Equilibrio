import 'package:doce_equilibrio/features/insulin/domain/entities/insulin_calculation.dart';

/// Implementa literalmente as formulas da secao 5 de requisitos.
class InsulinDoseCalculator {
  const InsulinDoseCalculator._();

  static const double _halfUnit = 0.5;
  static const double _tieTolerance = 1e-12;

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

    final exactTotalDose = correctionDose + carbohydrateDose;

    return InsulinCalculation(
      correctionDose: correctionDose,
      carbohydrateDose: carbohydrateDose,
      totalDose: quantizeRecommendedDose(exactTotalDose),
    );
  }

  /// Ajusta apenas a dose total para o múltiplo de 0,5 UI mais próximo.
  /// Empates exatos são resolvidos para cima (por exemplo, 0,25 → 0,5).
  static double quantizeRecommendedDose(double exactDose) {
    if (exactDose < 0) {
      throw ArgumentError('Dose recomendada não pode ser negativa.');
    }

    final scaledDose = exactDose / _halfUnit;
    final lowerStep = scaledDose.floor();
    final fraction = scaledDose - lowerStep;
    final selectedStep = fraction >= 0.5 - _tieTolerance
        ? lowerStep + 1
        : lowerStep;
    return selectedStep * _halfUnit;
  }
}
