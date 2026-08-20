import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseConnection {
  factory DatabaseConnection() => _instance;
  DatabaseConnection._internal();

  static final DatabaseConnection _instance = DatabaseConnection._internal();
  static const String _databaseName = 'doce_equilibrio.db';
  static const int _databaseVersion = 1;
  static Database? _database;

  final _secureStorage = const FlutterSecureStorage();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    final encryptionKey = await _getEncryptionKey();

    return openDatabase(
      path,
      version: _databaseVersion,
      password: encryptionKey,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<String> _getEncryptionKey() async {
    const keyName = 'db_encryption_key';
    var key = await _secureStorage.read(key: keyName);
    if (key != null) return key;

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    key = base64UrlEncode(keyBytes);
    await _secureStorage.write(key: keyName, value: key);
    return key;
  }

  Future<void> _onConfigure(Database db) => _configure(db);

  Future<void> _onCreate(Database db, int version) => _createSchema(db);

  Future<void> _configure(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await _createUsuarioTable(db);
    await _createAlimentoTable(db);
    await _createRefeicaoTable(db);
    await _createRefeicaoItemTable(db);
    await _createGlicemiaTable(db);
    await _createAtividadeTable(db);
    await _createMedicamentoTable(db);
    await _createLembreteTable(db);
    await _createInsulinApplicationTable(db);
    await _createIndexes(db);
  }

  @visibleForTesting
  Future<void> configureForTesting(DatabaseExecutor db) => _configure(db);

  @visibleForTesting
  Future<void> createSchemaForTesting(DatabaseExecutor db) => _createSchema(db);

  Future<void> _createUsuarioTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createAlimentoTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createRefeicaoTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createRefeicaoItemTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createGlicemiaTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createAtividadeTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE Atividade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        duracaoMinutos INTEGER NOT NULL,
        dataHora TEXT NOT NULL,
        intensidade TEXT,
        observacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMedicamentoTable(DatabaseExecutor db) async {
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
  }

  Future<void> _createLembreteTable(DatabaseExecutor db) async {
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
        medicamentoId INTEGER,
        FOREIGN KEY (usuarioId) REFERENCES Usuario (id) ON DELETE CASCADE,
        FOREIGN KEY (medicamentoId) REFERENCES Medicamento (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createInsulinApplicationTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE AplicacaoInsulina (
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
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX idx_glicemia_user_data ON Glicemia (usuarioId, dataHora)',
    );
    await db.execute('CREATE INDEX idx_alimento_user ON Alimento (usuarioId)');
    await db.execute(
      'CREATE INDEX idx_refeicao_user_data ON Refeicao (usuarioId, dataHora)',
    );
    await db.execute(
      'CREATE INDEX idx_refeicaoitem_refeicao ON RefeicaoItem (refeicaoId)',
    );
    await db.execute(
      'CREATE INDEX idx_atividade_user_data ON Atividade (usuarioId, dataHora)',
    );
    await db.execute(
      'CREATE INDEX idx_medicamento_user_data '
      'ON Medicamento (usuarioId, dataHora)',
    );
    await db.execute('CREATE INDEX idx_lembrete_user ON Lembrete (usuarioId)');
    await db.execute(
      'CREATE INDEX idx_lembrete_medicamento ON Lembrete (medicamentoId)',
    );
    await db.execute(
      'CREATE INDEX idx_aplicacao_insulina_user_data '
      'ON AplicacaoInsulina (usuarioId, dataHora)',
    );
    await db.execute(
      'CREATE INDEX idx_aplicacao_insulina_refeicao '
      'ON AplicacaoInsulina (refeicaoId)',
    );
  }
}
