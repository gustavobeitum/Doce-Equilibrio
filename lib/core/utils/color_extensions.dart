import 'package:flutter/material.dart';

/// Extensão para derivar variações de brilho a partir de uma cor já
/// existente no tema (ex: `AppColors.primaryColor.darken()`), em vez de
/// declarar um novo hexadecimal solto no meio do widget.
extension ColorShade on Color {
  /// Escurece a cor em [amount] (0.0 a 1.0). Quanto maior, mais escuro.
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslEscurecido = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return hslEscurecido.toColor();
  }

  /// Clareia a cor em [amount] (0.0 a 1.0). Quanto maior, mais claro.
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslClareado = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslClareado.toColor();
  }
}
