import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';

class HomeController {
  final IUsuarioRepository repository;

  HomeController(this.repository);

  String getGreeting() {
    final horaAtual = DateTime.now().hour;

    if (horaAtual >= 5 && horaAtual < 12) {
      return 'Bom dia,';
    } else if (horaAtual >= 12 && horaAtual < 18) {
      return 'Boa tarde,';
    } else {
      return 'Boa noite,';
    }
  }

  String nameFormatted(String nomeCompleto) {
    if (nomeCompleto.trim().isEmpty) return '';

    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));

    if (partes.length == 1) {
      return '${partes.first}!';
    }

    return '${partes.first} ${partes.last}!';
  }
}