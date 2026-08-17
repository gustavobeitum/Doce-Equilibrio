abstract final class NotificationIds {
  static int forReminderSlot(int reminderId, int slot) {
    return reminderId * 10 + slot;
  }

  static int single(int reminderId) => forReminderSlot(reminderId, 0);

  static int weekly(int reminderId, int weekday) {
    return forReminderSlot(reminderId, weekday);
  }

  static int snooze(int reminderId) => forReminderSlot(reminderId, 9);

  static Iterable<int> allForReminder(int reminderId) sync* {
    for (final slot in const [0, 1, 2, 3, 4, 5, 6, 7, 9]) {
      yield forReminderSlot(reminderId, slot);
    }
  }
}
