import 'package:doce_equilibrio/features/charts/domain/glycemia_chart_data.dart';
import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlycemiaChartData', () {
    test('representa nenhum registro como vazio e dados insuficientes', () {
      final data = _build(const []);

      expect(data.isEmpty, isTrue);
      expect(data.hasEnoughData, isFalse);
      expect(data.distribution.map((item) => item.count), [0, 0, 0]);
    });

    test('um registro continua insuficiente para os gráficos', () {
      final data = _build([_record(100, DateTime(2026, 8, 10))]);

      expect(data.isEmpty, isFalse);
      expect(data.hasEnoughData, isFalse);
    });

    test('ordena múltiplos registros cronologicamente sem alterar valores', () {
      final data = _build([
        _record(181, DateTime(2026, 8, 3)),
        _record(69, DateTime(2026, 8, 1)),
        _record(100, DateTime(2026, 8, 2)),
      ]);

      expect(data.hasEnoughData, isTrue);
      expect(data.records.map((record) => record.value), [69, 100, 181]);
    });

    test('usa domínio atual nos limites e calcula distribuição', () {
      final data = _build([
        _record(69, DateTime(2026, 8, 1)),
        _record(70, DateTime(2026, 8, 2)),
        _record(180, DateTime(2026, 8, 3)),
        _record(181, DateTime(2026, 8, 4)),
      ]);

      expect(_item(data, GlycemiaLevel.hypoglycemia).count, 1);
      expect(_item(data, GlycemiaLevel.normal).count, 2);
      expect(_item(data, GlycemiaLevel.hyperglycemia).count, 1);
      expect(_item(data, GlycemiaLevel.hypoglycemia).percentage, 25);
      expect(_item(data, GlycemiaLevel.normal).percentage, 50);
      expect(_item(data, GlycemiaLevel.hyperglycemia).percentage, 25);
      expect(
        data.distribution.fold<double>(0, (sum, item) => sum + item.percentage),
        closeTo(100, 0.000001),
      );
    });

    test('respeita limites personalizados sem duplicar classificação', () {
      final data = GlycemiaChartData.fromRecords(
        [
          _record(79, DateTime(2026, 8, 1)),
          _record(80, DateTime(2026, 8, 2)),
          _record(151, DateTime(2026, 8, 3)),
        ],
        lowAlertThreshold: 80,
        highDangerThreshold: 150,
      );

      expect(_item(data, GlycemiaLevel.hypoglycemia).count, 1);
      expect(_item(data, GlycemiaLevel.normal).count, 1);
      expect(_item(data, GlycemiaLevel.hyperglycemia).count, 1);
    });
  });
}

GlycemiaChartData _build(List<GlycemiaRecordModel> records) =>
    GlycemiaChartData.fromRecords(
      records,
      lowAlertThreshold: 70,
      highDangerThreshold: 180,
    );

GlycemiaDistributionItem _item(GlycemiaChartData data, GlycemiaLevel level) =>
    data.distribution.singleWhere((item) => item.level == level);

GlycemiaRecordModel _record(int value, DateTime dateTime) =>
    GlycemiaRecordModel(
      userId: 7,
      value: value,
      period: 'Antes da refeição',
      dateTime: dateTime,
    );
