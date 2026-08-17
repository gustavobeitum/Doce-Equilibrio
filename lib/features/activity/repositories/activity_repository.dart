import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository_interface.dart';

class ActivityRepository implements ActivityRepositoryInterface {
  final DatabaseConnection _dbConnection;

  ActivityRepository(this._dbConnection);

  @override
  Future<int> criar(ActivityModel atividade) async {
    final db = await _dbConnection.database;
    return await db.insert('Atividade', atividade.toMap());
  }

  @override
  Future<int> atualizar(ActivityModel atividade) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Atividade',
      atividade.toMap(),
      where: 'id = ?',
      whereArgs: [atividade.id],
    );
  }

  @override
  Future<int> excluir(int id) async {
    final db = await _dbConnection.database;
    return await db.delete('Atividade', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ActivityModel>> listByUser(int usuarioId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Atividade',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'dataHora DESC',
    );
    return maps.map((map) => ActivityModel.fromMap(map)).toList();
  }
}
