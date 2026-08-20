import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/hba1c/domain/hba1c_calculator.dart';
import 'package:doce_equilibrio/features/home/models/weekly_glycemia_summary.dart';
import 'package:doce_equilibrio/features/home/widgets/home_dashboard_section.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final weekStart = DateTime(2026, 8, 17);

  test('calcula média, mínima e máxima sem arredondar antes da agregação', () {
    final summary = _summary([
      _record(100, weekStart),
      _record(101, weekStart.add(const Duration(days: 2))),
      _record(103, weekStart.add(const Duration(days: 5))),
    ]);

    expect(summary.averageMgDl, closeTo(101.333333, 0.000001));
    expect(summary.minimumMgDl, 100);
    expect(summary.maximumMgDl, 103);
  });

  testWidgets('mostra estados vazios sem inventar glicemias', (tester) async {
    await tester.pumpWidget(
      _app(weekStart: weekStart, estimate: null, summary: _summary([])),
    );

    expect(find.byKey(const Key('hba1c-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('weekly-empty-state')), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('mostra HbA1c e dados semanais reais', (tester) async {
    final summary = _summary([
      _record(70, weekStart),
      _record(131, weekStart.add(const Duration(days: 3))),
      _record(184, weekStart.add(const Duration(days: 6))),
    ]);

    await tester.pumpWidget(
      _app(
        weekStart: weekStart,
        estimate: const HbA1cEstimate(
          averageGlycemiaMgDl: 131,
          percentage: 6.2,
          recordCount: 16,
        ),
        summary: summary,
      ),
    );

    expect(find.text('6,2%'), findsOneWidget);
    expect(find.text('131,0 mg/dL'), findsOneWidget);
    expect(find.text('128,3 mg/dL'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.text('70 mg/dL'), findsOneWidget);
    expect(find.text('184 mg/dL'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('um registro mostra resumo, mas não desenha linha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        weekStart: weekStart,
        estimate: null,
        summary: _summary([_record(120, weekStart)]),
      ),
    );

    expect(find.byKey(const Key('weekly-single-record-state')), findsOneWidget);
    expect(find.text('120,0 mg/dL'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('ação discreta permite abrir relatório', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardSection(
            hba1cEstimate: null,
            weeklySummary: _summary([]),
            weekStart: weekStart,
            onExportReport: () => opened = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('export-report-button')));
    expect(opened, isTrue);
  });
}

Widget _app({
  required DateTime weekStart,
  required HbA1cEstimate? estimate,
  required WeeklyGlycemiaSummary summary,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: HomeDashboardSection(
          hba1cEstimate: estimate,
          weeklySummary: summary,
          weekStart: weekStart,
          onExportReport: () {},
        ),
      ),
    ),
  );
}

WeeklyGlycemiaSummary _summary(List<GlycemiaRecordModel> records) {
  return WeeklyGlycemiaSummary.fromChartData(
    GlycemiaChartData.fromRecords(
      records,
      lowAlertThreshold: 70,
      highDangerThreshold: 180,
    ),
  );
}

GlycemiaRecordModel _record(int value, DateTime dateTime) {
  return GlycemiaRecordModel(
    userId: 1,
    value: value,
    period: 'Outro',
    dateTime: dateTime,
  );
}
