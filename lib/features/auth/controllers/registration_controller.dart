import 'package:doce_equilibrio/core/errors/auth_exceptions.dart';
import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:flutter/material.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';

class RegistrationController {
  final UserRepositoryInterface _userRepository;

  RegistrationController(this._userRepository);

  /// Cadastra um novo usuário, gerando um salt aleatório único para ele e
  /// armazenando apenas o hash da senha (nunca a senha em texto puro).
  ///
  /// [peso] e [altura] são obrigatórios já no cadastro inicial, conforme
  /// RF-001 / UC-01 da documentação do TCC.
  Future<String?> register({
    required String name,
    required String email,
    required String diabetesType,
    required int diagnosisYear,
    required String password,
    required double weight,
    required int height,
  }) async {
    try {
      final emailExiste = await _userRepository.emailJaCadastrado(email.trim());
      if (emailExiste) {
        return 'Não foi possível concluir o cadastro. Verifique os dados informados ou tente acessar sua conta.';
      }

      final salt = EncryptionUtils.generateSalt();
      final senhaSegura = EncryptionUtils.generateSaltedHash(password, salt);

      final user = UserModel(
        name: name.trim(),
        email: email.trim(),
        diabetesType: diabetesType,
        diagnosisYear: diagnosisYear,
        password: senhaSegura,
        salt: salt,
        weight: weight,
        height: height,
      );

      final id = await _userRepository.create(user);

      if (id > 0) {
        return null;
      }

      return 'Ocorreu um erro no sistema. Tente novamente mais tarde.';
    } catch (e) {
      debugPrint('ERRO AO SALVAR USUÁRIO: $e');
      return const DatabaseConnectionException().message;
    }
  }
}
