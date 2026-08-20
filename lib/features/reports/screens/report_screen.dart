import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/reports/controllers/report_controller.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ReportController>()..addListener(_refresh);
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

  Future<void> _generate() async {
    HistoryDateRange? range;
    if (_controller.period == HistoryPeriod.custom) {
      final now = DateTime.now();
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        ),
        helpText: 'Período do relatório',
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
    await _controller.generate(range: range);
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Período do relatório',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _periodSelector(),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _controller.isGenerating ? null : _generate,
                    icon: _controller.isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(PhosphorIcons.filePdf),
                    label: Text(
                      _controller.isGenerating
                          ? 'Gerando relatório...'
                          : 'Gerar relatório',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_controller.hasNoData)
                    _message(
                      PhosphorIcons.info,
                      'Nenhum registro encontrado no período selecionado.',
                    ),
                  if (_controller.errorMessage != null)
                    _message(
                      PhosphorIcons.warningCircle,
                      _controller.errorMessage!,
                      danger: true,
                    ),
                  if (_controller.pdfBytes != null) _success(),
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
            Icon(PhosphorIcons.filePdf, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relatório',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gere e compartilhe seu acompanhamento',
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

  Widget _periodSelector() => SegmentedButton<HistoryPeriod>(
    segments: const [
      ButtonSegment(value: HistoryPeriod.last30Days, label: Text('30 dias')),
      ButtonSegment(value: HistoryPeriod.last90Days, label: Text('90 dias')),
      ButtonSegment(value: HistoryPeriod.custom, label: Text('Personalizado')),
    ],
    selected: {_controller.period},
    onSelectionChanged: _controller.isGenerating
        ? null
        : (selection) => _controller.changePeriod(selection.single),
  );

  Widget _success() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            PhosphorIcons.checkCircle,
            color: AppColors.normalColor,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            _controller.successMessage ?? 'Relatório gerado com sucesso.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${_controller.pdfBytes!.length} bytes • armazenado temporariamente em memória',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _controller.isSharing ? null : _controller.share,
            icon: _controller.isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIcons.shareNetwork),
            label: Text(
              _controller.isSharing
                  ? 'Abrindo compartilhamento...'
                  : 'Compartilhar relatório',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O destino será escolhido por você no menu nativo do dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _message(IconData icon, String text, {bool danger = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: danger ? AppColors.dangerColor : AppColors.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
