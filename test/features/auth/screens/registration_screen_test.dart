import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/auth/controllers/login_controller.dart';
import 'package:doce_equilibrio/features/auth/controllers/registration_controller.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/auth/screens/login_screen.dart';
import 'package:doce_equilibrio/features/auth/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => getIt.reset());

  testWidgets('cadastro concluído retorna ao login sem iniciar sessão', (
    tester,
  ) async {
    final repository = _FakeUserRepository();
    final session = _FakeSessionService();
    getIt.registerFactory<RegistrationController>(
      () => RegistrationController(repository),
    );
    getIt.registerFactory<LoginController>(
      () => LoginController(repository, session),
    );

    await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Maria');
    await tester.enterText(fields.at(1), 'maria@example.com');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tipo 1').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), '2020');
    await tester.enterText(fields.at(3), '65');
    await tester.enterText(fields.at(4), '165');
    await tester.enterText(fields.at(5), 'Senha@123');
    await tester.enterText(fields.at(6), 'Senha@123');

    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Cadastro realizado com sucesso. Faça login.'),
      findsOneWidget,
    );
    expect(repository.createdUser, isNotNull);
    expect(session.startedUserId, isNull);
  });
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
