import 'package:doce_equilibrio/features/insulin/domain/services/insulin_dose_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantém parcelas exatas e quantiza somente a soma final', () {
    final result = InsulinDoseCalculator.calculate(
      currentGlycemia: 181,
      carbohydratesGrams: 45,
      glycemiaTarget: 100,
      correctionFactor: 30,
      insulinCarbohydrateRatio: 12,
    );
    expect(result.correctionDose, 2.7);
    expect(result.carbohydrateDose, 3.75);
    expect(result.totalDose, 6.5);
  });

  test('correcao e zero quando glicemia nao supera a meta', () {
    final result = InsulinDoseCalculator.calculate(
      currentGlycemia: 100,
      glycemiaTarget: 100,
      correctionFactor: 20,
      insulinCarbohydrateRatio: 15,
    );
    expect(result.correctionDose, 0);
  });

  test('quantiza para o múltiplo de 0,5 mais próximo com empate para cima', () {
    final cases = {
      0.24: 0.0,
      0.25: 0.5,
      0.26: 0.5,
      1.24: 1.0,
      1.26: 1.5,
      1.49: 1.5,
      1.51: 1.5,
      1.74: 1.5,
      1.76: 2.0,
      12.49: 12.5,
      12.74: 12.5,
      12.76: 13.0,
    };

    for (final entry in cases.entries) {
      final result = InsulinDoseCalculator.quantizeRecommendedDose(entry.key);
      expect(result, entry.value, reason: '${entry.key} UI');
      expect((result * 2) % 1, 0);
    }
  });

  test('não arredonda parcelas antes de somar', () {
    final result = InsulinDoseCalculator.calculate(
      currentGlycemia: 101,
      carbohydratesGrams: 1,
      glycemiaTarget: 100,
      correctionFactor: 3,
      insulinCarbohydrateRatio: 3,
    );

    expect(result.correctionDose, closeTo(1 / 3, 1e-12));
    expect(result.carbohydrateDose, closeTo(1 / 3, 1e-12));
    expect(result.totalDose, 0.5);
  });
}
