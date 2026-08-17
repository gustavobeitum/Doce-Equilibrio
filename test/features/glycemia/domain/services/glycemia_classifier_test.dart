import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva as cinco faixas personalizadas existentes', () {
    expect(GlycemiaClassifier.classify(49), GlycemiaLevel.lowDanger);
    expect(GlycemiaClassifier.classify(50), GlycemiaLevel.lowAlert);
    expect(GlycemiaClassifier.classify(70), GlycemiaLevel.normal);
    expect(GlycemiaClassifier.classify(141), GlycemiaLevel.highAlert);
    expect(GlycemiaClassifier.classify(181), GlycemiaLevel.highDanger);
  });
}
