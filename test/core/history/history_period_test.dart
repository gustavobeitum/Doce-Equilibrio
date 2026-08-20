import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 19, 14, 30);

  test('Hoje cobre o dia inteiro com limites inclusivos', () {
    final range = HistoryDateRange.forPeriod(HistoryPeriod.today, now: now);

    expect(range.start, DateTime(2026, 8, 19));
    expect(range.end, DateTime(2026, 8, 19, 23, 59, 59, 999, 999));
  });

  test('7, 30 e 90 dias incluem hoje e o primeiro dia', () {
    final cases = {
      HistoryPeriod.last7Days: DateTime(2026, 8, 13),
      HistoryPeriod.last30Days: DateTime(2026, 7, 21),
      HistoryPeriod.last90Days: DateTime(2026, 5, 22),
    };

    for (final entry in cases.entries) {
      final range = HistoryDateRange.forPeriod(entry.key, now: now);
      expect(range.start, entry.value);
      expect(range.end, DateTime(2026, 8, 19, 23, 59, 59, 999, 999));
    }
  });

  test('personalizado normaliza início e fim dos dias', () {
    final range = HistoryDateRange.forPeriod(
      HistoryPeriod.custom,
      customStart: DateTime(2026, 8, 2, 15),
      customEnd: DateTime(2026, 8, 5, 8),
    );

    expect(range.start, DateTime(2026, 8, 2));
    expect(range.end, DateTime(2026, 8, 5, 23, 59, 59, 999, 999));
  });

  test('personalizado rejeita data final anterior à inicial', () {
    expect(
      () => HistoryDateRange.forPeriod(
        HistoryPeriod.custom,
        customStart: DateTime(2026, 8, 5),
        customEnd: DateTime(2026, 8, 4),
      ),
      throwsArgumentError,
    );
  });
}
