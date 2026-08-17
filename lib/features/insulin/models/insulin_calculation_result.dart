/// Resultado do cálculo de dose de insulina (UC-16), já separado em
/// correção (glicemia atual acima da meta) e cobertura de carboidratos.
class InsulinCalculationResult {
  final double correctionDose;
  final double carbohydrateDose;
  final double totalDose;

  const InsulinCalculationResult({
    required this.correctionDose,
    required this.carbohydrateDose,
    required this.totalDose,
  });
}
