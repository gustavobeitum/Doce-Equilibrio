import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeFoodRepository repository;
  late FoodController controller;

  setUp(() {
    repository = _FakeFoodRepository();
    controller = FoodController(repository, _FakeSessionService());
  });

  test('lista e pesquisa alimentos pelo repository', () async {
    repository.foods = [_food(id: 1, name: 'Arroz')];

    expect(await controller.list(), hasLength(1));
    expect(await controller.search('arr'), hasLength(1));
    expect(repository.lastQuery, 'arr');
  });

  test('retorna resultado vazio da busca', () async {
    expect(await controller.search('inexistente'), isEmpty);
  });

  test('cria e edita alimento', () async {
    expect(
      await controller.save(
        name: 'Arroz',
        servingQuantity: 100,
        servingUnit: 'g',
        carbohydratesPerServing: 28,
      ),
      isNull,
    );
    expect(repository.created?.name, 'Arroz');

    expect(
      await controller.save(
        id: 4,
        name: 'Arroz integral',
        servingQuantity: 50,
        servingUnit: 'g',
        carbohydratesPerServing: 12.5,
      ),
      isNull,
    );
    expect(repository.updated?.id, 4);
    expect(repository.updated?.servingQuantity, 50);
    expect(repository.updated?.carbohydratesPerServing, 12.5);
  });

  test('exclui alimento', () async {
    expect(await controller.delete(4), isTrue);
    expect(repository.deletedId, 4);
  });
}

FoodModel _food({required int id, required String name}) => FoodModel(
  id: id,
  userId: 1,
  name: name,
  servingQuantity: 100,
  servingUnit: 'g',
  carbohydratesPerServing: 28,
);

class _FakeFoodRepository implements FoodRepositoryInterface {
  List<FoodModel> foods = [];
  FoodModel? created;
  FoodModel? updated;
  int? deletedId;
  String? lastQuery;

  @override
  Future<int> create(FoodModel food) async {
    created = food;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    deletedId = id;
    return 1;
  }

  @override
  Future<List<FoodModel>> listByUser(int userId) async => foods;

  @override
  Future<List<FoodModel>> searchByName(int userId, String query) async {
    lastQuery = query;
    return foods
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<int> update(FoodModel food) async {
    updated = food;
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
