import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/navigation/food_library_navigator.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_food_controller.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_food_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerFactory<MealFoodController>(
      () => MealFoodController(
        _FakeFoodRepository(),
        _FakeSessionService(),
        _FakeFoodLibraryNavigator(),
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('modal fica acima do teclado e mantém resultados acessíveis', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: Scaffold(body: MealFoodSelectionModal()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final modalBottom = tester.getBottomRight(find.byType(Container).first).dy;
    expect(modalBottom, lessThanOrEqualTo(500));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeFoodRepository implements FoodRepositoryInterface {
  static const food = FoodModel(
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
  Future<List<FoodModel>> searchByName(int userId, String query) async => [
    food,
  ];

  @override
  Future<int> update(FoodModel food) async => 1;
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => 1;

  @override
  Future<void> startSession(int userId) async {}
}

class _FakeFoodLibraryNavigator implements FoodLibraryNavigator {
  @override
  Future<void> open(BuildContext context) async {}
}
