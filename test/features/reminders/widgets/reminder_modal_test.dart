import 'package:doce_equilibrio/features/reminders/widgets/reminder_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe validação no modal e permite corrigir os dias', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ReminderModal.exibir(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final saveButton = find.text('Salvar Lembrete');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.byType(ReminderModal), findsOneWidget);
    expect(find.text('Selecione ao menos um dia da semana.'), findsOneWidget);
    expect(find.byKey(const Key('modal-feedback-message')), findsOneWidget);

    await tester.ensureVisible(find.text('D').first);
    await tester.tap(find.text('D').first);
    await tester.pump();

    expect(find.byType(ReminderModal), findsOneWidget);
    expect(find.text('Selecione ao menos um dia da semana.'), findsNothing);
  });
}
