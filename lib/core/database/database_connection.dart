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
      version: 1,
      password: encryptionKey,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        tipoDiabetes TEXT NOT NULL,
        anoDiagnostico INTEGER NOT NULL,
        senha TEXT NOT NULL
      )
    ''');
  }
}
