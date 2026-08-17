import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/reminders/controllers/reminder_controller.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:doce_equilibrio/features/reminders/services/reminder_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeReminderRepository repository;
  late _FakeNotificationService notifications;
  late ReminderController controller;

  setUp(() {
    repository = _FakeReminderRepository();
    notifications = _FakeNotificationService();
    controller = ReminderController(
      repository,
      notifications,
      _FakeSessionService(),
    );
  });

  test('desativar persiste e cancela sem usar plugin nativo', () async {
    final result = await controller.alternarAtivo(_reminder(active: true));

    expect(result, isTrue);
    expect(repository.updated?.active, isFalse);
    expect(notifications.cancelled?.id, 3);
    expect(notifications.scheduled, isNull);
  });

  test('ativar persiste e solicita reagendamento', () async {
    final result = await controller.alternarAtivo(_reminder(active: false));

    expect(result, isTrue);
    expect(repository.updated?.active, isTrue);
    expect(notifications.scheduled?.id, 3);
    expect(notifications.cancelled, isNull);
  });
}

ReminderModel _reminder({required bool active}) {
  return ReminderModel(
    id: 3,
    userId: 1,
    type: ReminderType.medication,
    title: 'Medicamento',
    time: 8,
    minute: 30,
    repeat: true,
    weekdays: const [1, 3, 5],
    active: active,
  );
}

class _FakeNotificationService implements ReminderNotificationService {
  ReminderModel? scheduled;
  ReminderModel? cancelled;

  @override
  Future<void> cancelReminder(ReminderModel reminder) async {
    cancelled = reminder;
  }

  @override
  Future<void> scheduleReminder(ReminderModel reminder) async {
    scheduled = reminder;
  }

  @override
  Future<void> snoozeReminder({
    required int reminderId,
    required String title,
    required ReminderType type,
    required int minutes,
  }) async {}
}

class _FakeReminderRepository implements ReminderRepositoryInterface {
  ReminderModel? updated;

  @override
  Future<int> create(ReminderModel reminder) async => 1;

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<List<ReminderModel>> listByUser(int userId) async => [];

  @override
  Future<int> update(ReminderModel reminder) async {
    updated = reminder;
    return 1;
  }
}

class _FakeSessionService implements SessionService {
  @override
  Future<void> endSession() async {}

  @override
  Future<int?> getCurrentUserId() async => 1;

  @override
  Future<void> startSession(int userId) async {}
}
