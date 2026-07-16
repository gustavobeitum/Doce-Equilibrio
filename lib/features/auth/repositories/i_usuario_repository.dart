import 'package:doce_equilibrio/features/auth/models/usuario_model.dart';

abstract class IUsuarioRepository {
  Future<int> criar(UsuarioModel usuario);
  Future<UsuarioModel?> buscar();
  Future<bool> emailJaCadastrado(String email);
  Future<UsuarioModel?> autenticar(String email, String senha);
}