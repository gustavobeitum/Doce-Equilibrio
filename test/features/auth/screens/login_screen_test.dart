import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:doce_equilibrio/core/theme/app_theme.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';
import 'package:doce_equilibrio/features/auth/screens/login_screen.dart';
import 'package:doce_equilibrio/features/home/screens/home_screen.dart';

class MockUsuarioRepository extends Mock implements IUsuarioRepository {}

void main() {
  late MockUsuarioRepository mockRepository;

  setUp(() {
    mockRepository = MockUsuarioRepository();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.theme,
      home: LoginScreen(repository: mockRepository),
    );
  }

  Future<void> preencherLogin(
    WidgetTester tester, {
    String email = 'teste@teste.com',
    String senha = 'senha123',
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), senha);
  }

  Future<void> tocarEntrar(WidgetTester tester) async {
    final botao = find.widgetWithText(ElevatedButton, 'Entrar');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  group('Validacao de campos obrigatorios', () {
    testWidgets('Deve exibir erro ao tentar entrar com campos vazios', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tocarEntrar(tester);

      expect(find.text('O email é obrigatório.'), findsOneWidget);
      expect(find.text('A senha é obrigatória.'), findsOneWidget);
      verifyNever(() => mockRepository.autenticar(any(), any()));
    });

    testWidgets('Deve exibir erro ao tentar entrar com formato de email invalido', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'emailsemarroba',
      );
      await tocarEntrar(tester);

      expect(find.text('Por favor, insira um endereço de email válido.'), findsOneWidget);
    });
  });

  group('Alternancia de visibilidade da senha', () {
    /// TextFormField nao expoe obscureText como propriedade publica - quem
    /// guarda esse valor de fato eh o EditableText interno, entao verificamos
    /// por ali.
    bool obscureTextDoCampo(WidgetTester tester, Finder campo) {
      final editableText = tester.widget<EditableText>(
        find.descendant(of: campo, matching: find.byType(EditableText)),
      );
      return editableText.obscureText;
    }

    testWidgets('Deve alternar obscureText do campo Senha ao tocar no icone de olho',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final campoSenha = find.widgetWithText(TextFormField, 'Senha');
      expect(obscureTextDoCampo(tester, campoSenha), isTrue);

      final botaoToggle = find.descendant(
        of: campoSenha,
        matching: find.byType(IconButton),
      );
      expect(botaoToggle, findsOneWidget);

      await tester.tap(botaoToggle);
      await tester.pump();

      expect(obscureTextDoCampo(tester, campoSenha), isFalse);
    });
  });

  group('Integracao com o controller - envio do formulario', () {
    testWidgets('Deve navegar para HomeScreen quando a autenticacao for bem-sucedida',
        (WidgetTester tester) async {
      final usuarioMock = UsuarioModel(
        id: 1,
        nome: 'Gustavo',
        email: 'teste@teste.com',
        tipoDiabetes: 'Tipo 1',
        anoDiagnostico: 2020,
        senha: 'senha123',
      );

      when(() => mockRepository.autenticar('teste@teste.com', 'senha123'))
          .thenAnswer((_) async => usuarioMock);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherLogin(tester);

      await tocarEntrar(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Deve enviar ao controller exatamente o email e senha digitados',
        (WidgetTester tester) async {
      when(() => mockRepository.autenticar(any(), any()))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherLogin(tester, email: 'outro@teste.com', senha: 'outraSenha');

      await tocarEntrar(tester);

      verify(() => mockRepository.autenticar('outro@teste.com', 'outraSenha'))
          .called(1);
    });

    testWidgets('Deve exibir SnackBar de erro ao receber credenciais invalidas', (WidgetTester tester) async {
      when(() => mockRepository.autenticar(any(), any())).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherLogin(tester, senha: 'senhaerrada');

      await tocarEntrar(tester);

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    });

    testWidgets('Deve exibir SnackBar de erro quando o repositorio lancar excecao',
        (WidgetTester tester) async {
      when(() => mockRepository.autenticar(any(), any()))
          .thenThrow(Exception('Falha de conexão'));

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherLogin(tester);

      await tocarEntrar(tester);

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    });
  });
}