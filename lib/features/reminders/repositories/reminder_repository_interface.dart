import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';

abstract class ReminderRepositoryInterface {
  Future<int> create(ReminderModel reminder);
  Future<int> update(ReminderModel reminder);
  Future<int> delete(int id);
  Future<List<ReminderModel>> listByUser(int userId);
}
