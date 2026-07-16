import 'package:flutter_test/flutter_test.dart';
import 'package:doce_equilibrio/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DoceEquilibrioApp());

    expect(find.text('Doce Equilíbrio'), findsWidgets);
  });
}