import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/charts/controllers/charts_controller.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late final ChartsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ChartsController>()..addListener(_refresh);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _selectPeriod(HistoryPeriod period) async {
    HistoryDateRange? range;
    if (period == HistoryPeriod.custom) {
      final now = DateTime.now();
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        ),
        helpText: 'Selecionar período',
        cancelText: 'Cancelar',
        confirmText: 'Aplicar',
      );
      if (selected == null || !mounted) return;
      range = HistoryDateRange.forPeriod(
        HistoryPeriod.custom,
        customStart: selected.start,
        customEnd: selected.end,
      );
    }
    await _controller.changePeriod(period, range: range);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primaryColor,
    body: SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.backgroundColor,
              child: Column(
                children: [
                  _periodSelector(),
                  Expanded(child: _content()),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    color: AppColors.primaryColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIcons.caretLeft,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            _HeaderIcon(),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gráficos de Glicemia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Acompanhe seus registros ao longo do tempo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _periodSelector() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: HistoryPeriod.values.map((period) {
        final label = switch (period) {
          HistoryPeriod.today => 'Hoje',
          HistoryPeriod.last7Days => '7 dias',
          HistoryPeriod.last30Days => '30 dias',
          HistoryPeriod.last90Days => '90 dias',
          HistoryPeriod.custom => 'Personalizado',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _controller.period == period,
            onSelected: _controller.isLoading
                ? null
                : (_) => _selectPeriod(period),
          ),
        );
      }).toList(),
    ),
  );

  Widget _content() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    if (_controller.errorMessage != null) {
      return _message(
        icon: PhosphorIcons.warningCircle,
        text: _controller.errorMessage!,
        action: ElevatedButton(
          onPressed: _controller.load,
          child: const Text('Tentar novamente'),
        ),
      );
    }
    final data = _controller.data;
    if (data == null || data.isEmpty) {
      return _message(
        icon: PhosphorIcons.chartLine,
        text: 'Nenhum registro de glicemia neste período.',
      );
    }
    if (!data.hasEnoughData) {
      return _message(
        icon: PhosphorIcons.chartLine,
        text:
            'São necessários pelo menos dois registros de glicemia para visualizar os gráficos.',
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _card('Evolução glicêmica', 'Glicemia em mg/dL', _lineChart(data)),
          const SizedBox(height: 16),
          _card(
            'Distribuição glicêmica',
            '${data.records.length} registros no período',
            _distributionChart(data),
          ),
        ],
      ),
    );
  }

  Widget _lineChart(GlycemiaChartData data) {
    final values = data.records.map((record) => record.value).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 20).clamp(0, 999);
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 20).clamp(0, 999);
    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: minY.toDouble(),
          maxY: maxY == minY ? maxY + 1 : maxY.toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              axisNameWidget: Text('mg/dL'),
              sideTitles: SideTitles(showTitles: true, reservedSize: 44),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: data.records.length > 4
                    ? (data.records.length - 1) / 2
                    : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= data.records.length) {
                    return const SizedBox.shrink();
                  }
                  final date = data.records[index].dateTime;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${_two(date.day)}/${_two(date.month)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final record = data.records[spot.x.round()];
                return LineTooltipItem(
                  '${record.value} mg/dL\n${_two(record.dateTime.day)}/${_two(record.dateTime.month)} ${_two(record.dateTime.hour)}:${_two(record.dateTime.minute)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.records.length; i++)
                  FlSpot(i.toDouble(), data.records[i].value.toDouble()),
              ],
              isCurved: false,
              color: AppColors.primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _distributionChart(GlycemiaChartData data) => Column(
    children: [
      SizedBox(
        height: 210,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 42,
            sectionsSpace: 3,
            sections: data.distribution
                .map(
                  (item) => PieChartSectionData(
                    value: item.count.toDouble(),
                    color: _color(item.level),
                    title: '${item.percentage.toStringAsFixed(0)}%',
                    radius: 62,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...data.distribution.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _color(item.level),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_label(item.level))),
              Text(
                '${item.count} (${item.percentage.toStringAsFixed(1).replaceAll('.', ',')}%)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _card(String title, String subtitle, Widget child) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );

  Widget _message({
    required IconData icon,
    required String text,
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    ),
  );

  Color _color(GlycemiaLevel level) => switch (level) {
    GlycemiaLevel.hypoglycemia => AppColors.dangerColor,
    GlycemiaLevel.normal => AppColors.normalColor,
    GlycemiaLevel.hyperglycemia => AppColors.warningColor,
  };

  String _label(GlycemiaLevel level) => switch (level) {
    GlycemiaLevel.hypoglycemia => 'Hipoglicemia',
    GlycemiaLevel.normal => 'Normal',
    GlycemiaLevel.hyperglycemia => 'Hiperglicemia',
  };

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.15),
    ),
    child: const Icon(PhosphorIcons.chartLine, color: Colors.white, size: 24),
  );
}
