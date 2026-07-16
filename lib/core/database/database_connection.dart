import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConnection {
  static final DatabaseConnection instance = DatabaseConnection._();
  static Database? _database;

  DatabaseConnection._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('doce_equilibrio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        tipoDiabetes TEXT NOT NULL,
        anoDiagnostico INTEGER NOT NULL,
        senha TEXT NOT NULL
      )
    ''');
  }
}