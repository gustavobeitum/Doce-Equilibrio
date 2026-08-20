import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeMealRepository repository;
  late MealController controller;

  setUp(() {
    repository = _FakeMealRepository();
    controller = MealController(repository, _FakeSessionService());
  });

  test('impede salvar refeição vazia', () async {
    final error = await controller.save(
      type: MealType.almoco,
      dateTime: DateTime(2026),
      items: const [],
    );

    expect(error, isNotNull);
    expect(repository.created, isNull);
  });

  test('persiste refeição com itens e total calculado', () async {
    final error = await controller.save(
      type: MealType.almoco,
      dateTime: DateTime(2026),
      items: [_item(quantity: 150)],
    );

    expect(error, isNull);
    expect(repository.created?.items, hasLength(1));
    expect(repository.created?.totalCarbohydrates, closeTo(42, 1e-10));
  });

  test('lista somente favoritas', () async {
    repository.meals = [
      _meal(id: 1, favorite: true),
      _meal(id: 2, favorite: false),
    ];

    final favorites = await controller.listFavorites();

    expect(favorites.map((meal) => meal.id), [1]);
  });

  test('atualiza favorita sem regravar itens', () async {
    expect(await controller.setFavorite(2, true), isTrue);
    expect(repository.favoriteUpdate, (id: 2, favorite: true));
    expect(repository.updated, isNull);
  });

  test('reutiliza itens preservando quantidades e removendo IDs', () {
    final favorite = _meal(id: 1, favorite: true);
    final originalItem = favorite.items.single;
    final items = controller.reuseFavoriteItems(favorite);

    expect(items.single.quantityGrams, 100);
    expect(items.single.foodId, originalItem.foodId);
    expect(items.single.foodName, originalItem.foodName);
    expect(items.single.id, isNull);
    expect(items.single.mealId, isNull);
    expect(items.single, isNot(same(originalItem)));
    expect(favorite.items.single.id, 8);
    expect(favorite.items.single.mealId, 1);
  });

  test('salva reutilização como nova refeição sem alterar favorita', () async {
    final favorite = _meal(id: 1, favorite: true);
    final reusedItems = controller.reuseFavoriteItems(favorite);
    final changedItems = [reusedItems.single.copyWith(quantityGrams: 150)];

    final error = await controller.save(
      type: favorite.type,
      dateTime: DateTime(2026, 2),
      items: changedItems,
    );

    expect(error, isNull);
    expect(repository.created?.id, isNull);
    expect(repository.updated, isNull);
    expect(repository.created?.items.single.id, isNull);
    expect(repository.created?.items.single.mealId, isNull);
    expect(repository.created?.items.single.quantityGrams, 150);
    expect(favorite.items.single.quantityGrams, 100);
    expect(favorite.favorite, isTrue);
  });

  test('alterar quantidade atualiza o total sem arredondamento novo', () {
    final original = _item(quantity: 100);
    final updated = original.copyWith(quantityGrams: 125);
    final meal = _meal(id: 1, favorite: false, items: [updated]);

    expect(meal.totalCarbohydrates, 35);
  });

  test('exclui refeição', () async {
    expect(await controller.delete(3), isTrue);
    expect(repository.deletedId, 3);
  });

  test('lista período usando usuário atual e limites inclusivos', () async {
    repository.meals = [
      MealModel(
        id: 1,
        userId: 1,
        type: MealType.almoco,
        dateTime: DateTime(2026, 8, 1),
      ),
      MealModel(
        id: 2,
        userId: 2,
        type: MealType.jantar,
        dateTime: DateTime(2026, 8, 1),
      ),
    ];

    final result = await controller.listByPeriod(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 1, 23, 59, 59, 999, 999),
    );

    expect(result.map((meal) => meal.id), [1]);
  });
}

MealItemModel _item({required double quantity}) => MealItemModel(
  id: 8,
  mealId: 1,
  foodId: 2,
  foodName: 'Arroz',
  carbohydratesPer100g: 28,
  quantityGrams: quantity,
);

MealModel _meal({
  required int id,
  required bool favorite,
  List<MealItemModel>? items,
}) => MealModel(
  id: id,
  userId: 1,
  type: MealType.almoco,
  dateTime: DateTime(2026),
  favorite: favorite,
  items: items ?? [_item(quantity: 100)],
);

class _FakeMealRepository implements MealRepositoryInterface {
  List<MealModel> meals = [];
  MealModel? created;
  MealModel? updated;
  int? deletedId;
  ({int id, bool favorite})? favoriteUpdate;

  @override
  Future<int> create(MealModel meal) async {
    created = meal;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    deletedId = id;
    return 1;
  }

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
  Future<int> setFavorite(int id, bool favorite) async {
    favoriteUpdate = (id: id, favorite: favorite);
    return 1;
  }

  @override
  Future<int> update(MealModel meal) async {
    updated = meal;
    return meal.id!;
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
