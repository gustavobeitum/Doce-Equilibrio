import 'package:doce_equilibrio/features/meals/widgets/meal_item_quantity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirmar quantidade fecha o diálogo sem exceção', (
    tester,
  ) async {
    double? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await MealItemQuantityDialog.show(
                context,
                foodName: 'Arroz',
                initialQuantity: 100,
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '150');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(result, 150);
    expect(tester.takeException(), isNull);
  });
}
