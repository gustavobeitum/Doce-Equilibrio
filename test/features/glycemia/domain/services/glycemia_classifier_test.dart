import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifica nas três categorias oficiais e preserva os limites', () {
    expect(GlycemiaClassifier.classify(69), GlycemiaLevel.hypoglycemia);
    expect(GlycemiaClassifier.classify(70), GlycemiaLevel.normal);
    expect(GlycemiaClassifier.classify(180), GlycemiaLevel.normal);
    expect(GlycemiaClassifier.classify(181), GlycemiaLevel.hyperglycemia);
  });

  test('aceita limites inferior e superior personalizados', () {
    expect(
      GlycemiaClassifier.classify(
        79,
        lowAlertThreshold: 80,
        highDangerThreshold: 200,
      ),
      GlycemiaLevel.hypoglycemia,
    );
    expect(
      GlycemiaClassifier.classify(
        200,
        lowAlertThreshold: 80,
        highDangerThreshold: 200,
      ),
      GlycemiaLevel.normal,
    );
  });
}
