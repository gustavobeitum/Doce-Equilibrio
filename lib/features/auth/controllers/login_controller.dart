import 'package:doce_equilibrio/core/utils/criptografia_util.dart';
import 'package:doce_equilibrio/features/auth/repositories/i_usuario_repository.dart';

class LoginController {
  final IUsuarioRepository _usuarioRepository;

  LoginController(this._usuarioRepository);

  Future<bool> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      final senhaSegura = CriptografiaUtil.gerarHashSha256(senha);
      final usuario = await _usuarioRepository.autenticar(email, senhaSegura);
      return usuario != null;
    } catch (e) {
      return false;
    }
  }
}