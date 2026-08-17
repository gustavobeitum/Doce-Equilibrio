import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeController {
  final UserRepositoryInterface repository;
  final FlutterSecureStorage _storage;

  HomeController(this.repository, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  String getGreeting() {
    final horaAtual = DateTime.now().hour;

    if (horaAtual >= 5 && horaAtual < 12) {
      return 'Bom dia,';
    } else if (horaAtual >= 12 && horaAtual < 18) {
      return 'Boa tarde,';
    } else {
      return 'Boa noite,';
    }
  }

  String nameFormatted(String fullName) {
    if (fullName.trim().isEmpty) return '';

    final partes = fullName.trim().split(RegExp(r'\s+'));

    if (partes.length == 1) {
      return '${partes.first}!';
    }

    return '${partes.first} ${partes.last}!';
  }

  /// Busca o usuário atualmente autenticado, a partir do `usuario_id`
  /// salvo no armazenamento seguro no momento do login/cadastro.
  /// Retorna `null` se não houver sessão ativa ou o usuário não for
  /// encontrado no banco.
  Future<UserModel?> findLoggedInUser() async {
    final idString = await _storage.read(key: 'usuario_id');
    if (idString == null) return null;

    final id = int.tryParse(idString);
    if (id == null) return null;

    return repository.find(id);
  }
}
