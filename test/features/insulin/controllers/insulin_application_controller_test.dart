import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/insulin/repositories/insulin_application_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ApplicationRepository applications;
  late _MealRepository meals;
  late InsulinApplicationController controller;

  setUp(() async {
    applications = _ApplicationRepository();
    meals = _MealRepository();
    controller = InsulinApplicationController(
      applications,
      meals,
      _UserRepository(),
      _Session(1),
      now: () => DateTime(2026, 8, 18, 12),
    );
    await controller.load();
  });

  test('calcula usando o domínio existente e quantiza somente o total', () {
    controller.calculate(glycemia: '180', carbohydrates: '60');

    expect(controller.calculation!.carbohydrateDose, 4);
    expect(controller.calculation!.correctionDose, 4);
    expect(controller.calculation!.totalDose, 8);
  });

  test(
    'cria registro mantendo recomendação e dose aplicada separadas',
    () async {
      final saved = await controller.save(
        glycemia: '180',
        carbohydrates: '60',
        appliedDose: '7,5',
        observation: 'Dose revisada',
      );

      expect(saved, isTrue);
      expect(applications.created!.recommendedDose, 8);
      expect(applications.created!.appliedDose, 7.5);
      expect(applications.created!.observation, 'Dose revisada');
      expect(applications.created!.dateTime, DateTime(2026, 8, 18, 12));
    },
  );

  test(
    'valida glicemia, carboidratos e incrementos da dose aplicada',
    () async {
      expect(
        await controller.save(
          glycemia: '-1',
          carbohydrates: '20',
          appliedDose: '1',
        ),
        isFalse,
      );
      expect(
        await controller.save(
          glycemia: '100',
          carbohydrates: '-1',
          appliedDose: '1',
        ),
        isFalse,
      );
      expect(
        await controller.save(
          glycemia: '100',
          carbohydrates: '20',
          appliedDose: '1,2',
        ),
        isFalse,
      );
      expect(applications.created, isNull);
    },
  );

  group('valida glicemia da calculadora entre 0 e 999', () {
    test('campo vazio usa mensagem de obrigatoriedade', () {
      expect(
        controller.calculate(glycemia: '', carbohydrates: '20'),
        'Informe a glicemia atual.',
      );
    });

    test('aceita os limites e valores válidos', () {
      for (final value in ['0', '1', '20', '600', '999']) {
        expect(
          controller.calculate(glycemia: value, carbohydrates: '20'),
          isNull,
          reason: '$value deveria ser válido',
        );
      }
    });

    test('rejeita negativos, acima do limite e decimais', () {
      for (final value in ['-1', '1000', '100,5']) {
        expect(
          controller.calculate(glycemia: value, carbohydrates: '20'),
          isNotNull,
          reason: '$value deveria ser inválido',
        );
      }
    });
  });

  test('seleciona refeição e importa seus carboidratos sem alterá-la', () {
    final meal = meals.items.single;
    final before = meal.totalCarbohydrates;

    final imported = controller.selectMeal(meal);

    expect(imported, closeTo(42, 1e-10));
    expect(controller.selectedMeal, same(meal));
    expect(meal.totalCarbohydrates, before);
  });

  test('salva mealId ao usar carboidratos de uma refeição', () async {
    controller.selectMeal(meals.items.single);
    await controller.save(
      glycemia: '120',
      carbohydrates: '42',
      appliedDose: '3',
    );
    expect(applications.created!.mealId, 7);
  });

  test(
    'edição recalcula recomendação após alterar glicemia e carboidratos',
    () async {
      final original = _application(id: 4, recommended: 2, applied: 1.5);
      applications.items = [original];
      controller.startEditing(original);

      final saved = await controller.save(
        glycemia: '200',
        carbohydrates: '45',
        appliedDose: '4,5',
      );

      expect(saved, isTrue);
      expect(applications.updated!.id, 4);
      expect(applications.updated!.recommendedDose, 8);
      expect(applications.updated!.appliedDose, 4.5);
    },
  );

  test('exclui aplicação do usuário atual', () async {
    final item = _application(id: 9);
    applications.items = [item];
    expect(await controller.delete(item), isTrue);
    expect(applications.deleted, (id: 9, userId: 1));
  });

  test('informa ausência de sessão sem consultar repositories', () async {
    final noSession = InsulinApplicationController(
      applications,
      meals,
      _UserRepository(),
      _Session(null),
    );

    await noSession.load();

    expect(noSession.errorMessage, contains('Sessão expirada'));
    expect(noSession.user, isNull);
  });

  test('trata erro do repository e encerra loading', () async {
    applications.throwOnList = true;

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, contains('Não foi possível carregar'));
  });

  test(
    'erro ao carregar refeições não é apresentado como lista vazia',
    () async {
      meals.throwOnList = true;

      await controller.loadMeals();

      expect(controller.isLoadingMeals, isFalse);
      expect(controller.meals, isEmpty);
      expect(controller.mealsErrorMessage, contains('carregar as refeições'));
    },
  );

  test('consulta refeições usando somente o usuário da sessão', () async {
    await controller.loadMeals();

    expect(meals.lastUserId, 1);
    expect(controller.meals.every((meal) => meal.userId == 1), isTrue);
  });
}

