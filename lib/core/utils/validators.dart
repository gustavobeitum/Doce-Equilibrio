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
}
