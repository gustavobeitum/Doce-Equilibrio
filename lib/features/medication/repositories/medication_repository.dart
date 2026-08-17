import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository_interface.dart';

class MedicationRepository implements MedicationRepositoryInterface {
  final DatabaseConnection _dbConnection;

  MedicationRepository(this._dbConnection);

  @override
  Future<int> criar(MedicationModel medicamento) async {
    final db = await _dbConnection.database;
    return await db.insert('Medicamento', medicamento.toMap());
  }

  @override
  Future<int> atualizar(MedicationModel medicamento) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Medicamento',
      medicamento.toMap(),
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
  }

  @override
  Future<int> excluir(int id) async {
    final db = await _dbConnection.database;
    return await db.delete('Medicamento', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<MedicationModel>> listByUser(int usuarioId) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Medicamento',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'dataHora DESC',
    );
    return maps.map((map) => MedicationModel.fromMap(map)).toList();
  }
}
