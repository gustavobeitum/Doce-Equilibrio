import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Toca o som do alarme em loop enquanto a tela de alarme estiver aberta.
///
/// Usa [AudioContextAndroid] com `usageType: alarm`, que é o mesmo canal
/// de volume que o despertador do sistema usa — assim o som não some se
/// o aparelho estiver no modo silencioso (que só afeta o canal de toque/
/// notificação, não o de alarme).
class AlarmAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _tocando = false;

  // Guarda a preparação/início da reprodução. `parar()` espera essa
  // etapa terminar antes de chamar `.stop()` — chamar stop() enquanto o
  // MediaPlayer nativo ainda está se preparando (ex: usuário tocou
  // "Adiar" muito rápido, antes do áudio realmente começar) é o que
  // causava o erro "stop called in state 0" nos testes.
  Future<void>? _preparando;

  static const _arquivoSom = 'sounds/alarme.mp3';

  Future<void> tocar() async {
    if (_tocando) return;
    _tocando = true;
    _preparando = _iniciarReproducao();
    await _preparando;
  }

  Future<void> _iniciarReproducao() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(_arquivoSom));
    } catch (e) {
      debugPrint('ERRO AO TOCAR SOM DO ALARME: $e');
    }
  }

  Future<void> stop() async {
    if (!_tocando) return;
    _tocando = false;

    // Espera a preparação terminar antes de tentar parar, em vez de
    // arriscar chamar stop() num player que ainda está no meio da
    // inicialização nativa.
    if (_preparando != null) {
      try {
        await _preparando;
      } catch (_) {}
    }

    try {
      await _player.stop();
    } catch (e) {
      // Não é um erro fatal pro app — o player pode já estar parado ou
      // num estado que o Android considera "sem nada pra parar". Só
      // registramos pra referência.
      debugPrint('Aviso ao parar som do alarme (sem impacto): $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
