import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:doce_equilibrio/features/auth/controllers/cadastro_controller.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';

class MockUsuarioRepository extends Mock implements IUsuarioRepository {}

class FakeUsuarioModel extends Fake implements UsuarioModel {}

void main() {
  late CadastroController controller;
  late MockUsuarioRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUsuarioModel());
  });

  setUp(() {
    mockRepository = MockUsuarioRepository();
    controller = CadastroController(mockRepository);
  });

  test('Deve retornar null quando o cadastro for bem-sucedido', () async {
    when(() => mockRepository.emailJaCadastrado(any())).thenAnswer((_) async => false);
    when(() => mockRepository.criar(any())).thenAnswer((_) async => 1);

    final resultado = await controller.registrar(
      nome: 'Gustavo Beitum',
      email: 'gustavo@email.com',
      tipoDiabetes: 'Tipo 1',
      anoDiagnostico: 2020,
      senha: 'Senha123!',
    );

    expect(resultado, isNull);
    verify(() => mockRepository.criar(any())).called(1);
  });

  test('Deve retornar mensagem de erro se o email ja existir', () async {
    when(() => mockRepository.emailJaCadastrado(any())).thenAnswer((_) async => true);

    final resultado = await controller.registrar(
      nome: 'Gustavo Beitum',
      email: 'gustavo@email.com',
      tipoDiabetes: 'Tipo 1',
      anoDiagnostico: 2020,
      senha: 'Senha123!',
    );

    expect(resultado, 'Não foi possível concluir o cadastro. Verifique os dados informados ou tente acessar sua conta.');
    verifyNever(() => mockRepository.criar(any()));
  });

  test('Deve retornar mensagem de erro se a insercao no banco falhar', () async {
    when(() => mockRepository.emailJaCadastrado(any())).thenAnswer((_) async => false);
    when(() => mockRepository.criar(any())).thenAnswer((_) async => 0);

    final resultado = await controller.registrar(
      nome: 'Gustavo Beitum',
      email: 'gustavo@email.com',
      tipoDiabetes: 'Tipo 1',
      anoDiagnostico: 2020,
      senha: 'Senha123!',
    );

    expect(resultado, 'Ocorreu um erro no sistema. Tente novamente mais tarde.');
  });
}