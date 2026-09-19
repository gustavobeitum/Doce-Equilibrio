import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/period_selector.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/charts/screens/charts_screen.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/screens/glycemia_history_screen.dart';
import 'package:doce_equilibrio/features/glycemia/widgets/glycemia_record_card.dart';
import 'package:doce_equilibrio/features/reports/screens/report_screen.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final GlycemiaController _glycemiaController;
  late final ProfileController _profileController;

  HistoryPeriod _period = HistoryPeriod.last30Days;
  HistoryDateRange? _customRange;
  bool _isLoading = true;
  String? _error;
  UserModel? _user;
  List<GlycemiaRecordModel> _glycemias = const [];

  @override
  void initState() {
    super.initState();
    _glycemiaController = getIt<GlycemiaController>();
    _profileController = getIt<ProfileController>();
    _load();
  }

  HistoryDateRange get _range => _period == HistoryPeriod.custom
      ? _customRange!
      : HistoryDateRange.forPeriod(_period);

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final range = _range;
      final results = await Future.wait([
        _glycemiaController.listHistoryByPeriod(range.start, range.end),
        _profileController.loadCurrentUser(),
      ]);
      _glycemias = results.first as List<GlycemiaRecordModel>;
      _user = results.last as UserModel?;
    } catch (_) {
      _error = 'Não foi possível carregar os registros deste período.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePeriod(HistoryPeriod period) async {
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
      _customRange = HistoryDateRange.forPeriod(
        HistoryPeriod.custom,
        customStart: selected.start,
        customEnd: selected.end,
      );
    }
    setState(() => _period = period);
    await _load();
  }

  Future<void> _openManagement(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) await _load();
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
              color: AppColors.backgroundColor,
              child: Column(
                children: [_periodSelector(), Expanded(child: _content())],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
    color: AppColors.primaryColor,
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(PhosphorIcons.caretLeft, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Icon(
          PhosphorIcons.clockCounterClockwise,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de Glicemia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Filtre por período, veja gráficos ou gerencie os registros',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Gerar relatório',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ReportScreen()),
          ),
          icon: const Icon(PhosphorIcons.filePdf, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _periodSelector() => PeriodSelector(
    periods: HistoryPeriod.values,
    selected: _period,
    onSelected: _changePeriod,
  );

  Widget _content() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PhosphorIcons.warningCircle,
                color: AppColors.dangerColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _actions(),
          const SizedBox(height: 16),
          if (_glycemias.isEmpty || _user == null)
            _empty('Nenhum registro de glicemia neste período.')
          else
            ..._glycemias.map(
              (record) => GlycemiaRecordCard(
                record: record,
                user: _user!,
                onEditar: () => _openManagement(
                  GlycemiaHistoryScreen(focusRecordId: record.id),
                ),
                onExcluir: () => _openManagement(
                  GlycemiaHistoryScreen(
                    focusRecordId: record.id,
                    autoOpenEdit: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton.icon(
        onPressed: () => _openManagement(const ChartsScreen()),
        icon: const Icon(PhosphorIcons.chartLine),
        label: const Text('Visualizar gráficos'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => _openManagement(const GlycemiaHistoryScreen()),
        icon: const Icon(PhosphorIcons.pencilSimple),
        label: const Text('Gerenciar glicemias'),
      ),
    ],
  );

  Widget _empty(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Text(message, textAlign: TextAlign.center),
  );
}