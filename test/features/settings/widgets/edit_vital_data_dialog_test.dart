import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:doce_equilibrio/features/settings/widgets/edit_vital_data_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('salva peso e altura e fecha sem FlutterError', (tester) async {
    final repository = _Repository();
    final controller = ProfileController(repository, _Session());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => EditVitalDataDialog.show(
              context,
              currentUser: _user,
              controller: controller,
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Peso (kg)'),
      '72,5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Altura (cm)'),
      '178',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.user.weight, 72.5);
    expect(repository.user.height, 178);
    expect(find.text('Editar Dados Vitais'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar e abrir novamente mantém o ciclo de vida válido', (
    tester,
  ) async {
    final controller = ProfileController(_Repository(), _Session());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => EditVitalDataDialog.show(
              context,
              currentUser: _user,
              controller: controller,
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}

final _user = UserModel(
  id: 1,
  name: 'Ana',
  email: 'ana@example.com',
  diabetesType: 'Tipo 1',
  diagnosisYear: 2020,
  password: 'hash',
  salt: 'salt',
  weight: 70,
  height: 170,
);

class _Repository implements UserRepositoryInterface {
  UserModel user = _user;
  @override
  Future<int> update(UserModel value) async {
    user = value;
    return 1;
  }

  @override
  Future<UserModel?> find(int id) async => user;
  @override
  Future<int> create(UserModel user) => throw UnimplementedError();
  @override
  Future<bool> emailJaCadastrado(String email) => throw UnimplementedError();
  @override
  Future<UserModel?> findByEmail(String email) => throw UnimplementedError();
}

class _Session implements SessionService {
  @override
  Future<int?> getCurrentUserId() async => 1;
  @override
  Future<void> startSession(int userId) async {}
  @override
  Future<void> endSession() async {}
}
