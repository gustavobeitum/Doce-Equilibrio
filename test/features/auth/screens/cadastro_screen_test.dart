import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:doce_equilibrio/core/theme/app_theme.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';
import 'package:doce_equilibrio/features/auth/screens/cadastro_screen.dart';
import 'package:doce_equilibrio/features/home/screens/home_screen.dart';

class MockUsuarioRepository extends Mock implements IUsuarioRepository {}

class FakeUsuarioModel extends Fake implements UsuarioModel {}

void main() {
  late MockUsuarioRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUsuarioModel());
  });

  setUp(() {
    mockRepository = MockUsuarioRepository();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.theme,
      home: CadastroScreen(repository: mockRepository),
    );
  }

  /// Preenche todos os campos com dados válidos, exceto os que forem
  /// sobrescritos explicitamente. Útil para isolar a validação de um único
  /// campo sem disparar os erros de "obrigatório" dos outros.
  Future<void> preencherFormularioValido(
    WidgetTester tester, {
    String nome = 'Gustavo Beitum',
    String email = 'gustavo@email.com',
    String tipoDiabetes = 'Tipo 1',
    String ano = '2020',
    String senha = 'SenhaForte1!',
    String confirmarSenha = 'SenhaForte1!',
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo'), nome);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tipoDiabetes).last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ano do Diagnóstico'),
      ano,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), senha);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar Senha'),
      confirmarSenha,
    );
  }

  Future<void> tocarCadastrar(WidgetTester tester) async {
    final botao = find.widgetWithText(ElevatedButton, 'Cadastrar');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  group('Validacao de campos obrigatorios', () {
    testWidgets('Deve exibir erro em todos os campos ao clicar em Cadastrar com campos vazios',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tocarCadastrar(tester);

      expect(find.text('O nome é obrigatório.'), findsOneWidget);
      expect(find.text('O email é obrigatório.'), findsOneWidget);
      expect(find.text('A seleção do tipo de diabetes é obrigatória.'), findsOneWidget);
      expect(find.text('O ano do diagnóstico é obrigatório.'), findsOneWidget);
      expect(find.text('A senha é obrigatória.'), findsOneWidget);
      expect(find.text('A confirmação de senha é obrigatória.'), findsOneWidget);
      verifyNever(() => mockRepository.criar(any()));
    });

    testWidgets('Deve exibir erro de email invalido quando faltar @ ou ponto',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'emailsemarroba',
      );
      await tocarCadastrar(tester);

      expect(
        find.text('Por favor, insira um endereço de email válido.'),
        findsOneWidget,
      );
    });
  });

  group('Validacao do ano de diagnostico', () {
    testWidgets('Deve exibir erro quando o ano contiver caracteres nao numericos',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester, ano: 'abcd');

      await tocarCadastrar(tester);

      expect(find.text('Por favor, insira apenas números.'), findsOneWidget);
    });

    testWidgets('Deve exibir erro quando o ano for anterior a 1900',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester, ano: '1899');

      await tocarCadastrar(tester);

      expect(find.text('O ano inserido é muito antigo.'), findsOneWidget);
    });

    testWidgets('Deve exibir erro quando o ano estiver no futuro',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      final anoFuturo = (DateTime.now().year + 1).toString();
      await preencherFormularioValido(tester, ano: anoFuturo);

      await tocarCadastrar(tester);

      expect(find.text('O ano não pode estar no futuro.'), findsOneWidget);
    });
  });

  group('Validacao de complexidade de senha', () {
    testWidgets('Deve exibir erro quando a senha tiver menos de 8 caracteres',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'Abc1!',
        confirmarSenha: 'Abc1!',
      );

      await tocarCadastrar(tester);

      expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);
    });

    testWidgets('Deve exibir erro quando a senha nao tiver letra maiuscula',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'senhafraca1!',
        confirmarSenha: 'senhafraca1!',
      );

      await tocarCadastrar(tester);

      expect(
        find.text('A senha deve conter ao menos uma letra maiúscula.'),
        findsOneWidget,
      );
    });

    testWidgets('Deve exibir erro quando a senha nao tiver letra minuscula',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'SENHAFORTE1!',
        confirmarSenha: 'SENHAFORTE1!',
      );

      await tocarCadastrar(tester);

      expect(
        find.text('A senha deve conter ao menos uma letra minúscula.'),
        findsOneWidget,
      );
    });

    testWidgets('Deve exibir erro quando a senha nao tiver numero',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'SenhaForte!',
        confirmarSenha: 'SenhaForte!',
      );

      await tocarCadastrar(tester);

      expect(find.text('A senha deve conter ao menos um número.'), findsOneWidget);
    });

    testWidgets('Deve exibir erro quando a senha nao tiver caractere especial',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'SenhaForte1',
        confirmarSenha: 'SenhaForte1',
      );

      await tocarCadastrar(tester);

      expect(
        find.text('A senha deve conter ao menos um caractere especial (!@#\$%^&*).'),
        findsOneWidget,
      );
    });

    testWidgets('Deve exibir erro de senhas incompativeis', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        senha: 'SenhaForte1!',
        confirmarSenha: 'SenhaErrada1!',
      );

      await tocarCadastrar(tester);

      expect(
        find.text('As senhas informadas não coincidem. Verifique novamente.'),
        findsOneWidget,
      );
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

    testWidgets(
        'Deve alternar obscureText do campo Confirmar Senha ao tocar no icone de olho',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final campoConfirmarSenha =
          find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.ensureVisible(campoConfirmarSenha);
      await tester.pumpAndSettle();
      expect(obscureTextDoCampo(tester, campoConfirmarSenha), isTrue);

      final botaoToggle = find.descendant(
        of: campoConfirmarSenha,
        matching: find.byType(IconButton),
      );
      expect(botaoToggle, findsOneWidget);
      await tester.ensureVisible(botaoToggle);

      await tester.tap(botaoToggle);
      await tester.pump();

      expect(obscureTextDoCampo(tester, campoConfirmarSenha), isFalse);
    });
  });

  group('Integracao com o controller - envio do formulario', () {
    testWidgets('Deve navegar para HomeScreen quando o cadastro for bem-sucedido',
        (WidgetTester tester) async {
      when(() => mockRepository.emailJaCadastrado(any()))
          .thenAnswer((_) async => false);
      when(() => mockRepository.criar(any())).thenAnswer((_) async => 1);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester);

      await tocarCadastrar(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CadastroScreen), findsNothing);
    });

    testWidgets('Deve enviar ao controller exatamente os dados preenchidos no formulario',
        (WidgetTester tester) async {
      when(() => mockRepository.emailJaCadastrado(any()))
          .thenAnswer((_) async => false);
      when(() => mockRepository.criar(any())).thenAnswer((_) async => 1);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(
        tester,
        nome: 'Maria Silva',
        email: 'maria@email.com',
        tipoDiabetes: 'Tipo 2',
        ano: '2015',
        senha: 'OutraSenha2@',
        confirmarSenha: 'OutraSenha2@',
      );

      await tocarCadastrar(tester);

      final usuarioCapturado =
          verify(() => mockRepository.criar(captureAny())).captured.single
              as UsuarioModel;

      expect(usuarioCapturado.nome, 'Maria Silva');
      expect(usuarioCapturado.email, 'maria@email.com');
      expect(usuarioCapturado.tipoDiabetes, 'Tipo 2');
      expect(usuarioCapturado.anoDiagnostico, 2015);
      expect(usuarioCapturado.senha, 'OutraSenha2@');
    });

    testWidgets('Deve exibir SnackBar quando o email ja estiver cadastrado',
        (WidgetTester tester) async {
      when(() => mockRepository.emailJaCadastrado(any()))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester);

      await tocarCadastrar(tester);

      expect(
        find.text(
          'Não foi possível concluir o cadastro. Verifique os dados informados ou tente acessar sua conta.',
        ),
        findsOneWidget,
      );
      verifyNever(() => mockRepository.criar(any()));
    });

    testWidgets('Deve exibir SnackBar de erro de sistema quando criar retornar id invalido',
        (WidgetTester tester) async {
      when(() => mockRepository.emailJaCadastrado(any()))
          .thenAnswer((_) async => false);
      when(() => mockRepository.criar(any())).thenAnswer((_) async => 0);

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester);

      await tocarCadastrar(tester);

      expect(
        find.text('Ocorreu um erro no sistema. Tente novamente mais tarde.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Deve exibir SnackBar de erro de comunicacao quando o repositorio lancar excecao',
        (WidgetTester tester) async {
      when(() => mockRepository.emailJaCadastrado(any()))
          .thenThrow(Exception('Falha de conexão'));

      await tester.pumpWidget(createWidgetUnderTest());
      await preencherFormularioValido(tester);

      await tocarCadastrar(tester);

      expect(
        find.text('Erro de comunicação com a base de dados.'),
        findsOneWidget,
      );
    });
  });
}