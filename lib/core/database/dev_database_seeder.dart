import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:doce_equilibrio/features/activity/models/activity_intensity.dart';
import 'package:doce_equilibrio/features/activity/models/activity_type.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_period.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/insulin/domain/services/insulin_dose_calculator.dart';
import 'package:doce_equilibrio/features/meals/domain/services/carbohydrate_calculator.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

enum DevSeedStatus { created, alreadyExists, disabled }

class DevSeedResult {
  const DevSeedResult({
    required this.status,
    this.glycemias = 0,
    this.foods = 0,
    this.meals = 0,
    this.mealItems = 0,
    this.insulinApplications = 0,
    this.medications = 0,
    this.reminders = 0,
    this.activities = 0,
    this.startDate,
    this.endDate,
    this.hba1cPercentage,
  });

  final DevSeedStatus status;
  final int glycemias;
  final int foods;
  final int meals;
  final int mealItems;
  final int insulinApplications;
  final int medications;
  final int reminders;
  final int activities;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? hba1cPercentage;
}

class DevDatabaseSeeder {
  DevDatabaseSeeder(this._connection);

  static const email = 'teste@doceequilibrio.local';
  static const password = 'Teste@123';
  static const _salt = 'ZGV2LXNlZWQtc2FsdC0yMDI2';

  final DatabaseConnection _connection;

  static bool shouldRun(bool enabled) => kDebugMode && enabled;

  Future<DevSeedResult> seed({
    DatabaseExecutor? executor,
    DateTime? referenceDate,
  }) async {
    if (!kDebugMode) {
      return const DevSeedResult(status: DevSeedStatus.disabled);
    }
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (executor != null) return _seed(executor, today);

    final database = await _connection.database;
    return database.transaction((transaction) => _seed(transaction, today));
  }

  Future<DevSeedResult> _seed(DatabaseExecutor db, DateTime today) async {
    final existing = await db.query(
      'Usuario',
      columns: const ['id'],
      where: 'email = ?',
      whereArgs: const [email],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return const DevSeedResult(status: DevSeedStatus.alreadyExists);
    }

    final startDate = today.subtract(const Duration(days: 89));
    final userId = await _insertUser(db, today);
    final foods = await _insertFoods(db, userId);
    final medicationIds = await _insertMedications(db, userId, today);
    final glycemias = await _insertGlycemias(db, userId, startDate);
    final mealResult = await _insertMealsAndApplications(
      db,
      userId,
      foods,
      startDate,
    );
    final activities = await _insertActivities(db, userId, startDate);
    final reminders = await _insertReminders(db, userId, medicationIds);
    final estimate = const HbA1cCalculator().calculate(
      glycemias.map((entry) => entry.value),
    );
    if (estimate == null) throw StateError('Seed sem dados para HbA1c.');

    return DevSeedResult(
      status: DevSeedStatus.created,
      glycemias: glycemias.length,
      foods: foods.length,
      meals: mealResult.meals,
      mealItems: mealResult.items,
      insulinApplications: mealResult.applications,
      medications: medicationIds.length,
      reminders: reminders,
      activities: activities,
      startDate: startDate,
      endDate: today,
      hba1cPercentage: estimate.percentage,
    );
  }

  Future<int> _insertUser(DatabaseExecutor db, DateTime today) {
    return db.insert('Usuario', {
      'nome': 'Usuário Teste',
      'email': email,
      'tipoDiabetes': 'Tipo 1',
      'anoDiagnostico': today.year - 8,
      'senha': EncryptionUtils.generateSaltedHash(password, _salt),
      'salt': _salt,
      'peso': 72.0,
      'altura': 172,
      'limiteNormalMinimo': 70,
      'limitePerigoAlto': 180,
      'fatorSensibilidade': 12.0,
      'fatorCorrecao': 40.0,
      'metaGlicemica': 100,
    });
  }

