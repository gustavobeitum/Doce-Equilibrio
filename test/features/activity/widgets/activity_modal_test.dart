import 'package:doce_equilibrio/features/activity/widgets/activity_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exige intensidade ao cadastrar atividade', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ActivityModal())),
    );

    await tester.enterText(find.byType(TextFormField).first, '30');
    final save = find.text('Salvar Registro');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text('Selecione a intensidade.'), findsOneWidget);
  });
}
