import 'package:doce_equilibrio/core/errors/auth_exceptions.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:flutter/foundation.dart';

class LoginController {
  final UserRepositoryInterface _userRepository;
  final SessionService _sessionService;

  LoginController(this._userRepository, this._sessionService);

  /// Realiza o login validando o hash da senha na camada de aplicação
  /// (nunca via comparação direta na query SQL).
  ///
  /// Retorna `null` em caso de sucesso, ou uma mensagem de erro que já
  /// diferencia credenciais inválidas de falhas de conexão/banco de dados.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _userRepository.findByEmail(email.trim());

      if (user == null || user.salt.isEmpty) {
        throw const InvalidCredentialsException();
      }

      final senhaValida = EncryptionUtils.validatePassword(
        enteredPassword: password,
        storedHash: user.password,
        salt: user.salt,
      );

      if (!senhaValida) {
        throw const InvalidCredentialsException();
      }

      await _sessionService.startSession(user.id!);
      return null;
    } on InvalidCredentialsException catch (e) {
      return e.message;
    } catch (e) {
      // Qualquer outra falha (banco indisponível, erro de I/O, chave de
      // criptografia inacessível etc.) é tratada como falha de
      // infraestrutura, nunca é mascarada como "credenciais inválidas".
      debugPrint('ERRO AO REALIZAR LOGIN: $e');
      return const DatabaseConnectionException().message;
    }
  }
}
