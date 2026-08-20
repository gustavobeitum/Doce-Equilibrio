import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/home/models/weekly_glycemia_summary.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({
    super.key,
    required this.hba1cEstimate,
    required this.weeklySummary,
    required this.weekStart,
    required this.onExportReport,
  });

  final HbA1cEstimate? hba1cEstimate;
  final WeeklyGlycemiaSummary weeklySummary;
  final DateTime weekStart;
  final VoidCallback onExportReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Hba1cCard(estimate: hba1cEstimate),
        const SizedBox(height: 16),
        _WeeklyTrendCard(summary: weeklySummary, weekStart: weekStart),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('export-report-button'),
            onPressed: onExportReport,
            icon: const Icon(PhosphorIcons.filePdf, size: 20),
            label: const Text('Exportar relatório'),
          ),
        ),
      ],
    );
  }
}

class _Hba1cCard extends StatelessWidget {
  const _Hba1cCard({required this.estimate});

  final HbA1cEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HbA1c Estimada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Baseada nos últimos 90 dias',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (estimate == null)
            const Text(
              'Registre glicemias para calcular sua HbA1c estimada.',
              key: Key('hba1c-empty-state'),
            )
          else ...[
            Text(
              '${_decimal(estimate!.percentage)}%',
              key: const Key('hba1c-value'),
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('hba1c-neutral-indicator'),
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Média Glicêmica',
                    value: '${_decimal(estimate!.averageGlycemiaMgDl)} mg/dL',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Medições',
                    value: '${estimate!.recordCount}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.summary, required this.weekStart});

  final WeeklyGlycemiaSummary summary;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final data = summary.chartData;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendência Semanal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Registre glicemias para visualizar sua tendência semanal.',
                key: Key('weekly-empty-state'),
              ),
            )
          else ...[
            if (data.hasEnoughData)
              SizedBox(
                key: const Key('weekly-line-chart'),
                height: 190,
                child: LineChart(_chartData()),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Uma medição disponível. Registre mais uma para visualizar a linha de tendência.',
                  key: Key('weekly-single-record-state'),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Média',
                    value: '${_decimal(summary.averageMgDl!)} mg/dL',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Mínima',
                    value: '${summary.minimumMgDl} mg/dL',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Máxima',
                    value: '${summary.maximumMgDl} mg/dL',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _chartData() {
    final records = summary.chartData.records;
    final minimum = summary.minimumMgDl!;
    final maximum = summary.maximumMgDl!;
    final minY = (minimum - 20).clamp(0, 999).toDouble();
    final maxY = (maximum + 20).clamp(0, 999).toDouble();

    return LineChartData(
      minX: 0,
      maxX: 6.999,
      minY: minY,
      maxY: maxY == minY ? minY + 1 : maxY,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 42),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > 6 || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              final date = weekStart.add(Duration(days: value.round()));
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  _weekday(date.weekday),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: records.map((record) {
            final elapsed = record.dateTime.difference(weekStart);
            return FlSpot(
              elapsed.inMilliseconds / Duration.millisecondsPerDay,
              record.value.toDouble(),
            );
          }).toList(),
          isCurved: false,
          color: AppColors.primaryColor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryColor.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

String _decimal(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _weekday(int weekday) {
  return const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][weekday - 1];
}
