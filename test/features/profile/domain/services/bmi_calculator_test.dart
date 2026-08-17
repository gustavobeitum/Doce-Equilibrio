import 'package:doce_equilibrio/features/profile/domain/services/bmi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula e classifica os limites oficiais de IMC', () {
    expect(
      BmiCalculator.calculate(weightKg: 18.49, heightMeters: 1).classification,
      BmiClassification.underweight,
    );
    expect(
      BmiCalculator.calculate(weightKg: 18.5, heightMeters: 1).classification,
      BmiClassification.idealWeight,
    );
    expect(
      BmiCalculator.calculate(weightKg: 25, heightMeters: 1).classification,
      BmiClassification.overweight,
    );
    expect(
      BmiCalculator.calculate(weightKg: 30, heightMeters: 1).classification,
      BmiClassification.obesity,
    );
  });
}
