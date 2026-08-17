import 'package:doce_equilibrio/features/meals/domain/services/carbohydrate_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula carboidratos proporcionalmente a quantidade', () {
    expect(
      CarbohydrateCalculator.forItem(
        carbohydratesPerServing: 20,
        standardServing: 100,
        consumedQuantity: 150,
      ),
      30,
    );
  });

  test('considera zero quando carboidratos nao estao cadastrados', () {
    expect(
      CarbohydrateCalculator.forItem(
        standardServing: 100,
        consumedQuantity: 50,
      ),
      0,
    );
  });
}
