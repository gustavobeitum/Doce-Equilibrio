import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_application_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';

class ReportData {
  const ReportData({
    required this.user,
    required this.range,
    required this.generatedAt,
    required this.glycemia,
    required this.insulinApplications,
    required this.meals,
    required this.hba1c,
  });

  final UserModel user;
  final HistoryDateRange range;
  final DateTime generatedAt;
  final GlycemiaChartData glycemia;
  final List<InsulinApplicationModel> insulinApplications;
  final List<MealModel> meals;
  final HbA1cEstimate? hba1c;

  bool get hasRecords =>
      glycemia.records.isNotEmpty ||
      insulinApplications.isNotEmpty ||
      meals.isNotEmpty;
}
