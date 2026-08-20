import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';

class GlycemiaDistributionItem {
  const GlycemiaDistributionItem({
    required this.level,
    required this.count,
    required this.percentage,
  });

  final GlycemiaLevel level;
  final int count;
  final double percentage;
}

class GlycemiaChartData {
  const GlycemiaChartData({required this.records, required this.distribution});

  final List<GlycemiaRecordModel> records;
  final List<GlycemiaDistributionItem> distribution;

  bool get isEmpty => records.isEmpty;
  bool get hasEnoughData => records.length >= 2;

  factory GlycemiaChartData.fromRecords(
    List<GlycemiaRecordModel> source, {
    required int lowAlertThreshold,
    required int highDangerThreshold,
  }) {
    final records = List<GlycemiaRecordModel>.of(source)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final counts = {for (final level in GlycemiaLevel.values) level: 0};

    for (final record in records) {
      final level = GlycemiaClassifier.classify(
        record.value,
        lowAlertThreshold: lowAlertThreshold,
        highDangerThreshold: highDangerThreshold,
      );
      counts[level] = counts[level]! + 1;
    }

    final total = records.length;
    return GlycemiaChartData(
      records: List.unmodifiable(records),
      distribution: GlycemiaLevel.values
          .map(
            (level) => GlycemiaDistributionItem(
              level: level,
              count: counts[level]!,
              percentage: total == 0 ? 0 : counts[level]! * 100 / total,
            ),
          )
          .toList(growable: false),
    );
  }
}
