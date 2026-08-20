import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:doce_equilibrio/features/auth/controllers/login_controller.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inicia sessão quando e-mail e senha são válidos', () async {
    const salt = 'salt-de-teste';
    final repository = _FakeUserRepository(
      UserModel(
        id: 5,
        name: 'Ana',
        email: 'ana@example.com',
        diabetesType: 'Tipo 1',
        diagnosisYear: 2020,
        password: EncryptionUtils.generateSaltedHash('senha123', salt),
        salt: salt,
      ),
    );
    final session = _FakeSessionService();
    final controller = LoginController(repository, session);

    final error = await controller.login(
      email: ' ana@example.com ',
      password: 'senha123',
    );

    expect(error, isNull);
    expect(repository.searchedEmail, 'ana@example.com');
    expect(session.startedUserId, 5);
  });

  test('não inicia sessão com senha inválida', () async {
    const salt = 'salt-de-teste';
    final repository = _FakeUserRepository(
      UserModel(
        id: 5,
        name: 'Ana',
        email: 'ana@example.com',
        diabetesType: 'Tipo 1',
        diagnosisYear: 2020,
        password: EncryptionUtils.generateSaltedHash('senha123', salt),
        salt: salt,
      ),
    );
    final session = _FakeSessionService();
    final controller = LoginController(repository, session);

    final error = await controller.login(
      email: 'ana@example.com',
      password: 'outra-senha',
    );

    expect(error, isNotNull);
    expect(session.startedUserId, isNull);
  });
}

class _FakeUserRepository implements UserRepositoryInterface {
  _FakeUserRepository(this.user);

  final UserModel? user;
  String? searchedEmail;

  @override
  Future<UserModel?> findByEmail(String email) async {
    searchedEmail = email;
    return user;
  }

  @override
  Future<int> create(UserModel user) async => 1;

  @override
  Future<bool> emailJaCadastrado(String email) async => false;

  @override
  Future<UserModel?> find(int id) async => user;

  @override
  Future<int> update(UserModel user) async => 1;
}

class _FakeSessionService implements SessionService {
  int? startedUserId;

  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => startedUserId;

  @override
  Future<void> startSession(int userId) async {
    startedUserId = userId;
  }
}
