import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê alimento legado como porção padrão de 100 g', () {
    final food = FoodModel.fromMap({
      'id': 1,
      'usuarioId': 2,
      'nome': 'Arroz',
      'carboidratosPor100g': 28.0,
    });

    expect(food.servingQuantity, 100);
    expect(food.servingUnit, 'g');
    expect(food.carbohydratesPerServing, 28);
  });

  test('preserva porção e carboidratos no mapa atual', () {
    final food = FoodModel(
      id: 1,
      userId: 2,
      name: 'Iogurte',
      servingQuantity: 170,
      servingUnit: 'g',
      carbohydratesPerServing: 14,
    );

    final restored = FoodModel.fromMap(food.toMap());
    expect(restored.servingQuantity, 170);
    expect(restored.servingUnit, 'g');
    expect(restored.carbohydratesPerServing, 14);
  });
}
