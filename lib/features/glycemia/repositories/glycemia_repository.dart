import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';

class GlycemiaRepository implements GlycemiaRepositoryInterface {
  final DatabaseConnection _dbConnection;

  GlycemiaRepository(this._dbConnection);

  @override
  Future<int> create(GlycemiaRecordModel record) async {
    final db = await _dbConnection.database;
    return await db.insert('Glicemia', record.toMap());
  }

  @override
  Future<int> update(GlycemiaRecordModel record) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Glicemia',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbConnection.database;
    return await db.delete('Glicemia', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<GlycemiaRecordModel>> listByUser(int userId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Glicemia',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'dataHora DESC',
    );
    return maps.map((map) => GlycemiaRecordModel.fromMap(map)).toList();
  }

  @override
  Future<List<GlycemiaRecordModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Glicemia',
      where: 'usuarioId = ? AND dataHora >= ? AND dataHora <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dataHora DESC',
    );
    return maps.map(GlycemiaRecordModel.fromMap).toList();
  }

  @override
  Future<GlycemiaRecordModel?> findLatestReading(int userId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Glicemia',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'dataHora DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GlycemiaRecordModel.fromMap(maps.first);
    }
    return null;
  }
}
