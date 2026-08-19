enum GlycemiaLevel { hypoglycemia, normal, hyperglycemia }

/// Classificacao pura. Os quatro limites personalizados existentes sao
/// preservados; cores e rotulos pertencem exclusivamente a apresentacao.
class GlycemiaClassifier {
  const GlycemiaClassifier._();

  static GlycemiaLevel classify(
    int valueMgDl, {
    int lowAlertThreshold = 70,
    int highDangerThreshold = 180,
  }) {
    if (valueMgDl < lowAlertThreshold) return GlycemiaLevel.hypoglycemia;
    if (valueMgDl <= highDangerThreshold) return GlycemiaLevel.normal;
    return GlycemiaLevel.hyperglycemia;
  }
}
