import 'dart:convert';

import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/reports/models/report_data.dart';
import 'package:doce_equilibrio/features/reports/services/report_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ReportPdfService(compress: false);

  test('gera PDF válido e não vazio com os dados agregados', () async {
    final bytes = await service.generate(_report(4));
    final content = latin1.decode(bytes, allowInvalid: true);

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(content, isNot(contains('não deve aparecer')));
  });

  test('gera documento multipágina com muitos registros', () async {
    final bytes = await service.generate(_report(60));
    final content = latin1.decode(bytes, allowInvalid: true);
    final pages = RegExp(r'/Type\s*/Page\b').allMatches(content).length;

    expect(pages, greaterThan(1));
  });
}

ReportData _report(int count) {
  final records = List.generate(
    count,
    (index) => GlycemiaRecordModel(
      id: index + 1,
      userId: 7,
      value: 60 + index % 160,
      period: 'Jejum',
      dateTime: DateTime(2026, 8, 19).subtract(Duration(hours: index * 8)),
    ),
  );
  return ReportData(
    user: UserModel(
      id: 7,
      name: 'Pessoa de Teste',
      email: 'pessoa@teste.com',
      diabetesType: 'Tipo 1',
      diagnosisYear: 2020,
      password: 'não deve aparecer',
      salt: 'não deve aparecer',
    ),
    range: HistoryDateRange.forPeriod(
      HistoryPeriod.last30Days,
      now: DateTime(2026, 8, 19),
    ),
    generatedAt: DateTime(2026, 8, 19, 15),
    glycemia: GlycemiaChartData.fromRecords(
      records,
      lowAlertThreshold: 70,
      highDangerThreshold: 180,
    ),
    insulinApplications: const [],
    meals: const [],
    hba1c: const HbA1cCalculator().calculate(records.map((item) => item.value)),
  );
}
