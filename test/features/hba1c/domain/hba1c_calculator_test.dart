import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = HbA1cCalculator();

  test('não calcula sem registros', () {
    expect(calculator.calculate(const []), isNull);
  });

  test('permite calcular com um registro', () {
    final result = calculator.calculate(const [126])!;

    expect(result.averageGlycemiaMgDl, 126);
    expect(result.percentage, closeTo((126 + 46.7) / 28.7, 0.0000001));
    expect(result.recordCount, 1);
  });

  test('calcula média conhecida e HbA1c pela fórmula oficial', () {
    final result = calculator.calculate(const [100, 140, 180])!;

    expect(result.averageGlycemiaMgDl, 140);
    expect(result.percentage, closeTo(6.5052264808, 0.0000001));
  });

  test('preserva média decimal e precisão intermediária', () {
    final result = calculator.calculate(const [100, 101, 103])!;
    final exactAverage = 304 / 3;

    expect(result.averageGlycemiaMgDl, closeTo(exactAverage, 0.0000001));
    expect(result.percentage, closeTo((exactAverage + 46.7) / 28.7, 0.0000001));
    expect(result.percentage.toStringAsFixed(1), '5.2');
  });
}
