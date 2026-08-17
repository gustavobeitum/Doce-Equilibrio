import 'dart:convert';

import 'package:doce_equilibrio/core/navigation/app_navigator.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:doce_equilibrio/features/reminders/screens/ringing_alarm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Id, nome e descrição do canal de notificação — em nível top-level
/// porque também são usados pelo callback de segundo plano
/// [_aoReceberRespostaSegundoPlano], que roda num isolate isolado e não
/// tem acesso aos membros da classe [NotificationService].
const _canalId = 'lembretes_channel_v2';
const _canalNome = 'Lembretes';
const _canalDescricao =
    'Lembretes de insulina, medicamentos e outros horários configurados';

String _mensagemParaLembrete(ReminderType type) {
  switch (type) {
    case ReminderType.insulinaBasal:
      return 'Hora de aplicar sua insulina basal.';
    case ReminderType.medication:
      return 'Hora de tomar seu medicamento.';
    case ReminderType.outro:
      return 'Você tem um lembrete configurado para agora.';
  }
}

int _generateNotificationId(int reminderId, int index) {
  return reminderId * 10 + index;
}

/// Agenda e cancela os alarmes dos lembretes (UC-17 / RF-003).
///
/// Diferente de uma notificação comum, aqui usamos `fullScreenIntent`: o
/// Android abre a [AlarmeTocandoScreen] automaticamente por cima da tela
/// (inclusive bloqueada), do jeito que um despertador nativo funciona. Se
/// o aparelho estiver em uso, o sistema mostra como notificação normal
/// com os botões "Dispensar"/"Adiar" — por isso os dois caminhos
/// (tela cheia e ação da notificação) levam pro mesmo lugar.
///
/// Cada [LembreteModel] pode repetir em vários dias da semana; como o
/// `flutter_local_notifications` agenda uma notificação por combinação de
/// dia+hora, geramos um id de notificação por (lembreteId, diaDaSemana) —
/// índice 0 é reservado pro disparo único e índice 9 pra soneca, então
/// eles não colidem entre si nem são cancelados junto dos outros dias.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  bool _canScheduleExact = false;

  Future<void> init() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Não foi possível detectar o fuso horário: $e');
    }

    const configuracaoAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const configuracaoInicializacao = InitializationSettings(
      android: configuracaoAndroid,
    );
    await _plugin.initialize(
      configuracaoInicializacao,
      onDidReceiveNotificationResponse: _aoReceberResposta,
      onDidReceiveBackgroundNotificationResponse:
          _aoReceberRespostaSegundoPlano,
    );
    await _solicitarPermissoes();

    _inicializado = true;
  }

  Future<void> _solicitarPermissoes() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final notificacoesPermitidas = await androidPlugin
        ?.requestNotificationsPermission();
    debugPrint('Permissão de notificações concedida: $notificacoesPermitidas');

    await androidPlugin?.requestExactAlarmsPermission();
    _canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    debugPrint('Pode agendar alarmes exatos: $_canScheduleExact');

    // Necessária pra tela de alarme conseguir abrir sozinha por cima da
    // tela bloqueada. Sem ela, o alarme cai pra notificação comum.
    final telaCompletaPermitida = await androidPlugin
        ?.requestFullScreenIntentPermission();
    debugPrint(
      'Permissão de notificação em tela cheia concedida: $telaCompletaPermitida',
    );
  }

  /// Se o app for aberto a partir do toque numa notificação (inclusive
  /// com o app totalmente fechado antes), navega direto pra tela de
  /// alarme. Precisa ser chamado uma vez no início do `main()`.
  Future<void> tratarLancamentoPorNotificacao() async {
    final detalhes = await _plugin.getNotificationAppLaunchDetails();
    if (detalhes?.didNotificationLaunchApp ?? false) {
      _abrirTelaDeAlarme(detalhes!.notificationResponse?.payload);
    }
  }

  void _aoReceberResposta(NotificationResponse resposta) {
    if (resposta.actionId == 'dispensar') {
      if (resposta.id != null) {
        _plugin.cancel(resposta.id!);
      }
      return;
    }

    if (resposta.actionId == 'adiar') {
      _adiarAPartirDoPayload(resposta.payload, 10);
      if (resposta.id != null) {
        _plugin.cancel(resposta.id!);
      }
      return;
    }

    _abrirTelaDeAlarme(resposta.payload);
  }

  void _abrirTelaDeAlarme(String? payload) {
    if (payload == null) return;
    final date = _decodePayload(payload);
    if (date == null) return;

    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => RingingAlarmScreen(
          reminderId: date.reminderId,
          title: date.title,
          type: date.type,
        ),
      ),
    );
  }

  Future<void> _adiarAPartirDoPayload(String? payload, int minutos) async {
    final date = _decodePayload(payload);
    if (date == null) return;

    await adiarLembrete(
      reminderId: date.reminderId,
      title: date.title,
      type: date.type,
      minutos: minutos,
    );
  }

  ({int reminderId, String title, ReminderType type})? _decodePayload(
    String? payload,
  ) {
    if (payload == null) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return (
        reminderId: map['lembreteId'] as int,
        title: map['titulo'] as String,
        type: ReminderType.fromValor(map['tipo'] as String),
      );
    } catch (e) {
      debugPrint('Payload de notificação inválido: $e');
      return null;
    }
  }

  String _generatePayload(int reminderId, String title, ReminderType type) {
    return jsonEncode({
      'lembreteId': reminderId,
      'titulo': title,
      'tipo': type.name,
    });
  }

  /// Agenda (ou reagenda) um lembrete ativo: se `repetir` for `true`,
  /// agenda um alarme semanal por dia selecionado; se for `false`, agenda
  /// um único disparo na data/hora escolhida.
  Future<void> scheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder);

    if (!reminder.active || reminder.id == null) return;

    final scheduleMode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (reminder.repeat) {
      for (final weekday in reminder.weekdays) {
        await _scheduleNotification(
          notificationId: _generateNotificationId(reminder.id!, weekday),
          reminderId: reminder.id!,
          title: reminder.title,
          type: reminder.type,
          scheduledFor: _nextWeeklyOccurrence(
            weekday,
            reminder.time,
            reminder.minute,
          ),
          scheduleMode: scheduleMode,
          repeat: true,
        );
      }
    } else if (reminder.date != null) {
      await _scheduleNotification(
        notificationId: _generateNotificationId(reminder.id!, 0),
        reminderId: reminder.id!,
        title: reminder.title,
        type: reminder.type,
        scheduledFor: tz.TZDateTime(
          tz.local,
          reminder.date!.year,
          reminder.date!.month,
          reminder.date!.day,
          reminder.time,
          reminder.minute,
        ),
        scheduleMode: scheduleMode,
        repeat: false,
      );
    }

    final pendingNotifications = await _plugin.pendingNotificationRequests();
    debugPrint(
      'Total de notificações pendentes no sistema agora: ${pendingNotifications.length}',
    );
  }

  /// Adia um lembrete que acabou de disparar por [minutos], agendando um
  /// disparo único a partir de agora. Usado pelos botões "Adiar" da tela
  /// de alarme e da ação da notificação.
  Future<void> adiarLembrete({
    required int reminderId,
    required String title,
    required ReminderType type,
    required int minutos,
  }) async {
    final scheduleMode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final scheduledFor = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutos));

    await _scheduleNotification(
      notificationId: _generateSnoozeNotificationId(reminderId),
      reminderId: reminderId,
      title: title,
      type: type,
      scheduledFor: scheduledFor,
      scheduleMode: scheduleMode,
      repeat: false,
    );
  }

  Future<void> _scheduleNotification({
    required int notificationId,
    required int reminderId,
    required String title,
    required ReminderType type,
    required tz.TZDateTime scheduledFor,
    required AndroidScheduleMode scheduleMode,
    required bool repeat,
  }) async {
    debugPrint(
      'Agendando lembrete "$title" (id $notificationId) '
      'para $scheduledFor — modo: $scheduleMode — repete: $repeat',
    );

    await _plugin.zonedSchedule(
      notificationId,
      title,
      _mensagemParaLembrete(type),
      scheduledFor,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNome,
          channelDescription: _canalDescricao,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: const RawResourceAndroidNotificationSound('alarme'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Não some sozinha nem ao tocar — só sai quando o usuário
          // Dispensar/Adiar, igual um despertador de verdade.
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('dispensar', 'Dispensar'),
            AndroidNotificationAction('adiar', 'Adiar 10 min'),
          ],
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
      payload: _generatePayload(reminderId, title, type),
    );
  }

  /// Cancela todos os agendamentos de um lembrete — os 7 dias da semana
  /// (índice 1-7), o slot de disparo único (índice 0) e o de soneca
  /// (índice 9) — sem afetar outros lembretes.
  Future<void> cancelReminder(ReminderModel reminder) async {
    if (reminder.id == null) return;
    for (final index in [0, 1, 2, 3, 4, 5, 6, 7, 9]) {
      await _plugin.cancel(_generateNotificationId(reminder.id!, index));
    }
  }

  int _generateSnoozeNotificationId(int reminderId) {
    return _generateNotificationId(reminderId, 9);
  }

  tz.TZDateTime _nextWeeklyOccurrence(int weekday, int time, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time,
      minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}

