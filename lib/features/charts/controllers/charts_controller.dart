import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/foundation.dart';

class ChartsController extends ChangeNotifier {
  ChartsController(this._glycemiaController, this._profileController);

  final GlycemiaController _glycemiaController;
  final ProfileController _profileController;

  HistoryPeriod period = HistoryPeriod.last30Days;
  HistoryDateRange? customRange;
  GlycemiaChartData? data;
  bool isLoading = false;
  String? errorMessage;

  HistoryDateRange get range => period == HistoryPeriod.custom
      ? customRange!
      : HistoryDateRange.forPeriod(period);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final selectedRange = range;
      final records = await _glycemiaController.listHistoryByPeriod(
        selectedRange.start,
        selectedRange.end,
      );
      final user = await _profileController.loadCurrentUser();
      if (user == null) throw StateError('Usuário não encontrado.');
      data = GlycemiaChartData.fromRecords(
        records,
        lowAlertThreshold: user.normalMinimumThreshold,
        highDangerThreshold: user.highDangerThreshold,
      );
    } catch (_) {
      data = null;
      errorMessage = 'Não foi possível carregar os gráficos deste período.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePeriod(
    HistoryPeriod value, {
    HistoryDateRange? range,
  }) async {
    if (value == HistoryPeriod.custom && range == null) {
      throw ArgumentError('Informe o período personalizado.');
    }
    period = value;
    customRange = range;
    await load();
  }
}
