import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/screens/meal_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeMealRepository repository;

  setUp(() async {
    await getIt.reset();
    repository = _FakeMealRepository();
    getIt.registerFactory<MealController>(
      () => MealController(repository, _FakeSessionService()),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('abre a seleção e mostra apenas refeições favoritas', (
    tester,
  ) async {
    repository.meals = [
      _meal(id: 1, favorite: true, foodName: 'Arroz favorito'),
      _meal(id: 2, favorite: false, foodName: 'Feijão comum'),
    ];
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('use-favorite-meal-button')));
    await tester.pumpAndSettle();

    expect(find.text('Usar refeição favorita'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('favorite-meal-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-meal-2')), findsNothing);
    expect(find.textContaining('1 alimento(s)'), findsOneWidget);
    expect(find.textContaining('28.0g de carboidratos'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há favoritas', (tester) async {
    repository.meals = [_meal(id: 2, favorite: false)];
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('use-favorite-meal-button')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma refeição favorita cadastrada.'), findsOneWidget);
  });

  testWidgets('seleciona template, clona itens e salva uma nova refeição', (
    tester,
  ) async {
    final favorite = _meal(id: 7, favorite: true);
    repository.meals = [favorite];
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('use-favorite-meal-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-meal-7')));
    await tester.pumpAndSettle();

    expect(find.textContaining('100 g'), findsOneWidget);
    expect(find.text('28.0g'), findsOneWidget);

    final saveButton = find.byKey(const ValueKey('save-meal-button'));
    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.created, isNotNull);
    expect(repository.updated, isNull);
    expect(repository.created!.id, isNull);
    expect(repository.created!.items.single.id, isNull);
    expect(repository.created!.items.single.mealId, isNull);
    expect(repository.created!.items.single.quantityGrams, 100);
    expect(repository.created!.totalCarbohydrates, closeTo(28, 1e-10));
    expect(favorite.items.single.id, 70);
    expect(favorite.items.single.mealId, 7);
    expect(favorite.items.single.quantityGrams, 100);
  });

  testWidgets('não substitui itens atuais sem confirmação', (tester) async {
    repository.meals = [
      _meal(id: 7, favorite: true, foodName: 'Arroz favorito'),
    ];
    await _pumpScreen(
      tester,
      initialItems: [_item(mealId: null, id: null, foodName: 'Item atual')],
    );

    await tester.tap(find.byKey(const ValueKey('use-favorite-meal-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-meal-7')));
    await tester.pumpAndSettle();

    expect(find.text('Substituir alimentos?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Item atual'), findsOneWidget);
    expect(find.text('Arroz favorito'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('use-favorite-meal-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-meal-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir'));
    await tester.pumpAndSettle();
    expect(find.text('Item atual'), findsNothing);
    expect(find.text('Arroz favorito'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<MealItemModel> initialItems = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(home: MealRegistrationScreen(initialItems: initialItems)),
  );
  await tester.pumpAndSettle();
}

MealItemModel _item({
  int? id = 70,
  int? mealId = 7,
  String foodName = 'Arroz favorito',
}) => MealItemModel(
  id: id,
  mealId: mealId,
  foodId: 3,
  foodName: foodName,
  carbohydratesPer100g: 28,
  quantityGrams: 100,
);

MealModel _meal({
  required int id,
  required bool favorite,
  String foodName = 'Arroz favorito',
}) => MealModel(
  id: id,
  userId: 1,
  type: MealType.almoco,
  dateTime: DateTime(2026),
  favorite: favorite,
  items: [_item(id: id * 10, mealId: id, foodName: foodName)],
);

class _FakeMealRepository implements MealRepositoryInterface {
  List<MealModel> meals = [];
  MealModel? created;
  MealModel? updated;

  @override
  Future<int> create(MealModel meal) async {
    created = meal;
    return 1;
  }

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<List<MealModel>> listByUser(int userId) async => meals;

  @override
  Future<List<MealModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  ) async => meals
      .where(
        (meal) =>
            meal.userId == userId &&
            !meal.dateTime.isBefore(start) &&
            !meal.dateTime.isAfter(end),
      )
      .toList();

  @override
  Future<int> setFavorite(int id, bool favorite) async => 1;

  @override
  Future<int> update(MealModel meal) async {
    updated = meal;
    return 1;
  }
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => 1;

  @override
  Future<void> startSession(int userId) async {}
}
