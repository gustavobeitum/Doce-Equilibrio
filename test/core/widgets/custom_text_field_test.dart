import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doce_equilibrio/core/widgets/custom_text_field.dart';

void main() {
  testWidgets('Deve renderizar o labelText corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Email de Teste',
          ),
        ),
      ),
    );

    expect(find.text('Email de Teste'), findsOneWidget);
  });

  testWidgets('Deve renderizar o hintText quando o campo estiver focado e vazio',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Email',
            hintText: 'seu@email.com',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();

    expect(find.text('seu@email.com'), findsOneWidget);
  });

  testWidgets('Deve exibir mensagem de erro quando a validacao falhar', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomTextField(
              labelText: 'Senha',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    
    await tester.pump();

    expect(find.text('Campo obrigatório'), findsOneWidget);
  });

  testWidgets('Deve remover a mensagem de erro quando o texto se tornar valido',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomTextField(
              labelText: 'Senha',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);

    await tester.enterText(find.byType(CustomTextField), 'qualquerValor');
    await tester.pump();

    expect(find.text('Campo obrigatório'), findsNothing);
  });

  testWidgets('Deve permitir a digitacao de texto no campo', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Nome',
            controller: controller,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(CustomTextField), 'Teste de Digitação');

    expect(controller.text, 'Teste de Digitação');
  });

  testWidgets('Deve chamar onChanged a cada alteracao de texto', (WidgetTester tester) async {
    String? valorRecebido;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Nome',
            onChanged: (value) => valorRecebido = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(CustomTextField), 'abc');

    expect(valorRecebido, 'abc');
  });

  testWidgets('Deve ocultar o texto quando obscureText for verdadeiro', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Senha',
            obscureText: true,
          ),
        ),
      ),
    );

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.obscureText, isTrue);
  });

  testWidgets('Deve renderizar o suffixIcon quando informado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Senha',
            suffixIcon: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}