InsulinApplicationModel _application({
  int? id,
  double recommended = 3,
  double applied = 3,
}) => InsulinApplicationModel(
  id: id,
  userId: 1,
  glycemia: 120,
  carbohydrates: 30,
  carbohydrateDose: 2,
  correctionDose: 1,
  recommendedDose: recommended,
  appliedDose: applied,
  dateTime: DateTime(2026),
);

class _ApplicationRepository implements InsulinApplicationRepositoryInterface {
  List<InsulinApplicationModel> items = [];
  InsulinApplicationModel? created;
  InsulinApplicationModel? updated;
  ({int id, int userId})? deleted;
  bool throwOnList = false;

  @override
  Future<int> create(InsulinApplicationModel application) async {
    created = application;
    items = [...items, application];
    return 1;
  }

  @override
  Future<int> update(InsulinApplicationModel application) async {
    updated = application;
    return 1;
  }

  @override
  Future<int> delete(int id, int userId) async {
    deleted = (id: id, userId: userId);
    items = items.where((item) => item.id != id).toList();
    return 1;
  }

  @override
  Future<InsulinApplicationModel?> findById(int id, int userId) async =>
      items.where((item) => item.id == id && item.userId == userId).firstOrNull;

  @override
  Future<List<InsulinApplicationModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  ) async => items;

  @override
  Future<List<InsulinApplicationModel>> listByUser(int userId) async {
    if (throwOnList) throw Exception('database');
    return items;
  }
}

class _MealRepository implements MealRepositoryInterface {
  bool throwOnList = false;
  int? lastUserId;
  final items = [
    MealModel(
      id: 7,
      userId: 1,
      type: MealType.almoco,
      dateTime: DateTime(2026),
      items: const [
        MealItemModel(
          foodId: 2,
          foodName: 'Arroz',
          carbohydratesPer100g: 28,
          quantityGrams: 150,
        ),
      ],
    ),
  ];

  @override
  Future<List<MealModel>> listByUser(int userId) async {
    lastUserId = userId;
    if (throwOnList) throw Exception('database');
    return items.where((meal) => meal.userId == userId).toList();
  }

  @override
  Future<int> create(MealModel meal) => throw UnimplementedError();
  @override
  Future<int> update(MealModel meal) => throw UnimplementedError();
  @override
  Future<int> delete(int id) => throw UnimplementedError();
  @override
  Future<int> setFavorite(int id, bool favorite) => throw UnimplementedError();
}

class _UserRepository implements UserRepositoryInterface {
  @override
  Future<UserModel?> find(int id) async => UserModel(
    id: id,
    name: 'Ana',
    email: 'ana@example.com',
    diabetesType: 'Tipo 1',
    diagnosisYear: 2020,
    password: 'hash',
    salt: 'salt',
    sensitivityFactor: 15,
    correctionFactor: 20,
    glycemiaTarget: 100,
  );
  @override
  Future<int> create(UserModel user) => throw UnimplementedError();
  @override
  Future<bool> emailJaCadastrado(String email) => throw UnimplementedError();
  @override
  Future<UserModel?> findByEmail(String email) => throw UnimplementedError();
  @override
  Future<int> update(UserModel user) => throw UnimplementedError();
}

class _Session implements SessionService {
  final int? id;
  _Session(this.id);
  @override
  Future<int?> getCurrentUserId() async => id;
  @override
  Future<void> startSession(int userId) async {}
  @override
  Future<void> endSession() async {}
}
