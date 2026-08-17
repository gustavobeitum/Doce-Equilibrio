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

  static const Color corPerigo = Color(0xFFE53935);
  static const Color corAlertaBaixo = Color(0xFFFFB300);
  static const Color corAlertaAlto = Color(0xFFFB8C00);
  static const Color corNormal = Color(0xFF4CAF50);

  static GlycemiaClassificationInfo classify(
    int valueMgDl, {
    int lowDangerThreshold = 50,
    int normalMinimumThreshold = 70,
    int normalMaximumThreshold = 140,
    int highDangerThreshold = 180,
  }) {
    final level = GlycemiaClassifier.classify(
      valueMgDl,
      lowDangerThreshold: lowDangerThreshold,
      normalMinimumThreshold: normalMinimumThreshold,
      normalMaximumThreshold: normalMaximumThreshold,
      highDangerThreshold: highDangerThreshold,
    );
    return switch (level) {
      GlycemiaLevel.lowDanger || GlycemiaLevel.highDanger =>
        const GlycemiaClassificationInfo('Perigo', corPerigo),
      GlycemiaLevel.lowAlert => const GlycemiaClassificationInfo(
        'Alerta Baixo',
        corAlertaBaixo,
      ),
      GlycemiaLevel.highAlert => const GlycemiaClassificationInfo(
        'Alerta Alto',
        corAlertaAlto,
      ),
      GlycemiaLevel.normal => const GlycemiaClassificationInfo(
        'Normal',
        corNormal,
      ),
    };
  }
}
