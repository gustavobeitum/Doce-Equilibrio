import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionService sessionService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    sessionService = SecureStorageSessionService();
  });

  test('retorna null quando não existe sessão ativa', () async {
    expect(await sessionService.getCurrentUserId(), isNull);
  });

  test('inicia e recupera a sessão do usuário', () async {
    await sessionService.startSession(42);

    expect(await sessionService.getCurrentUserId(), 42);
  });

  test('encerra a sessão ativa', () async {
    await sessionService.startSession(42);
    await sessionService.endSession();

    expect(await sessionService.getCurrentUserId(), isNull);
  });

  test(
    'trata um identificador armazenado inválido como sessão ausente',
    () async {
      FlutterSecureStorage.setMockInitialValues({'usuario_id': 'inválido'});

      expect(await sessionService.getCurrentUserId(), isNull);
    },
  );
}
