import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';

class FoodRepository implements FoodRepositoryInterface {
  final DatabaseConnection _dbConnection;

  FoodRepository(this._dbConnection);

  @override
  Future<int> create(FoodModel food) async {
    final db = await _dbConnection.database;
    return await db.insert('Alimento', food.toMap());
  }

  @override
  Future<int> update(FoodModel food) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Alimento',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbConnection.database;
    return await db.delete('Alimento', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<FoodModel>> listByUser(int userId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Alimento',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'nome ASC',
    );
    return maps.map((map) => FoodModel.fromMap(map)).toList();
  }
}
