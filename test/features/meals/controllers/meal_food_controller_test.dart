import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/navigation/food_library_navigator.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_food_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acessa alimentos pelo contrato sem usar FoodController', () async {
    final repository = _FakeFoodRepository();
    final controller = MealFoodController(
      repository,
      _FakeSessionService(),
      _FakeFoodLibraryNavigator(),
    );

    expect(await controller.listFoods(), hasLength(1));
    expect(await controller.searchFoods('arr'), hasLength(1));
    expect(repository.lastQuery, 'arr');
  });
}

class _FakeFoodRepository implements FoodRepositoryInterface {
  String? lastQuery;
  final food = const FoodModel(
    id: 1,
    userId: 1,
    name: 'Arroz',
    carbohydratesPer100g: 28,
  );

  @override
  Future<int> create(FoodModel food) async => 1;

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<List<FoodModel>> listByUser(int userId) async => [food];

  @override
  Future<List<FoodModel>> searchByName(int userId, String query) async {
    lastQuery = query;
    return [food];
  }

  @override
  Future<int> update(FoodModel food) async => 1;
}

class _FakeFoodLibraryNavigator implements FoodLibraryNavigator {
  @override
  Future<void> open(BuildContext context) async {}
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => 1;

  @override
  Future<void> startSession(int userId) async {}
}
