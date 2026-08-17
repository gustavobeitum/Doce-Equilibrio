import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Utilitário responsável pela geração de salt e pelo hash/validação segura
/// de senhas de usuário.
///
/// A senha nunca é armazenada nem comparada em texto puro: cada usuário
/// recebe um salt aleatório único (gerado em [gerarSalt]), persistido junto
/// ao seu registro no banco. O salt é concatenado à senha antes do hash
/// SHA-256, o que garante que usuários com a mesma senha tenham hashes
/// diferentes no banco e neutraliza ataques de rainbow table.
class EncryptionUtils {
  EncryptionUtils._();

  static const int _saltLengthBytes = 16;

  /// Gera um salt aleatório e criptograficamente seguro, codificado em
  /// Base64Url. Deve ser gerado uma única vez por usuário, no cadastro, e
  /// armazenado junto ao registro dele.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _saltLengthBytes,
      (_) => random.nextInt(256),
    );
    return base64Url.encode(bytes);
  }

  /// Gera o hash SHA-256 da senha concatenada ao salt informado.
  static String generateSaltedHash(String plainPassword, String salt) {
    final bytes = utf8.encode('$plainPassword$salt');
    return sha256.convert(bytes).toString();
  }

  /// Valida se [senhaDigitada] corresponde ao [hashArmazenado], recalculando
  /// o hash a partir do [salt] do usuário. A comparação final é feita em
  /// tempo constante para reduzir a exposição a ataques de timing.
  static bool validatePassword({
    required String enteredPassword,
    required String storedHash,
    required String salt,
  }) {
    final calculatedHash = generateSaltedHash(enteredPassword, salt);
    return _constantTimeEquals(calculatedHash, storedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
