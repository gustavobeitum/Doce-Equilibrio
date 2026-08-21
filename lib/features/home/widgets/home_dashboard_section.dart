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
        const SizedBox(height: 16),
        _ExportReportButton(onPressed: onExportReport),
      ],
    );
  }
}

/// Classificação de referência da HbA1c (padrão SBD/ADA), usada apenas para
/// exibir um selo informativo ao usuário — não substitui avaliação médica.
class _Hba1cRange {
  const _Hba1cRange(this.label, this.color);

  final String label;
  final Color color;

  static _Hba1cRange forPercentage(double percentage) {
    if (percentage < 5.7) {
      return const _Hba1cRange('Normal', AppColors.normalColor);
    }
    if (percentage < 6.5) {
      return const _Hba1cRange('Pré-diabetes', AppColors.warningColor);
    }
    return const _Hba1cRange('Diabetes', AppColors.dangerColor);
  }
}

class _Hba1cCard extends StatelessWidget {
  const _Hba1cCard({required this.estimate});

  final HbA1cEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final range = estimate != null
        ? _Hba1cRange.forPercentage(estimate!.percentage)
        : null;

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: PhosphorIcons.heartbeat,
            title: 'HbA1c Estimada',
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
            const SizedBox(height: 8),
            Container(
              key: const Key('hba1c-classification-badge'),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: range!.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  color: range.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Hba1cGauge(
              key: const Key('hba1c-gauge'),
              percentage: estimate!.percentage,
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

/// Barra de gradiente (verde → amarelo → laranja → vermelho) com um marcador
/// indicando onde a HbA1c estimada do usuário cai nessa faixa.
class _Hba1cGauge extends StatelessWidget {
  const _Hba1cGauge({super.key, required this.percentage});

  final double percentage;

  static const double _min = 4.0;
  static const double _max = 9.0;
  static const double _markerWidth = 6;

  @override
  Widget build(BuildContext context) {
    final fraction = ((percentage - _min) / (_max - _min)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final markerLeft =
            (constraints.maxWidth - _markerWidth) * fraction;
        return SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.normalColor,
                        Color(0xFFFFC107),
                        Color(0xFFFF7043),
                        AppColors.dangerColor,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                top: 0,
                child: Container(
                  width: _markerWidth,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          const _CardTitle(
            icon: PhosphorIcons.chartLine,
            title: 'Tendência Semanal',
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
                height: 170,
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

    // Intervalo "redondo" dos rótulos à esquerda (10, 20, 25, 50 ou 100).
    final rawRange = (maximum - minimum + 40).clamp(1, 999).toDouble();
    final leftInterval = _niceInterval(rawRange);

    // Alinha o mínimo/máximo do eixo a múltiplos do intervalo, para que os
    // rótulos fiquem igualmente espaçados e nunca colados nas bordas
    // (ex.: evita um "44" quase grudado no "50").
    final minY = (((minimum - 20) / leftInterval).floor() * leftInterval)
        .clamp(0, 999)
        .toDouble();
    final maxY = (((maximum + 20) / leftInterval).ceil() * leftInterval)
        .clamp(0, 999)
        .toDouble();

    return LineChartData(
      minX: 0,
      maxX: 6.999,
      minY: minY,
      maxY: maxY == minY ? minY + 1 : maxY,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: leftInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: leftInterval,
            getTitlesWidget: (value, meta) => Text(
              value.round().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > 6 || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              final date = weekStart.add(Duration(days: value.round()));
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  _weekday(date.weekday),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
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
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: AppColors.primaryColor,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.35),
                AppColors.primaryColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
      // Estilo da caixinha (tooltip) que aparece ao tocar/arrastar no gráfico.
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.primaryColor,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.round()} mg/dL',
                const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: AppColors.primaryColor, strokeWidth: 2),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                      strokeColor: AppColors.white,
                    ),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

/// Calcula um intervalo "redondo" para os rótulos do eixo vertical
/// (ex.: 20, 50, 100 mg/dL) a partir do range de valores exibido.
double _niceInterval(double range) {
  if (range <= 0) return 1;
  const steps = [10, 20, 25, 50, 100];
  for (final step in steps) {
    if (range / step <= 5) return step.toDouble();
  }
  return (range / 5).roundToDouble();
}

/// Título de card com um pequeno ícone à esquerda, usado tanto no card de
/// HbA1c quanto no de tendência semanal.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Botão de "Exportar relatório" com visual de destaque (pílula preenchida
/// com a cor primária), em vez do TextButton simples anterior.
class _ExportReportButton extends StatelessWidget {
  const _ExportReportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('export-report-button'),
        onPressed: onPressed,
        icon: const Icon(PhosphorIcons.filePdf, size: 20),
        label: const Text('Exportar relatório'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
          shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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