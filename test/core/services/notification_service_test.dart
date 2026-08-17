import 'package:doce_equilibrio/core/notifications/notification_scheduler.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeScheduler scheduler;
  late _FakeReminderRepository repository;
  late NotificationService service;

  setUp(() {
    scheduler = _FakeScheduler();
    repository = _FakeReminderRepository();
    service = NotificationService(scheduler, repository);
  });

  test('dispensar remove a notificação e conclui disparo único', () async {
    await service.dismissReminder(reminderId: 7, notificationId: 70);

    expect(scheduler.cancelled, [70]);
    expect(repository.completedId, 7);
  });

  test('soneca remove o disparo e substitui agendamento anterior', () async {
    await service.snoozeReminder(
      reminderId: 7,
      title: 'Medicamento',
      type: ReminderType.medication,
      minutes: 10,
      notificationId: 70,
    );

    expect(scheduler.cancelled, [70, 79]);
    expect(scheduler.afterId, 79);
    expect(scheduler.afterDelay, const Duration(minutes: 10));
    expect(repository.completedId, isNull);
  });
}

class _FakeScheduler implements NotificationScheduler {
  final List<int> cancelled = [];
  int? afterId;
  Duration? afterDelay;

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<NotificationResponse?> getLaunchResponse() async => null;

  @override
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback onResponse,
    required DidReceiveBackgroundNotificationResponseCallback
    onBackgroundResponse,
  }) async {}

  @override
  Future<void> scheduleAfter({
    required int id,
    required String title,
    required String body,
    required String payload,
    required Duration delay,
  }) async {
    afterId = id;
    afterDelay = delay;
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime dateTime,
  }) async {}

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int weekday,
    required int hour,
    required int minute,
  }) async {}
}

class _FakeReminderRepository implements ReminderRepositoryInterface {
  int? completedId;

  @override
  Future<int> completeSingle(int id) async {
    completedId = id;
    return 1;
  }

  @override
  Future<int> create(ReminderModel reminder) async => 1;

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<List<ReminderModel>> listByUser(int userId) async => [];

  @override
  Future<int> update(ReminderModel reminder) async => 1;
}
