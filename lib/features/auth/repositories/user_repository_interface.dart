import 'package:doce_equilibrio/features/auth/models/user_model.dart';

abstract class UserRepositoryInterface {
  Future<int> create(UserModel user);
  Future<UserModel?> find(int id);
  Future<bool> emailJaCadastrado(String email);

  /// Busca o usuário apenas pelo e-mail, sem envolver a senha na consulta.
  /// A validação da senha (hash + salt) é responsabilidade da camada de
  /// Controller, nunca do banco de dados.
  Future<UserModel?> findByEmail(String email);

  Future<int> update(UserModel user);
}
