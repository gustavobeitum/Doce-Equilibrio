import 'package:sqflite_sqlcipher/sqflite.dart';

abstract final class FinalFeaturesMigration {
  static const version = 13;

  static Future<void> migrate(
    DatabaseExecutor db, {
    required int oldVersion,
    required int newVersion,
  }) async {
    if (oldVersion >= version || newVersion < version) return;

    await _addColumnIfMissing(db, 'Atividade', 'intensidade', 'TEXT');
    await _addColumnIfMissing(
      db,
      'Lembrete',
      'medicamentoId',
      'INTEGER REFERENCES Medicamento (id) ON DELETE SET NULL',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lembrete_medicamento '
      'ON Lembrete (medicamentoId)',
    );
  }

  static Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
