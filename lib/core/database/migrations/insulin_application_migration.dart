import 'package:sqflite_sqlcipher/sqflite.dart';

abstract final class InsulinApplicationMigration {
  static const version = 12;

  static Future<void> migrate(
    DatabaseExecutor db, {
    required int oldVersion,
    required int newVersion,
  }) async {
    if (oldVersion >= version || newVersion < version) return;
    await create(db);
  }

  static Future<void> create(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AplicacaoInsulina (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        glicemia INTEGER NOT NULL,
        carboidratos REAL NOT NULL,
        doseAlimentar REAL NOT NULL,
        doseCorrecao REAL NOT NULL,
        doseRecomendada REAL NOT NULL,
        doseAplicada REAL NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        refeicaoId INTEGER,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE,
        FOREIGN KEY (refeicaoId) REFERENCES Refeicao (id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_aplicacao_insulina_user_data '
      'ON AplicacaoInsulina (usuarioId, dataHora)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_aplicacao_insulina_refeicao '
      'ON AplicacaoInsulina (refeicaoId)',
    );
  }
}
