import 'package:flutter/material.dart';
import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';

/// Resultado da classificação de uma leitura de glicemia: rótulo exibido
/// na UI e cor associada (mesma paleta já usada em `GlycemicGoalsCard`).
class GlycemiaClassificationInfo {
  final String label;
  final Color color;

  const GlycemiaClassificationInfo(this.label, this.color);
}

/// Classifica automaticamente uma leitura de glicemia (RF-010 / UC-09).
///
/// As faixas são as Metas Glicêmicas configuradas pelo próprio usuário
/// (RF-002), com os antigos valores fixos como padrão para quem ainda não
/// personalizou nada.
class GlycemiaClassification {
  GlycemiaClassification._();

  static const Color corHipoglicemia = Color(0xFFE53935);
  static const Color corHiperglicemia = Color(0xFFFFB300);
  static const Color corNormal = Color(0xFF4CAF50);

  static GlycemiaClassificationInfo classify(
    int valueMgDl, {
    int lowAlertThreshold = 70,
    int highDangerThreshold = 180,
  }) {
    final level = GlycemiaClassifier.classify(
      valueMgDl,
      lowAlertThreshold: lowAlertThreshold,
      highDangerThreshold: highDangerThreshold,
    );
    return switch (level) {
      GlycemiaLevel.hypoglycemia => const GlycemiaClassificationInfo(
        'Hipoglicemia',
        corHipoglicemia,
      ),
      GlycemiaLevel.hyperglycemia => const GlycemiaClassificationInfo(
        'Hiperglicemia',
        corHiperglicemia,
      ),
      GlycemiaLevel.normal => const GlycemiaClassificationInfo(
        'Normal',
        corNormal,
      ),
    };
  }
}
