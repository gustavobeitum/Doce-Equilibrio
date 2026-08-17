import 'package:doce_equilibrio/features/insulin/domain/services/insulin_dose_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('soma dose alimentar e correcao sem arredondar o dominio', () {
    final result = InsulinDoseCalculator.calculate(
      currentGlycemia: 181,
      carbohydratesGrams: 45,
      glycemiaTarget: 100,
      correctionFactor: 30,
      insulinCarbohydrateRatio: 12,
    );
    expect(result.correctionDose, 2.7);
    expect(result.carbohydrateDose, 3.75);
    expect(result.totalDose, 6.45);
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
}
