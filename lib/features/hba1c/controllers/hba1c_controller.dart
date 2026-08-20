import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:flutter/foundation.dart';

class HbA1cController extends ChangeNotifier {
  HbA1cController(
    this._glycemiaController, {
    this._calculator = const HbA1cCalculator(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GlycemiaController _glycemiaController;
  final HbA1cCalculator _calculator;
  final DateTime Function() _now;

  HbA1cEstimate? estimate;
  HistoryDateRange? analyzedRange;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final range = HistoryDateRange.forPeriod(
        HistoryPeriod.last90Days,
        now: _now(),
      );
      final records = await _glycemiaController.listHistoryByPeriod(
        range.start,
        range.end,
      );
      analyzedRange = range;
      estimate = _calculator.calculate(records.map((record) => record.value));
    } catch (_) {
      analyzedRange = null;
      estimate = null;
      errorMessage = 'Não foi possível calcular a estimativa de HbA1c.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
