/// Exceções do fluxo de autenticação. Permitem que a camada de Controller
/// diferencie uma falha de credenciais (usuário digitou algo errado) de uma
/// falha de infraestrutura (conexão ou banco de dados indisponível), para
/// que a mensagem exibida ao usuário nunca mascare o problema real.
class InvalidCredentialsException implements Exception {
  final String message;

  const InvalidCredentialsException([
    this.message = 'E-mail ou senha incorretos. Verifique seus dados.',
  ]);

  @override
  String toString() => message;
}

class DatabaseConnectionException implements Exception {
  final String message;

  const DatabaseConnectionException([
    this.message =
        'Não foi possível acessar o banco de dados. Verifique o app e tente novamente.',
  ]);

  @override
  String toString() => message;
}
