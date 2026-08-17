import 'package:doce_equilibrio/core/notifications/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa e interpreta payload de lembrete', () {
    const original = NotificationPayload(
      reminderId: 12,
      title: 'Insulina basal',
      type: 'insulinaBasal',
    );

    final parsed = NotificationPayload.tryParse(original.encode());

    expect(parsed?.reminderId, original.reminderId);
    expect(parsed?.title, original.title);
    expect(parsed?.type, original.type);
  });

  test('retorna null para payload ausente, inválido ou incompleto', () {
    expect(NotificationPayload.tryParse(null), isNull);
    expect(NotificationPayload.tryParse('inválido'), isNull);
    expect(NotificationPayload.tryParse('{"lembreteId": 1}'), isNull);
  });
}
