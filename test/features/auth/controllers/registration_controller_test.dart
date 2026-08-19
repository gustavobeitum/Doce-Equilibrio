import 'package:doce_equilibrio/features/auth/controllers/registration_controller.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cadastro cria usuário sem iniciar sessão', () async {
    final repository = _FakeUserRepository();
    final controller = RegistrationController(repository);

    final error = await controller.register(
      name: 'Maria',
      email: 'maria@example.com',
      diabetesType: 'Tipo 1',
      diagnosisYear: 2020,
      password: 'Senha@123',
      weight: 65,
      height: 165,
    );

    expect(error, isNull);
    expect(repository.createdUser?.email, 'maria@example.com');
  });
}

class _FakeUserRepository implements UserRepositoryInterface {
  UserModel? createdUser;

  @override
  Future<int> create(UserModel user) async {
    createdUser = user;
    return 1;
  }

  @override
  Future<bool> emailJaCadastrado(String email) async => false;

  @override
  Future<UserModel?> find(int id) async => null;

  @override
  Future<UserModel?> findByEmail(String email) async => null;

  @override
  Future<int> update(UserModel user) async => 0;
}
