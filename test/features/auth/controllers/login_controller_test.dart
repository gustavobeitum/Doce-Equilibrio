import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:doce_equilibrio/features/auth/controllers/login_controller.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';

class MockUsuarioRepository extends Mock implements IUsuarioRepository {}

void main() {
  late LoginController controller;
  late MockUsuarioRepository mockRepository;

  const email = 'teste@teste.com';
  const senha = 'senha123';

  setUp(() {
    mockRepository = MockUsuarioRepository();
    controller = LoginController(mockRepository);
  });

  group('Caminho de sucesso', () {
    test('Deve retornar true quando a autenticacao for bem-sucedida', () async {
      final usuarioMock = UsuarioModel(
        id: 1,
        nome: 'Gustavo',
        email: email,
        tipoDiabetes: 'Tipo 1',
        anoDiagnostico: 2020,
        senha: senha,
      );

      when(() => mockRepository.autenticar(email, senha))
          .thenAnswer((_) async => usuarioMock);

      final resultado = await controller.entrar(email: email, senha: senha);

      expect(resultado, isTrue);
      verify(() => mockRepository.autenticar(email, senha)).called(1);
    });
  });

  group('Credenciais invalidas', () {
    test('Deve retornar false quando a autenticacao falhar (usuario nulo)', () async {
      when(() => mockRepository.autenticar(email, 'senhaErrada'))
          .thenAnswer((_) async => null);

      final resultado = await controller.entrar(
        email: email,
        senha: 'senhaErrada',
      );

      expect(resultado, isFalse);
      verify(() => mockRepository.autenticar(email, 'senhaErrada')).called(1);
    });

    test('Deve retornar false quando o email nao existir', () async {
      when(() => mockRepository.autenticar('naoexiste@teste.com', senha))
          .thenAnswer((_) async => null);

      final resultado = await controller.entrar(
        email: 'naoexiste@teste.com',
        senha: senha,
      );

      expect(resultado, isFalse);
    });
  });

  group('Excecoes inesperadas (catch)', () {
    test('Deve retornar false quando autenticar lancar excecao', () async {
      when(() => mockRepository.autenticar(email, senha))
          .thenThrow(Exception('Falha de conexão com o banco'));

      final resultado = await controller.entrar(email: email, senha: senha);

      expect(resultado, isFalse);
    });
  });
}