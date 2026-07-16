import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';

class UsuarioRepository implements IUsuarioRepository {
  final DatabaseConnection _dbConnection;

  UsuarioRepository(this._dbConnection);

  @override
  Future<int> criar(UsuarioModel usuario) async {
    final db = await _dbConnection.database;
    return await db.insert('Usuario', usuario.toMap());
  }

  @override
  Future<UsuarioModel?> buscar() async {
    final db = await _dbConnection.database;
    final maps = await db.query('Usuario', limit: 1);

    if (maps.isNotEmpty) {
      return UsuarioModel.fromMap(maps.first);
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
  Future<UsuarioModel?> autenticar(String email, String senha) async {
    final db = await _dbConnection.database;
    final maps = await db.query(
      'Usuario',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UsuarioModel.fromMap(maps.first);
    }
    return null;
  }
}
