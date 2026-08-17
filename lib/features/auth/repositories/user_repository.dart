import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';

class UserRepository implements UserRepositoryInterface {
  final DatabaseConnection _dbConnection;

  UserRepository(this._dbConnection);

  @override
  Future<int> create(UserModel user) async {
    final db = await _dbConnection.database;
    return await db.insert('Usuario', user.toMap());
  }

  @override
  Future<UserModel?> find(int id) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Usuario',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<bool> emailJaCadastrado(String email) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Usuario',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  @override
  Future<UserModel?> findByEmail(String email) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Usuario',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> update(UserModel user) async {
    final db = await _dbConnection.database;
    return await db.update(
      'Usuario',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
