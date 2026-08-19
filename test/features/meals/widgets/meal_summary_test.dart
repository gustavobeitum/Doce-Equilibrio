import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('identifica refeição e limita alimentos com +N', (tester) async {
    final meal = MealModel(
      userId: 1,
      type: MealType.almoco,
      dateTime: DateTime(2026, 8, 18, 12, 43),
      items: List.generate(
        5,
        (index) => MealItemModel(
          foodId: index,
          foodName: 'Alimento muito longo $index',
          carbohydratesPer100g: 10,
          quantityGrams: 10,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 180, child: MealSummary(meal: meal)),
      ),
    );
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('18/08/2026 • 12:43'), findsOneWidget);
    expect(find.textContaining('+2'), findsOneWidget);
    expect(find.text('5 g de carboidratos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
