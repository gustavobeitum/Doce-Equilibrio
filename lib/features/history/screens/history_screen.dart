import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/utils/formatters.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/charts/screens/charts_screen.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/screens/glycemia_history_screen.dart';
import 'package:doce_equilibrio/features/glycemia/widgets/glycemia_record_card.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/insulin/screens/insulin_calculator_screen.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/screens/meals_screen.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_summary.dart';
import 'package:doce_equilibrio/features/reports/screens/report_screen.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum HistoryCategory { glycemia, insulin, meals }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final GlycemiaController _glycemiaController;
  late final InsulinApplicationController _insulinController;
  late final MealController _mealController;
  late final ProfileController _profileController;

  HistoryCategory _category = HistoryCategory.glycemia;
  HistoryPeriod _period = HistoryPeriod.last30Days;
  HistoryDateRange? _customRange;
  bool _isLoading = true;
  String? _error;
  UserModel? _user;
  List<GlycemiaRecordModel> _glycemias = const [];
  List<InsulinApplicationModel> _applications = const [];
  List<MealModel> _meals = const [];

  @override
  void initState() {
    super.initState();
    _glycemiaController = getIt<GlycemiaController>();
    _insulinController = getIt<InsulinApplicationController>();
    _mealController = getIt<MealController>();
    _profileController = getIt<ProfileController>();
    _load();
  }

  @override
  void dispose() {
    _insulinController.dispose();
    super.dispose();
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
      switch (_category) {
        case HistoryCategory.glycemia:
          final results = await Future.wait([
            _glycemiaController.listHistoryByPeriod(range.start, range.end),
            _profileController.loadCurrentUser(),
          ]);
          _glycemias = results.first as List<GlycemiaRecordModel>;
          _user = results.last as UserModel?;
        case HistoryCategory.insulin:
          _applications = await _insulinController.listByPeriod(
            range.start,
            range.end,
          );
        case HistoryCategory.meals:
          _meals = await _mealController.listByPeriod(range.start, range.end);
      }
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
                children: [
                  _categorySelector(),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Seus principais registros',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
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

  Widget _categorySelector() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: SegmentedButton<HistoryCategory>(
      segments: const [
        ButtonSegment(value: HistoryCategory.glycemia, label: Text('Glicemia')),
        ButtonSegment(value: HistoryCategory.insulin, label: Text('Insulina')),
        ButtonSegment(value: HistoryCategory.meals, label: Text('Refeições')),
      ],
      selected: {_category},
      onSelectionChanged: (selection) {
        setState(() => _category = selection.single);
        _load();
      },
    ),
  );

  Widget _periodSelector() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            selected: _period == period,
            onSelected: (_) => _changePeriod(period),
          ),
        );
      }).toList(),
    ),
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
    return switch (_category) {
      HistoryCategory.glycemia => _glycemiaContent(),
      HistoryCategory.insulin => _insulinContent(),
      HistoryCategory.meals => _mealContent(),
    };
  }

  Widget _list(List<Widget> children, Widget managementButton) =>
      RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [managementButton, const SizedBox(height: 16), ...children],
        ),
      );

  Widget _glycemiaContent() => _list(
    _glycemias.isEmpty || _user == null
        ? [_empty('Nenhum registro de glicemia neste período.')]
        : _glycemias
              .map(
                (record) => GlycemiaRecordCard(
                  record: record,
                  user: _user!,
                  onEditar: () =>
                      _openManagement(const GlycemiaHistoryScreen()),
                  onExcluir: () =>
                      _openManagement(const GlycemiaHistoryScreen()),
                ),
              )
              .toList(),
    Column(
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
    ),
  );

  Widget _insulinContent() => _list(
    _applications.isEmpty
        ? [_empty('Nenhuma aplicação de insulina neste período.')]
        : _applications
              .map(
                (item) => Card(
                  child: ListTile(
                    title: Text(
                      '${Formatters.date(item.dateTime)} • ${Formatters.time(item.dateTime)}',
                    ),
                    subtitle: Text(
                      'Aplicada: ${_number(item.appliedDose)} UI\n'
                      'Recomendada: ${_number(item.recommendedDose)} UI\n'
                      '${item.glycemia} mg/dL • ${_number(item.carbohydrates)} g',
                    ),
                  ),
                ),
              )
              .toList(),
    OutlinedButton.icon(
      onPressed: () => _openManagement(const InsulinCalculatorScreen()),
      icon: const Icon(PhosphorIcons.pencilSimple),
      label: const Text('Gerenciar aplicações'),
    ),
  );

  Widget _mealContent() => _list(
    _meals.isEmpty
        ? [_empty('Nenhuma refeição neste período.')]
        : _meals
              .map(
                (meal) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: MealSummary(meal: meal),
                  ),
                ),
              )
              .toList(),
    OutlinedButton.icon(
      onPressed: () => _openManagement(const MealsScreen()),
      icon: const Icon(PhosphorIcons.pencilSimple),
      label: const Text('Gerenciar refeições'),
    ),
  );

  Widget _empty(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Text(message, textAlign: TextAlign.center),
  );

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
}
