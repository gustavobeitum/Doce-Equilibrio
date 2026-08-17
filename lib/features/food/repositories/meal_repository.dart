import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/food/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_model.dart';
import 'package:doce_equilibrio/features/food/repositories/meal_repository_interface.dart';

class MealRepository implements MealRepositoryInterface {
  final DatabaseConnection _dbConnection;

  MealRepository(this._dbConnection);

  @override
  Future<int> create(MealModel meal) async {
    final db = await _dbConnection.database;
    return db.transaction((txn) async {
      final mealId = await txn.insert('Refeicao', meal.toMap());
      for (final item in meal.items) {
        final mapaItem = item.toMap()
          ..['id'] = null
          ..['refeicaoId'] = mealId;
        await txn.insert('RefeicaoItem', mapaItem);
      }
      return mealId;
    });
  }

  @override
  Future<int> update(MealModel meal) async {
    final db = await _dbConnection.database;
    await db.transaction((txn) async {
      await txn.update(
        'Refeicao',
        meal.toMap(),
        where: 'id = ?',
        whereArgs: [meal.id],
      );
      await txn.delete(
        'RefeicaoItem',
        where: 'refeicaoId = ?',
        whereArgs: [meal.id],
      );
      for (final item in meal.items) {
        final mapaItem = item.toMap()
          ..['id'] = null
          ..['refeicaoId'] = meal.id;
        await txn.insert('RefeicaoItem', mapaItem);
      }
    });
    return meal.id!;
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbConnection.database;
    // RefeicaoItem tem ON DELETE CASCADE em refeicaoId, então os itens
    // somem junto automaticamente.
    return await db.delete('Refeicao', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<MealModel>> listByUser(int userId) async {
    final db = await _dbConnection.database;
    final mapasRefeicoes = await db.query(
      'Refeicao',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'dataHora DESC',
    );

    final meals = <MealModel>[];
    for (final mealMap in mapasRefeicoes) {
      final mapasItens = await db.query(
        'RefeicaoItem',
        where: 'refeicaoId = ?',
        whereArgs: [mealMap['id']],
      );
      final items = mapasItens
          .map((map) => MealItemModel.fromMap(map))
          .toList();
      meals.add(MealModel.fromMap(mealMap, items: items));
    }
    return meals;
  }
}
