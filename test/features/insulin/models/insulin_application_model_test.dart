import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte aplicação para mapa e restaura todos os valores', () {
    final original = InsulinApplicationModel(
      id: 3,
      userId: 1,
      glycemia: 181,
      carbohydrates: 60,
      carbohydrateDose: 4,
      correctionDose: 4.05,
      recommendedDose: 8,
      appliedDose: 7.5,
      dateTime: DateTime(2026, 8, 18, 12, 30),
      observation: 'Após almoço',
      mealId: 9,
    );

    final restored = InsulinApplicationModel.fromMap(original.toMap());

    expect(restored.id, 3);
    expect(restored.recommendedDose, 8);
    expect(restored.appliedDose, 7.5);
    expect(restored.correctionDose, 4.05);
    expect(restored.mealId, 9);
    expect(restored.observation, 'Após almoço');
  });
}
