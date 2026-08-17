import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';

abstract interface class ReminderNotificationService {
  Future<void> scheduleReminder(ReminderModel reminder);
  Future<void> cancelReminder(ReminderModel reminder);
  Future<void> snoozeReminder({
    required int reminderId,
    required String title,
    required ReminderType type,
    required int minutes,
  });
}
