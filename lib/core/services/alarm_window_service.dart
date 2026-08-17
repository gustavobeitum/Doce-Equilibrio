import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ativa/desativa a exibição da Activity por cima da tela bloqueada e o
/// "acender a tela" automaticamente — o mesmo comportamento de um
/// despertador nativo.
///
/// Isso não tem equivalente puro em Flutter: precisa de um MethodChannel
/// chamando `Window.addFlags`/`clearFlags` do lado nativo Android (ver
/// `MainActivity.kt`). Só ativamos isso enquanto a tela de alarme está
/// aberta — o resto do app nunca deve aparecer sobre a tela bloqueada.
class AlarmWindowService {
  static const _canal = MethodChannel('doce_equilibrio/alarm_window');

  Future<void> ativarSobreTelaBloqueada() async {
    try {
      await _canal.invokeMethod('ativarSobreTelaBloqueada');
    } catch (e) {
      debugPrint('ERRO AO ATIVAR TELA SOBRE BLOQUEIO: $e');
    }
  }

  Future<void> desativarSobreTelaBloqueada() async {
    try {
      await _canal.invokeMethod('desativarSobreTelaBloqueada');
    } catch (e) {
      debugPrint('ERRO AO DESATIVAR TELA SOBRE BLOQUEIO: $e');
    }
  }
}
