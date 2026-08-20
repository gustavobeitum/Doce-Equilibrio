import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';

class WeeklyGlycemiaSummary {
  const WeeklyGlycemiaSummary({
    required this.chartData,
    this.averageMgDl,
    this.minimumMgDl,
    this.maximumMgDl,
  });

  factory WeeklyGlycemiaSummary.fromChartData(GlycemiaChartData chartData) {
    if (chartData.records.isEmpty) {
      return WeeklyGlycemiaSummary(chartData: chartData);
    }

    var sum = 0.0;
    var minimum = chartData.records.first.value;
    var maximum = chartData.records.first.value;
    for (final record in chartData.records) {
      sum += record.value;
      if (record.value < minimum) minimum = record.value;
      if (record.value > maximum) maximum = record.value;
    }

    return WeeklyGlycemiaSummary(
      chartData: chartData,
      averageMgDl: sum / chartData.records.length,
      minimumMgDl: minimum,
      maximumMgDl: maximum,
    );
  }

  final GlycemiaChartData chartData;
  final double? averageMgDl;
  final int? minimumMgDl;
  final int? maximumMgDl;
}
