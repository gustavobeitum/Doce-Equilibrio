import 'dart:convert';
import 'dart:math';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseConnection {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  factory DatabaseConnection() => _instance;
  DatabaseConnection._internal();

  static Database? _database;

  static const int _databaseVersion = 12;

  final _secureStorage = const FlutterSecureStorage();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> _getEncryptionKey() async {
    const keyName = 'db_encryption_key';
    String? key = await _secureStorage.read(key: keyName);

    if (key == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(keyBytes);

      await _secureStorage.write(key: keyName, value: key);
    }

    return key;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'doce_equilibrio.db');

    final encryptionKey = await _getEncryptionKey();

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: encryptionKey,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Ponto unico de verdade para instalacoes novas. Bancos existentes sao
  // atualizados de forma aditiva por [_onUpgrade], sem apagar dados.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        tipoDiabetes TEXT NOT NULL,
        anoDiagnostico INTEGER NOT NULL,
        senha TEXT NOT NULL,
        salt TEXT NOT NULL,
        peso REAL,
        altura INTEGER,
        limitePerigoBaixo INTEGER NOT NULL DEFAULT 50,
        limiteNormalMinimo INTEGER NOT NULL DEFAULT 70,
        limiteNormalMaximo INTEGER NOT NULL DEFAULT 140,
        limitePerigoAlto INTEGER NOT NULL DEFAULT 180,
        fatorSensibilidade REAL NOT NULL DEFAULT 15,
        fatorCorrecao REAL NOT NULL DEFAULT 20,
        metaGlicemica INTEGER NOT NULL DEFAULT 100
      )
    ''');

    await db.execute('''
      CREATE TABLE Glicemia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        valor INTEGER NOT NULL,
        periodo TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_glicemia_user_data ON Glicemia (usuarioId, dataHora)',
    );

    await db.execute('''
      CREATE TABLE Lembrete (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        hora INTEGER NOT NULL,
        minuto INTEGER NOT NULL,
        repetir INTEGER NOT NULL DEFAULT 1,
        diasSemana TEXT NOT NULL,
        data TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_lembrete_user ON Lembrete (usuarioId)');

    await db.execute('''
      CREATE TABLE Alimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        carboidratosPor100g REAL NOT NULL,
        porcaoQuantidade REAL NOT NULL DEFAULT 100,
        porcaoUnidade TEXT NOT NULL DEFAULT 'g',
        carboidratosPorPorcao REAL NOT NULL,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_alimento_user ON Alimento (usuarioId)');

    await db.execute('''
      CREATE TABLE Refeicao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        favorita INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_refeicao_user_data ON Refeicao (usuarioId, dataHora)',
    );

    await db.execute('''
      CREATE TABLE RefeicaoItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refeicaoId INTEGER NOT NULL,
        alimentoId INTEGER NOT NULL,
        nomeAlimento TEXT NOT NULL,
        carboidratosPor100g REAL NOT NULL,
        quantidadeGramas REAL NOT NULL,
        porcaoQuantidade REAL NOT NULL DEFAULT 100,
        porcaoUnidade TEXT NOT NULL DEFAULT 'g',
        carboidratosPorPorcao REAL NOT NULL,
        quantidadeConsumida REAL NOT NULL,
        FOREIGN KEY (refeicaoId) REFERENCES Refeicao (id) ON DELETE CASCADE,
        FOREIGN KEY (alimentoId) REFERENCES Alimento (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_refeicaoitem_refeicao ON RefeicaoItem (refeicaoId)',
    );

    await _createInsulinApplicationTable(db);

    await db.execute('''
      CREATE TABLE Atividade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        duracaoMinutos INTEGER NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_atividade_user_data ON Atividade (usuarioId, dataHora)',
    );

    await db.execute('''
      CREATE TABLE Medicamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        dosagem TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_medicamento_user_data '
      'ON Medicamento (usuarioId, dataHora)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'salt',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(txn, 'Usuario', 'peso', 'REAL');
      await _addColumnIfMissing(txn, 'Usuario', 'altura', 'INTEGER');
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'limitePerigoBaixo',
        'INTEGER NOT NULL DEFAULT 50',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'limiteNormalMinimo',
        'INTEGER NOT NULL DEFAULT 70',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'limiteNormalMaximo',
        'INTEGER NOT NULL DEFAULT 140',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'limitePerigoAlto',
        'INTEGER NOT NULL DEFAULT 180',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'fatorSensibilidade',
        'REAL NOT NULL DEFAULT 15',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'fatorCorrecao',
        'REAL NOT NULL DEFAULT 20',
      );
      await _addColumnIfMissing(
        txn,
        'Usuario',
        'metaGlicemica',
        'INTEGER NOT NULL DEFAULT 100',
      );

      await _createFeatureTables(txn);
      await _migrateFoodServings(txn);
      await _createInsulinApplicationTable(txn);
    });
  }

  Future<void> _createFeatureTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Glicemia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        valor INTEGER NOT NULL,
        periodo TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_glicemia_user_data '
      'ON Glicemia (usuarioId, dataHora)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Lembrete (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        hora INTEGER NOT NULL,
        minuto INTEGER NOT NULL,
        repetir INTEGER NOT NULL DEFAULT 1,
        diasSemana TEXT NOT NULL,
        data TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lembrete_user ON Lembrete (usuarioId)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Alimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        carboidratosPor100g REAL NOT NULL,
        porcaoQuantidade REAL NOT NULL DEFAULT 100,
        porcaoUnidade TEXT NOT NULL DEFAULT 'g',
        carboidratosPorPorcao REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alimento_user ON Alimento (usuarioId)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Refeicao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        favorita INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_refeicao_user_data '
      'ON Refeicao (usuarioId, dataHora)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RefeicaoItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refeicaoId INTEGER NOT NULL,
        alimentoId INTEGER NOT NULL,
        nomeAlimento TEXT NOT NULL,
        carboidratosPor100g REAL NOT NULL,
        quantidadeGramas REAL NOT NULL,
        porcaoQuantidade REAL NOT NULL DEFAULT 100,
        porcaoUnidade TEXT NOT NULL DEFAULT 'g',
        carboidratosPorPorcao REAL NOT NULL DEFAULT 0,
        quantidadeConsumida REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (refeicaoId) REFERENCES Refeicao (id) ON DELETE CASCADE,
        FOREIGN KEY (alimentoId) REFERENCES Alimento (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_refeicaoitem_refeicao '
      'ON RefeicaoItem (refeicaoId)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Atividade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        duracaoMinutos INTEGER NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_atividade_user_data '
      'ON Atividade (usuarioId, dataHora)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Medicamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        dosagem TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medicamento_user_data '
      'ON Medicamento (usuarioId, dataHora)',
    );
  }

  Future<void> _migrateFoodServings(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      'Alimento',
      'porcaoQuantidade',
      'REAL NOT NULL DEFAULT 100',
    );
    await _addColumnIfMissing(
      db,
      'Alimento',
      'porcaoUnidade',
      "TEXT NOT NULL DEFAULT 'g'",
    );
    await _addColumnIfMissing(
      db,
      'Alimento',
      'carboidratosPorPorcao',
      'REAL NOT NULL DEFAULT 0',
    );
    await db.execute('''
      UPDATE Alimento
      SET carboidratosPorPorcao = carboidratosPor100g
      WHERE porcaoQuantidade = 100
        AND porcaoUnidade = 'g'
        AND carboidratosPorPorcao = 0
    ''');

    await _addColumnIfMissing(
      db,
      'RefeicaoItem',
      'porcaoQuantidade',
      'REAL NOT NULL DEFAULT 100',
    );
    await _addColumnIfMissing(
      db,
      'RefeicaoItem',
      'porcaoUnidade',
      "TEXT NOT NULL DEFAULT 'g'",
    );
    await _addColumnIfMissing(
      db,
      'RefeicaoItem',
      'carboidratosPorPorcao',
      'REAL NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'RefeicaoItem',
      'quantidadeConsumida',
      'REAL NOT NULL DEFAULT 0',
    );
    await db.execute('''
      UPDATE RefeicaoItem
      SET carboidratosPorPorcao = carboidratosPor100g,
          quantidadeConsumida = quantidadeGramas
      WHERE porcaoQuantidade = 100
        AND porcaoUnidade = 'g'
        AND carboidratosPorPorcao = 0
    ''');
  }

  Future<void> _createInsulinApplicationTable(DatabaseExecutor db) async {
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

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
