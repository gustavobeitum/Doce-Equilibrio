import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/reports/models/report_data.dart';
import 'package:doce_equilibrio/features/reports/services/report_pdf_service.dart';
import 'package:doce_equilibrio/features/reports/services/report_share_service.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/foundation.dart';

class ReportController extends ChangeNotifier {
  ReportController(
    this._glycemiaController,
    this._insulinController,
    this._mealController,
    this._profileController,
    this._pdfService,
    this._shareService, {
    this._hba1cCalculator = const HbA1cCalculator(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GlycemiaController _glycemiaController;
  final InsulinApplicationController _insulinController;
  final MealController _mealController;
  final ProfileController _profileController;
  final ReportPdfService _pdfService;
  final ReportShareService _shareService;
  final HbA1cCalculator _hba1cCalculator;
  final DateTime Function() _now;

  HistoryPeriod period = HistoryPeriod.last30Days;
  HistoryDateRange? customRange;
  ReportData? data;
  Uint8List? pdfBytes;
  bool isGenerating = false;
  bool isSharing = false;
  bool hasNoData = false;
  String? errorMessage;
  String? successMessage;

  Future<void> generate({HistoryDateRange? range}) async {
    if (period == HistoryPeriod.custom && range != null) customRange = range;
    final selectedRange = period == HistoryPeriod.custom
        ? customRange
        : HistoryDateRange.forPeriod(period, now: _now());
    if (selectedRange == null) {
      errorMessage = 'Selecione o período personalizado.';
      notifyListeners();
      return;
    }

    isGenerating = true;
    errorMessage = null;
    successMessage = null;
    hasNoData = false;
    data = null;
    pdfBytes = null;
    notifyListeners();
    try {
      final user = await _profileController.loadCurrentUser();
      if (user == null) throw StateError('Usuário não encontrado.');
      final glycemia = await _glycemiaController.listHistoryByPeriod(
        selectedRange.start,
        selectedRange.end,
      );
      final applications = await _insulinController.listByPeriod(
        selectedRange.start,
        selectedRange.end,
      );
      final meals = await _mealController.listByPeriod(
        selectedRange.start,
        selectedRange.end,
      );
      final hba1cRange = HistoryDateRange.forPeriod(
        HistoryPeriod.last90Days,
        now: _now(),
      );
      final hba1cRecords = await _glycemiaController.listHistoryByPeriod(
        hba1cRange.start,
        hba1cRange.end,
      );
      final chartData = GlycemiaChartData.fromRecords(
        glycemia,
        lowAlertThreshold: user.normalMinimumThreshold,
        highDangerThreshold: user.highDangerThreshold,
      );
      final report = ReportData(
        user: user,
        range: selectedRange,
        generatedAt: _now(),
        glycemia: chartData,
        insulinApplications: applications,
        meals: meals,
        hba1c: _hba1cCalculator.calculate(
          hba1cRecords.map((record) => record.value),
        ),
      );
      if (!report.hasRecords) {
        hasNoData = true;
        return;
      }
      data = report;
      pdfBytes = await _pdfService.generate(report);
      successMessage = 'Relatório gerado com sucesso.';
    } catch (_) {
      errorMessage = 'Não foi possível gerar o relatório. Tente novamente.';
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  void changePeriod(HistoryPeriod value) {
    period = value;
    if (value != HistoryPeriod.custom) customRange = null;
    data = null;
    pdfBytes = null;
    hasNoData = false;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<void> share() async {
    final bytes = pdfBytes;
    if (bytes == null) return;
    isSharing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final date = _now();
      await _shareService.share(
        bytes,
        'doce_equilibrio_${date.year}${_two(date.month)}${_two(date.day)}.pdf',
      );
    } catch (_) {
      errorMessage = 'Não foi possível compartilhar o relatório.';
    } finally {
      isSharing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _insulinController.dispose();
    super.dispose();
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
