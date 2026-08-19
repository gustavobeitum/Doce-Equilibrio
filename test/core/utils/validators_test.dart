import 'package:doce_equilibrio/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valida os limites oficiais do registro de glicemia', () {
    expect(Validators.validateGlycemia('19'), isNotNull);
    expect(Validators.validateGlycemia('20'), isNull);
    expect(Validators.validateGlycemia('600'), isNull);
    expect(Validators.validateGlycemia('601'), isNotNull);
  });

  group('glicemia para cálculo de insulina', () {
    test('diferencia campo vazio de valor fora da faixa', () {
      expect(
        Validators.validateInsulinCalculationGlycemia(''),
        'Informe a glicemia atual.',
      );
      expect(
        Validators.validateInsulinCalculationGlycemia('1000'),
        'Informe um valor entre 0 e 999 mg/dL.',
      );
    });

    test('aceita somente inteiros entre 0 e 999', () {
      for (final value in ['0', '1', '20', '600', '999']) {
        expect(
          Validators.validateInsulinCalculationGlycemia(value),
          isNull,
          reason: '$value deveria ser válido',
        );
      }

      for (final value in ['-1', '1000', '100,5', '100.5']) {
        expect(
          Validators.validateInsulinCalculationGlycemia(value),
          isNotNull,
          reason: '$value deveria ser inválido',
        );
      }
    });
  });

  test('valida os limites oficiais da meta glicêmica', () {
    expect(Validators.validateGlycemiaTarget('49'), isNotNull);
    expect(Validators.validateGlycemiaTarget('50'), isNull);
    expect(Validators.validateGlycemiaTarget('500'), isNull);
    expect(Validators.validateGlycemiaTarget('501'), isNotNull);
  });
}
