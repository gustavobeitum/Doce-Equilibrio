import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/insulin/repositories/insulin_application_repository_interface.dart';

class InsulinApplicationRepository
    implements InsulinApplicationRepositoryInterface {
  final DatabaseConnection _connection;

  InsulinApplicationRepository(this._connection);

  @override
  Future<int> create(InsulinApplicationModel application) async {
    final db = await _connection.database;
    return db.insert('AplicacaoInsulina', application.toMap()..remove('id'));
  }

  @override
  Future<int> update(InsulinApplicationModel application) async {
    if (application.id == null) {
      throw ArgumentError('A aplicação precisa de ID para ser atualizada.');
    }
    final db = await _connection.database;
    final values = application.toMap()..remove('id');
    return db.update(
      'AplicacaoInsulina',
      values,
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [application.id, application.userId],
    );
  }

  @override
  Future<int> delete(int id, int userId) async {
    final db = await _connection.database;
    return db.delete(
      'AplicacaoInsulina',
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, userId],
    );
  }

  @override
  Future<InsulinApplicationModel?> findById(int id, int userId) async {
    final db = await _connection.database;
    final rows = await db.query(
      'AplicacaoInsulina',
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : InsulinApplicationModel.fromMap(rows.first);
  }

  @override
  Future<List<InsulinApplicationModel>> listByUser(int userId) async {
    final db = await _connection.database;
    final rows = await db.query(
      'AplicacaoInsulina',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'dataHora DESC',
    );
    return rows.map(InsulinApplicationModel.fromMap).toList();
  }

  @override
  Future<List<InsulinApplicationModel>> listByPeriod(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _connection.database;
    final rows = await db.query(
      'AplicacaoInsulina',
      where: 'usuarioId = ? AND dataHora >= ? AND dataHora <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dataHora DESC',
    );
    return rows.map(InsulinApplicationModel.fromMap).toList();
  }
}
