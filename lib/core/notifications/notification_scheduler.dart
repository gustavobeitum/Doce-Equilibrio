import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const notificationChannelId = 'lembretes_channel_v2';
const notificationChannelName = 'Lembretes';
const notificationChannelDescription =
    'Lembretes de insulina, medicamentos e outros horários configurados';

NotificationDetails alarmNotificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alarme'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction('dispensar', 'Dispensar'),
        AndroidNotificationAction('adiar', 'Adiar 10 min'),
      ],
    ),
  );
}

abstract interface class NotificationScheduler {
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback onResponse,
    required DidReceiveBackgroundNotificationResponseCallback
    onBackgroundResponse,
  });
  Future<NotificationResponse?> getLaunchResponse();
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int weekday,
    required int hour,
    required int minute,
  });
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime dateTime,
  });
  Future<void> scheduleAfter({
    required int id,
    required String title,
    required String body,
    required String payload,
    required Duration delay,
  });
  Future<void> cancel(int id);
}

class LocalNotificationScheduler implements NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _canScheduleExact = false;

  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback onResponse,
    required DidReceiveBackgroundNotificationResponseCallback
    onBackgroundResponse,
  }) async {
    if (_initialized) return;
    await _configureTimezone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _configureTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      debugPrint('Não foi possível detectar o fuso horário: $error');
    }
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsAllowed = await android
        ?.requestNotificationsPermission();
    debugPrint('Permissão de notificações concedida: $notificationsAllowed');

    await android?.requestExactAlarmsPermission();
    _canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
    debugPrint('Pode agendar alarmes exatos: $_canScheduleExact');

    final fullScreenAllowed = await android
        ?.requestFullScreenIntentPermission();
    debugPrint(
      'Permissão de notificação em tela cheia concedida: $fullScreenAllowed',
    );
  }

  @override
  Future<NotificationResponse?> getLaunchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (!(details?.didNotificationLaunchApp ?? false)) return null;
    return details?.notificationResponse;
  }

  AndroidScheduleMode get _scheduleMode => _canScheduleExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledFor = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduledFor.weekday != weekday || scheduledFor.isBefore(now)) {
      scheduledFor = scheduledFor.add(const Duration(days: 1));
    }
    return _schedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledFor: scheduledFor,
      repeat: true,
    );
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime dateTime,
  }) {
    return _schedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledFor: tz.TZDateTime(
        tz.local,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
      ),
      repeat: false,
    );
  }

  @override
  Future<void> scheduleAfter({
    required int id,
    required String title,
    required String body,
    required String payload,
    required Duration delay,
  }) {
    return _schedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledFor: tz.TZDateTime.now(tz.local).add(delay),
      repeat: false,
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required tz.TZDateTime scheduledFor,
    required bool repeat,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledFor,
      alarmNotificationDetails(),
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);
}
