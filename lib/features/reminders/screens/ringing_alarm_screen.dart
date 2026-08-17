import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/alarm_audio_service.dart';
import 'package:doce_equilibrio/core/services/alarm_window_service.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Tela cheia de alarme tocando — aberta automaticamente quando um
/// lembrete dispara (via notificação de tela cheia) ou ao tocar na
/// notificação. Toca o som em loop até o usuário Dispensar ou Adiar.
class RingingAlarmScreen extends StatefulWidget {
  final int reminderId;
  final String title;
  final ReminderType type;

  const RingingAlarmScreen({
    super.key,
    required this.reminderId,
    required this.title,
    required this.type,
  });

  @override
  State<RingingAlarmScreen> createState() => _AlarmeTocandoScreenState();
}

class _AlarmeTocandoScreenState extends State<RingingAlarmScreen> {
  final AlarmAudioService _audioService = AlarmAudioService();
  final AlarmWindowService _windowService = AlarmWindowService();
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _windowService.ativarSobreTelaBloqueada();
    _audioService.tocar();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _windowService.desativarSobreTelaBloqueada();
    super.dispose();
  }

  IconData get _icone {
    switch (widget.type) {
      case ReminderType.insulinaBasal:
        return PhosphorIcons.drop;
      case ReminderType.medication:
        return PhosphorIcons.pill;
      case ReminderType.outro:
        return PhosphorIcons.bellSimple;
    }
  }

  Future<void> _dispensar() async {
    if (_processando) return;
    setState(() => _processando = true);

    await _audioService.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _adiar(int minutos) async {
    if (_processando) return;
    setState(() => _processando = true);

    await _audioService.stop();

    final notificationService = getIt<NotificationService>();
    await notificationService.adiarLembrete(
      reminderId: widget.reminderId,
      title: widget.title,
      type: widget.type,
      minutos: minutos,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Não deixa fechar a tela de alarme sem escolher uma ação — igual
      // qualquer despertador de verdade.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icone, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.type.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 3),

                // Adiar
                Text(
                  'Adiar por',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _processando ? null : () => _adiar(5),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('5 min'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _processando ? null : () => _adiar(10),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('10 min'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dispensar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _processando ? null : _dispensar,
                    icon: const Icon(PhosphorIcons.check),
                    label: const Text('Dispensar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
