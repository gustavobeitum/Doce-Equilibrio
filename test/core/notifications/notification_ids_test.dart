import 'package:doce_equilibrio/core/notifications/notification_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera IDs determinísticos e distintos para cada slot', () {
    expect(NotificationIds.single(15), 150);
    expect(NotificationIds.weekly(15, DateTime.monday), 151);
    expect(NotificationIds.weekly(15, DateTime.sunday), 157);
    expect(NotificationIds.snooze(15), 159);
  });

  test('lista todos os IDs canceláveis de um lembrete', () {
    expect(
      NotificationIds.allForReminder(2),
      orderedEquals([20, 21, 22, 23, 24, 25, 26, 27, 29]),
    );
  });
}
