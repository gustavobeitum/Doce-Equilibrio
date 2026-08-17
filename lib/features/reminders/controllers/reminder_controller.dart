import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:flutter/foundation.dart';

class ReminderController {
  final ReminderRepositoryInterface repository;
  final NotificationService _notificationService;
  final SessionService _sessionService;

  ReminderController(
    this.repository,
    this._notificationService,
    this._sessionService,
  );

  Future<List<ReminderModel>> list() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) return [];
    return repository.listByUser(userId);
  }

  /// Cria um novo lembrete (quando [id] é `null`) ou atualiza um existente,
  /// e já (re)agenda as notificações correspondentes.
  ///
  /// Quando [repetir] é `true`, [diasSemana] é obrigatório (ao menos um
  /// dia). Quando é `false`, [data] é obrigatória e precisa estar no
  /// futuro (é um disparo único, como um alarme "uma vez só").
  Future<String?> save({
    int? id,
    required ReminderType type,
    required String title,
    required int time,
    required int minute,
    required bool repeat,
    List<int> weekdays = const [],
    DateTime? date,
    bool active = true,
  }) async {
    if (title.trim().isEmpty) {
      return 'Informe um título para o lembrete.';
    }

    if (repeat) {
      if (weekdays.isEmpty) {
        return 'Selecione ao menos um dia da semana.';
      }
    } else {
      if (date == null) {
        return 'Selecione a data do lembrete.';
      }
      final scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time,
        minute,
      );
      if (scheduledFor.isBefore(DateTime.now())) {
        return 'Escolha uma data e horário no futuro.';
      }
    }

    try {
      final userId = await _sessionService.getCurrentUserId();
      if (userId == null) {
        return 'Sessão expirada. Faça login novamente.';
      }

      final diasOrdenados = repeat
          ? (List<int>.from(weekdays)..sort())
          : const <int>[];

      final baseReminder = ReminderModel(
        id: id,
        userId: userId,
        type: type,
        title: title.trim(),
        time: time,
        minute: minute,
        repeat: repeat,
        weekdays: diasOrdenados,
        date: repeat ? null : date,
        active: active,
      );

      final savedId = id == null
          ? await repository.create(baseReminder)
          : await repository.update(baseReminder).then((_) => id);

      await _notificationService.scheduleReminder(
        baseReminder.copyWith(id: savedId),
      );

      return null;
    } catch (e) {
      debugPrint('ERRO AO SALVAR LEMBRETE: $e');
      return 'Não foi possível salvar o lembrete. Tente novamente.';
    }
  }

  /// Ativa/desativa rapidamente um lembrete existente (usado no switch da
  /// listagem), agendando ou cancelando a notificação conforme o caso.
  Future<bool> alternarAtivo(ReminderModel reminder) async {
    try {
      final updated = reminder.copyWith(active: !reminder.active);
      await repository.update(updated);

      if (updated.active) {
        await _notificationService.scheduleReminder(updated);
      } else {
        await _notificationService.cancelReminder(updated);
      }
      return true;
    } catch (e) {
      debugPrint('ERRO AO ALTERNAR LEMBRETE: $e');
      return false;
    }
  }

  Future<bool> delete(ReminderModel reminder) async {
    try {
      if (reminder.id == null) return false;
      await _notificationService.cancelReminder(reminder);
      final affectedRows = await repository.delete(reminder.id!);
      return affectedRows > 0;
    } catch (e) {
      debugPrint('ERRO AO EXCLUIR LEMBRETE: $e');
      return false;
    }
  }
}
