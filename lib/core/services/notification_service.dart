import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/core/navigation/app_navigator.dart';
import 'package:doce_equilibrio/core/notifications/notification_ids.dart';
import 'package:doce_equilibrio/core/notifications/notification_payload.dart';
import 'package:doce_equilibrio/core/notifications/notification_scheduler.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:doce_equilibrio/features/reminders/screens/ringing_alarm_screen.dart';
import 'package:doce_equilibrio/features/reminders/services/reminder_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService implements ReminderNotificationService {
  final NotificationScheduler _scheduler;
  final ReminderRepositoryInterface _reminderRepository;
  bool _initialized = false;
  int? _openReminderId;

  NotificationService(this._scheduler, this._reminderRepository);

  Future<void> init() async {
    if (_initialized) return;
    await _scheduler.initialize(
      onResponse: _onResponse,
      onBackgroundResponse: onBackgroundNotificationResponse,
    );
    _initialized = true;
  }

  Future<void> handleNotificationLaunch() async {
    final response = await _scheduler.getLaunchResponse();
    if (response != null) await _handleResponse(response);
  }

  void _onResponse(NotificationResponse response) {
    _handleResponse(response).catchError((Object error) {
      debugPrint('Erro ao tratar resposta da notificação: $error');
    });
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    if (response.actionId == 'dispensar') {
      final payload = NotificationPayload.tryParse(response.payload);
      if (response.id != null) await _scheduler.cancel(response.id!);
      if (payload != null) {
        await _reminderRepository.completeSingle(payload.reminderId);
      }
      return;
    }

    if (response.actionId == 'adiar') {
      await _snoozeFromPayload(response.payload, 10, response.id);
      return;
    }

    if (response.id != null) await _scheduler.cancel(response.id!);
    _openAlarm(response.payload, notificationId: response.id);
  }

  void _openAlarm(String? rawPayload, {int? notificationId}) {
    final payload = NotificationPayload.tryParse(rawPayload);
    if (payload == null) {
      if (rawPayload != null) debugPrint('Payload de notificação inválido.');
      return;
    }
    if (_openReminderId == payload.reminderId) return;
    _openReminderId = payload.reminderId;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _openReminderId = null;
      return;
    }
    navigator
        .push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => RingingAlarmScreen(
              reminderId: payload.reminderId,
              title: payload.title,
              type: ReminderType.fromValor(payload.type),
              notificationId: notificationId,
            ),
          ),
        )
        .whenComplete(() => _openReminderId = null);
  }

  Future<void> _snoozeFromPayload(
    String? rawPayload,
    int minutes,
    int? notificationId,
  ) async {
    final payload = NotificationPayload.tryParse(rawPayload);
    if (payload == null) {
      debugPrint('Não foi possível adiar: payload de notificação inválido.');
      return;
    }
    await snoozeReminder(
      reminderId: payload.reminderId,
      title: payload.title,
      type: ReminderType.fromValor(payload.type),
      minutes: minutes,
      notificationId: notificationId,
    );
  }

  String _messageFor(ReminderType type) {
    return switch (type) {
      ReminderType.insulinaBasal => 'Hora de aplicar sua insulina basal.',
      ReminderType.medication => 'Hora de tomar seu medicamento.',
      ReminderType.outro => 'Você tem um lembrete configurado para agora.',
    };
  }

  NotificationPayload _payload({
    required int reminderId,
    required String title,
    required ReminderType type,
  }) {
    return NotificationPayload(
      reminderId: reminderId,
      title: title,
      type: type.name,
    );
  }

  @override
  Future<void> scheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder);
    if (!reminder.active || reminder.id == null) return;

    final reminderId = reminder.id!;
    final body = _messageFor(reminder.type);
    final payload = _payload(
      reminderId: reminderId,
      title: reminder.title,
      type: reminder.type,
    ).encode();

    if (reminder.repeat) {
      for (final weekday in reminder.weekdays) {
        await _scheduler.scheduleWeekly(
          id: NotificationIds.weekly(reminderId, weekday),
          title: reminder.title,
          body: body,
          payload: payload,
          weekday: weekday,
          hour: reminder.time,
          minute: reminder.minute,
        );
      }
    } else if (reminder.date != null) {
      await _scheduler.scheduleOnce(
        id: NotificationIds.single(reminderId),
        title: reminder.title,
        body: body,
        payload: payload,
        dateTime: DateTime(
          reminder.date!.year,
          reminder.date!.month,
          reminder.date!.day,
          reminder.time,
          reminder.minute,
        ),
      );
    }
  }

  @override
  Future<void> snoozeReminder({
    required int reminderId,
    required String title,
    required ReminderType type,
    required int minutes,
    int? notificationId,
  }) async {
    if (notificationId != null) await _scheduler.cancel(notificationId);
    await _scheduler.cancel(NotificationIds.snooze(reminderId));
    await _scheduler.scheduleAfter(
      id: NotificationIds.snooze(reminderId),
      title: title,
      body: _messageFor(type),
      payload: _payload(
        reminderId: reminderId,
        title: title,
        type: type,
      ).encode(),
      delay: Duration(minutes: minutes),
    );
  }

  @override
  Future<void> dismissReminder({
    required int reminderId,
    int? notificationId,
  }) async {
    if (notificationId != null) await _scheduler.cancel(notificationId);
    await _reminderRepository.completeSingle(reminderId);
  }

  @override
  Future<void> cancelReminder(ReminderModel reminder) async {
    if (reminder.id == null) return;
    for (final id in NotificationIds.allForReminder(reminder.id!)) {
      await _scheduler.cancel(id);
    }
  }
}

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  final plugin = FlutterLocalNotificationsPlugin();
  if (response.actionId == 'dispensar') {
    if (response.id != null) await plugin.cancel(response.id!);
    final payload = NotificationPayload.tryParse(response.payload);
    if (payload != null) {
      try {
        await ReminderRepository(
          DatabaseConnection(),
        ).completeSingle(payload.reminderId);
      } catch (error) {
        debugPrint('Erro ao concluir lembrete em segundo plano: $error');
      }
    }
    return;
  }
  if (response.actionId != 'adiar') return;

  final payload = NotificationPayload.tryParse(response.payload);
  if (payload == null) {
    debugPrint('Erro ao adiar em segundo plano: payload inválido.');
    return;
  }

  try {
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      debugPrint('Falha ao detectar timezone no segundo plano: $error');
    }

    final type = ReminderType.fromValor(payload.type);
    final body = switch (type) {
      ReminderType.insulinaBasal => 'Hora de aplicar sua insulina basal.',
      ReminderType.medication => 'Hora de tomar seu medicamento.',
      ReminderType.outro => 'Você tem um lembrete configurado para agora.',
    };

    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact =
        await android?.canScheduleExactNotifications() ?? false;

    await plugin.zonedSchedule(
      NotificationIds.snooze(payload.reminderId),
      payload.title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      alarmNotificationDetails(),
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload.encode(),
    );

    if (response.id != null) await plugin.cancel(response.id!);
  } catch (error) {
    debugPrint('Erro ao adiar em segundo plano: $error');
  }
}