/// Callback de segundo plano (isolate separado, sem acesso ao restante do
/// app/DI) — é chamado sempre que o usuário toca direto num botão de
/// ação da notificação ("Dispensar"/"Adiar") e o app não está com uma
/// instância de [NotificationService] já rodando em primeiro plano
/// (o que cobre a maior parte dos casos reais, já que o alarme geralmente
/// dispara com o app em segundo plano ou fechado). Precisa ser uma função
/// de nível top-level e marcada com @pragma, por exigência do plugin.
///
/// Como esse isolate não compartilha memória com o app principal, ele
/// monta sua própria instância mínima do plugin e do fuso horário — não
/// dá pra reaproveitar o `get_it`/[NotificationService] normal aqui.
@pragma('vm:entry-point')
void _aoReceberRespostaSegundoPlano(NotificationResponse resposta) async {
  final plugin = FlutterLocalNotificationsPlugin();

  if (resposta.actionId == 'dispensar') {
    if (resposta.id != null) {
      await plugin.cancel(resposta.id!);
    }
    return;
  }

  if (resposta.actionId != 'adiar') return;

  final payload = resposta.payload;
  if (payload == null) return;

  try {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final reminderId = map['lembreteId'] as int;
    final title = map['titulo'] as String;
    final type = ReminderType.fromValor(map['tipo'] as String);

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Segue com o fuso padrão da biblioteca em vez de travar o adiar.
    }

    final scheduledFor = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 10));

    await plugin.zonedSchedule(
      _generateNotificationId(reminderId, 9),
      title,
      _mensagemParaLembrete(type),
      scheduledFor,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNome,
          channelDescription: _canalDescricao,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: const RawResourceAndroidNotificationSound('alarme'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('dispensar', 'Dispensar'),
            AndroidNotificationAction('adiar', 'Adiar 10 min'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'lembreteId': reminderId,
        'titulo': title,
        'tipo': type.name,
      }),
    );

    if (resposta.id != null) {
      await plugin.cancel(resposta.id!);
    }
  } catch (e) {
    debugPrint('Erro ao adiar em segundo plano: $e');
  }
}
