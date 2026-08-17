import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';

class ReminderRepository implements ReminderRepositoryInterface {
  final DatabaseConnection _dbConnection;

  ReminderRepository(this._dbConnection);

  @override
  Future<int> create(ReminderModel reminder) async {
    final db = await _dbConnection.database;
    return await db.insert('Lembrete', reminder.toMap());
  }

  @override
  Future<int> update(ReminderModel reminder) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Lembrete',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  @override
  Future<int> completeSingle(int id) async {
    final db = await _dbConnection.database;
    return db.update(
      'Lembrete',
      {'ativo': 0},
      where: 'id = ? AND repetir = 0',
      whereArgs: [id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbConnection.database;
    return await db.delete('Lembrete', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ReminderModel>> listByUser(int userId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Lembrete',
      where: 'usuarioId = ?',
      whereArgs: [userId],
      orderBy: 'hora ASC, minuto ASC',
    );
    return maps.map((map) => ReminderModel.fromMap(map)).toList();
  }
}