  Future<List<_SeedFood>> _insertFoods(DatabaseExecutor db, int userId) async {
    const definitions = [
      ('Arroz', 100.0, 'g', 28.0),
      ('Feijão', 100.0, 'g', 14.0),
      ('Frango', 100.0, 'g', 0.0),
      ('Pão', 50.0, 'g', 25.0),
      ('Leite', 200.0, 'ml', 10.0),
      ('Banana', 80.0, 'g', 18.0),
      ('Aveia', 30.0, 'g', 20.0),
      ('Batata', 100.0, 'g', 20.0),
      ('Macarrão', 100.0, 'g', 30.0),
      ('Maçã', 100.0, 'g', 14.0),
      ('Iogurte', 170.0, 'g', 12.0),
      ('Café', 100.0, 'ml', 0.0),
    ];
    final foods = <_SeedFood>[];
    for (final definition in definitions) {
      final per100 = definition.$3 == 'g'
          ? definition.$4 / definition.$2 * 100
          : definition.$4;
      final id = await db.insert('Alimento', {
        'usuarioId': userId,
        'nome': definition.$1,
        'carboidratosPor100g': per100,
        'porcaoQuantidade': definition.$2,
        'porcaoUnidade': definition.$3,
        'carboidratosPorPorcao': definition.$4,
      });
      foods.add(
        _SeedFood(
          id: id,
          name: definition.$1,
          serving: definition.$2,
          unit: definition.$3,
          carbohydrates: definition.$4,
        ),
      );
    }
    return foods;
  }

  Future<List<int>> _insertMedications(
    DatabaseExecutor db,
    int userId,
    DateTime today,
  ) async {
    final definitions = [
      ('Medicamento Teste A', '500 mg', 'Uso exclusivamente fictício'),
      ('Medicamento Teste B', '10 mg', 'Dados para validação da interface'),
      ('Suplemento Teste', '1 unidade', null),
    ];
    final ids = <int>[];
    for (var index = 0; index < definitions.length; index++) {
      final item = definitions[index];
      ids.add(
        await db.insert('Medicamento', {
          'usuarioId': userId,
          'nome': item.$1,
          'dosagem': item.$2,
          'dataHora': today.subtract(Duration(days: index)).toIso8601String(),
          'observacao': item.$3,
        }),
      );
    }
    return ids;
  }

  Future<List<_SeedGlycemia>> _insertGlycemias(
    DatabaseExecutor db,
    int userId,
    DateTime start,
  ) async {
    final entries = <_SeedGlycemia>[];
    const hours = [7, 11, 16, 21];
    for (var day = 0; day < 90; day++) {
      if (day % 13 == 5) continue;
      final count = 2 + day % 3;
      for (var measurement = 0; measurement < count; measurement++) {
        final marker = (day * 4 + measurement) % 19;
        final value = marker == 0
            ? 64 + day % 5
            : marker == 1
            ? 185 + day % 25
            : 82 + (day * 11 + measurement * 17) % 94;
        final dateTime = start.add(
          Duration(days: day, hours: hours[measurement], minutes: day % 4 * 7),
        );
        await db.insert('Glicemia', {
          'usuarioId': userId,
          'valor': value,
          'periodo': GlycemiaPeriod
              .options[(day + measurement) % GlycemiaPeriod.options.length],
          'dataHora': dateTime.toIso8601String(),
          'observacao': marker % 7 == 0 ? 'Registro fictício de teste' : null,
        });
        entries.add(_SeedGlycemia(value: value, dateTime: dateTime));
      }
    }
    return entries;
  }

