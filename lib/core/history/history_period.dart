enum HistoryPeriod { today, last7Days, last30Days, last90Days, custom }

class HistoryDateRange {
  const HistoryDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory HistoryDateRange.forPeriod(
    HistoryPeriod period, {
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final endOfToday = today
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    if (period == HistoryPeriod.custom) {
      if (customStart == null || customEnd == null) {
        throw ArgumentError('Informe as datas inicial e final.');
      }
      final start = DateTime(
        customStart.year,
        customStart.month,
        customStart.day,
      );
      final end = DateTime(
        customEnd.year,
        customEnd.month,
        customEnd.day,
      ).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      if (end.isBefore(start)) {
        throw ArgumentError('A data final não pode ser anterior à inicial.');
      }
      return HistoryDateRange(start: start, end: end);
    }

    final days = switch (period) {
      HistoryPeriod.today => 1,
      HistoryPeriod.last7Days => 7,
      HistoryPeriod.last30Days => 30,
      HistoryPeriod.last90Days => 90,
      HistoryPeriod.custom => throw StateError(
        'Período personalizado inválido.',
      ),
    };
    return HistoryDateRange(
      start: today.subtract(Duration(days: days - 1)),
      end: endOfToday,
    );
  }
}
