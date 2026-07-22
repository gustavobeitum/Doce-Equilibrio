import 'dart:convert';
import 'package:crypto/crypto.dart';

class CriptografiaUtil {
  static String gerarHashSha256(String senhaLimpa) {
    final bytes = utf8.encode(senhaLimpa);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}