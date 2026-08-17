enum GlycemiaLevel { lowDanger, lowAlert, normal, highAlert, highDanger }

/// Classificacao pura. Os quatro limites personalizados existentes sao
/// preservados; cores e rotulos pertencem exclusivamente a apresentacao.
class GlycemiaClassifier {
  const GlycemiaClassifier._();

  static GlycemiaLevel classify(
    int valueMgDl, {
    int lowDangerThreshold = 50,
    int normalMinimumThreshold = 70,
    int normalMaximumThreshold = 140,
    int highDangerThreshold = 180,
  }) {
    if (valueMgDl < lowDangerThreshold) return GlycemiaLevel.lowDanger;
    if (valueMgDl < normalMinimumThreshold) return GlycemiaLevel.lowAlert;
    if (valueMgDl <= normalMaximumThreshold) return GlycemiaLevel.normal;
    if (valueMgDl <= highDangerThreshold) return GlycemiaLevel.highAlert;
    return GlycemiaLevel.highDanger;
  }
}
