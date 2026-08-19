import 'package:doce_equilibrio/features/insulin/models/insulin_calculation_result.dart';
import 'package:doce_equilibrio/features/insulin/domain/services/insulin_dose_calculator.dart';

/// Calcula a dose sugerida de insulina (UC-16), a partir dos Parâmetros de
/// Insulina configurados pelo usuário (RF-002 / Sprint 4):
///
/// - Dose de Correção = (Glicemia Atual − Meta Glicêmica) / Fator de
///   Correção — só entra em cálculo se a glicemia atual estiver acima da
///   meta; nunca é negativa.
/// - Dose de Carboidratos = Carboidratos da Refeição / Fator de
///   Sensibilidade (razão insulina/carboidrato).
///
/// Este é um cálculo estimado (ver aviso na tela) — não substitui
/// orientação médica.
class InsulinCalculationController {
  InsulinCalculationController._();

  static InsulinCalculationResult calculate({
    int? currentGlycemia,
    double? carbohydratesGrams,
    required int glycemiaTarget,
    required double correctionFactor,
    required double sensitivityFactor,
  }) {
    final calculation = InsulinDoseCalculator.calculate(
      currentGlycemia: currentGlycemia,
      carbohydratesGrams: carbohydratesGrams,
      glycemiaTarget: glycemiaTarget,
      correctionFactor: correctionFactor,
      insulinCarbohydrateRatio: sensitivityFactor,
    );

    return InsulinCalculationResult(
      correctionDose: calculation.correctionDose,
      carbohydrateDose: calculation.carbohydrateDose,
      totalDose: calculation.totalDose,
    );
  }
}
