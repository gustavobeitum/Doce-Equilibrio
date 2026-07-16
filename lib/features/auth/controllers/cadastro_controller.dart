import 'package:flutter/material.dart';
import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';

class CadastroController {
  final IUsuarioRepository _usuarioRepository;

  CadastroController(this._usuarioRepository);

  Future<String?> registrar({
    required String nome,
    required String email,
    required String tipoDiabetes,
    required int anoDiagnostico,
    required String senha,
  }) async {
    try {
      final emailExiste = await _usuarioRepository.emailJaCadastrado(email);
      if (emailExiste) {
        return 'Não foi possível concluir o cadastro. Verifique os dados informados ou tente acessar sua conta.';
      }

      final usuario = UsuarioModel(
        nome: nome,
        email: email,
        tipoDiabetes: tipoDiabetes,
        anoDiagnostico: anoDiagnostico,
        senha: senha,
      );

      final id = await _usuarioRepository.criar(usuario);

      if (id > 0) return null;

      return 'Ocorreu um erro no sistema. Tente novamente mais tarde.';
    } catch (e) {
      debugPrint('ERRO AO SALVAR USUÁRIO: $e');
      return 'Erro de comunicação com a base de dados.';
    }
  }
}