  Future<_MealSeedResult> _insertMealsAndApplications(
    DatabaseExecutor db,
    int userId,
    List<_SeedFood> foods,
    DateTime start,
  ) async {
    var meals = 0;
    var items = 0;
    var applications = 0;
    for (var day = 0; day < 90; day++) {
      final types = <MealType>[MealType.almoco];
      if (day % 3 == 0) types.add(MealType.cafeDaManha);
      if (day % 5 == 0) types.add(MealType.jantar);
      if (day % 7 == 0) types.add(MealType.lanche);
      for (var mealIndex = 0; mealIndex < types.length; mealIndex++) {
        final type = types[mealIndex];
        final hour = switch (type) {
          MealType.cafeDaManha => 8,
          MealType.almoco => 12,
          MealType.lanche => 16,
          MealType.jantar => 20,
          _ => 14,
        };
        final dateTime = start.add(Duration(days: day, hours: hour));
        final mealId = await db.insert('Refeicao', {
          'usuarioId': userId,
          'tipo': type.name,
          'dataHora': dateTime.toIso8601String(),
          'favorita': day % 17 == 0 ? 1 : 0,
        });
        meals++;

        final selectedFoods = [
          foods[(day + mealIndex) % foods.length],
          foods[(day + mealIndex + 4) % foods.length],
        ];
        final itemCarbohydrates = <double>[];
        for (var itemIndex = 0; itemIndex < selectedFoods.length; itemIndex++) {
          final food = selectedFoods[itemIndex];
          final consumed = food.serving * (itemIndex == 0 ? 1.0 : 0.75);
          final carbohydrates = CarbohydrateCalculator.forItem(
            carbohydratesPerServing: food.carbohydrates,
            standardServing: food.serving,
            consumedQuantity: consumed,
          );
          itemCarbohydrates.add(carbohydrates);
          await db.insert('RefeicaoItem', {
            'refeicaoId': mealId,
            'alimentoId': food.id,
            'nomeAlimento': food.name,
            'carboidratosPor100g': food.unit == 'g'
                ? food.carbohydrates / food.serving * 100
                : food.carbohydrates,
            'quantidadeGramas': consumed,
            'porcaoQuantidade': food.serving,
            'porcaoUnidade': food.unit,
            'carboidratosPorPorcao': food.carbohydrates,
            'quantidadeConsumida': consumed,
          });
          items++;
        }

        if (type == MealType.almoco && day.isEven) {
          final carbohydrates = CarbohydrateCalculator.total(itemCarbohydrates);
          final glycemia = 95 + day % 70;
          final calculation = InsulinDoseCalculator.calculate(
            currentGlycemia: glycemia,
            carbohydratesGrams: carbohydrates,
            glycemiaTarget: 100,
            correctionFactor: 40,
            insulinCarbohydrateRatio: 12,
          );
          final appliedAdjustment = day % 4 == 0 ? -0.5 : 0.0;
          final applied = (calculation.totalDose + appliedAdjustment).clamp(
            0,
            double.infinity,
          );
          await db.insert('AplicacaoInsulina', {
            'usuarioId': userId,
            'glicemia': glycemia,
            'carboidratos': carbohydrates,
            'doseAlimentar': calculation.carbohydrateDose,
            'doseCorrecao': calculation.correctionDose,
            'doseRecomendada': calculation.totalDose,
            'doseAplicada': applied,
            'dataHora': dateTime
                .add(const Duration(minutes: 10))
                .toIso8601String(),
            'observacao': day % 10 == 0 ? 'Aplicação fictícia vinculada' : null,
            'refeicaoId': mealId,
          });
          applications++;
        }
      }
    }
    return _MealSeedResult(
      meals: meals,
      items: items,
      applications: applications,
    );
  }

  Future<int> _insertActivities(
    DatabaseExecutor db,
    int userId,
    DateTime start,
  ) async {
    var count = 0;
    for (var day = 0; day < 90; day += 3) {
      final type = ActivityType.values[(day ~/ 3) % 4];
      final intensity = ActivityIntensity.values[(day ~/ 3) % 3];
      await db.insert('Atividade', {
        'usuarioId': userId,
        'tipo': type.name,
        'duracaoMinutos': 20 + (day % 5) * 10,
        'dataHora': start.add(Duration(days: day, hours: 18)).toIso8601String(),
        'intensidade': intensity.label,
        'observacao': day % 9 == 0 ? 'Atividade fictícia de teste' : null,
      });
      count++;
    }
    return count;
  }

  Future<int> _insertReminders(
    DatabaseExecutor db,
    int userId,
    List<int> medicationIds,
  ) async {
    final reminders = [
      (ReminderType.insulinaBasal, 'Insulina basal teste', 22, 0, null, 1),
      (
        ReminderType.medication,
        'Medicamento teste A',
        8,
        0,
        medicationIds[0],
        1,
      ),
      (ReminderType.medication, 'Medicamento sem vínculo', 13, 0, null, 0),
      (ReminderType.outro, 'Lembrete inativo de teste', 18, 30, null, 0),
    ];
    for (final reminder in reminders) {
      await db.insert('Lembrete', {
        'usuarioId': userId,
        'tipo': reminder.$1.name,
        'titulo': reminder.$2,
        'hora': reminder.$3,
        'minuto': reminder.$4,
        'repetir': 1,
        'diasSemana': '1,2,3,4,5,6,7',
        'data': null,
        'ativo': reminder.$6,
        'medicamentoId': reminder.$5,
      });
    }
    return reminders.length;
  }
}

class _SeedFood {
  const _SeedFood({
    required this.id,
    required this.name,
    required this.serving,
    required this.unit,
    required this.carbohydrates,
  });

  final int id;
  final String name;
  final double serving;
  final String unit;
  final double carbohydrates;
}

class _SeedGlycemia {
  const _SeedGlycemia({required this.value, required this.dateTime});

  final int value;
  final DateTime dateTime;
}

class _MealSeedResult {
  const _MealSeedResult({
    required this.meals,
    required this.items,
    required this.applications,
  });

  final int meals;
  final int items;
  final int applications;
}
