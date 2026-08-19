/// Validadores de formulário reutilizáveis entre as telas do app.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]"
    r"(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Valida se o e-mail foi preenchido e possui um formato válido
  /// (usuário, domínio e ao menos um ponto após o `@`).
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'O e-mail é obrigatório.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Insira um endereço de e-mail válido.';
    }
    return null;
  }

  static String? validateGlycemia(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 20 || parsed > 600) {
      return 'Informe um valor entre 20 e 600 mg/dL.';
    }
    return null;
  }

  /// Valida a glicemia manual usada no cálculo de insulina.
  /// Esta regra é distinta do registro de glicemia (UC-08).
  static String? validateInsulinCalculationGlycemia(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Informe a glicemia atual.';
    }

    final parsed = int.tryParse(text);
    if (parsed == null) {
      return 'Informe um valor inteiro entre 0 e 999 mg/dL.';
    }
    if (parsed < 0 || parsed > 999) {
      return 'Informe um valor entre 0 e 999 mg/dL.';
    }
    return null;
  }

  static String? validateGlycemiaTarget(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 50 || parsed > 500) {
      return 'Informe um valor entre 50 e 500.';
    }
    return null;
  }
}
