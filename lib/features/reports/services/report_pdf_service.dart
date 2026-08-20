import 'dart:typed_data';

import 'package:doce_equilibrio/features/glycemia/domain/services/glycemia_classifier.dart';
import 'package:doce_equilibrio/features/reports/models/report_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportPdfService {
  const ReportPdfService({this.compress = true});

  final bool compress;

  Future<Uint8List> generate(ReportData data) async {
    final document = pw.Document(
      compress: compress,
      title: 'Relatório de acompanhamento - Doce Equilíbrio',
      author: 'Doce Equilíbrio',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(
                'Doce Equilíbrio - Relatório de acompanhamento',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Gerado em ${_dateTime(data.generatedAt)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          pw.Text(
            'DOCE EQUILÍBRIO',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal700,
            ),
          ),
          pw.Text(
            'Relatório de acompanhamento',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 18),
          _section('Usuário e período'),
          pw.Text('Nome: ${data.user.name}'),
          pw.Text('Tipo de diabetes: ${data.user.diabetesType}'),
          pw.Text(
            'Período: ${_date(data.range.start)} a ${_date(data.range.end)}',
          ),
          pw.SizedBox(height: 16),
          _summary(data),
          pw.SizedBox(height: 18),
          _section('Gráficos glicêmicos'),
          ..._charts(data),
          pw.SizedBox(height: 18),
          ..._glycemiaTable(data),
          pw.SizedBox(height: 18),
          ..._insulinTable(data),
          pw.SizedBox(height: 18),
          ..._mealsTable(data),
          pw.SizedBox(height: 16),
          pw.Text(
            'A HbA1c apresentada é uma estimativa baseada nos registros disponíveis no aplicativo e não substitui exame laboratorial.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _summary(ReportData data) {
    final records = data.glycemia.records;
    final average = records.isEmpty
        ? null
        : records.fold<double>(0, (sum, item) => sum + item.value) /
              records.length;
    final min = records.isEmpty
        ? null
        : records.map((item) => item.value).reduce((a, b) => a < b ? a : b);
    final max = records.isEmpty
        ? null
        : records.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section('Resumo'),
        pw.Bullet(text: 'Registros glicêmicos: ${records.length}'),
        pw.Bullet(
          text:
              'Média glicêmica: ${average == null ? 'Sem dados' : '${_number(average)} mg/dL'}',
        ),
        pw.Bullet(
          text:
              'Mínimo / máximo: ${min == null ? 'Sem dados' : '$min / $max mg/dL'}',
        ),
        pw.Bullet(
          text:
              'HbA1c estimada (90 dias): ${data.hba1c == null ? 'Sem dados' : '${_number(data.hba1c!.percentage)}%'}',
        ),
        pw.Bullet(
          text: 'Aplicações de insulina: ${data.insulinApplications.length}',
        ),
        pw.Bullet(text: 'Refeições: ${data.meals.length}'),
      ],
    );
  }

  List<pw.Widget> _charts(ReportData data) {
    if (!data.glycemia.hasEnoughData) {
      return [
        pw.Text(
          'Dados insuficientes: são necessários ao menos dois registros para exibir os gráficos.',
        ),
      ];
    }
    final records = data.glycemia.records;
    final values = records.map((item) => item.value).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY--;
      maxY++;
    }
    final distribution = data.glycemia.distribution
        .where((item) => item.count > 0)
        .toList();
    return [
      pw.Text(
        'Evolução glicêmica (mg/dL)',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(
        height: 180,
        child: pw.Chart(
          grid: pw.CartesianGrid(
            xAxis: pw.FixedAxis<int>([
              0,
              records.length - 1,
            ], format: (value) => _date(records[value.toInt()].dateTime)),
            yAxis: pw.FixedAxis<int>([minY, maxY], divisions: true),
          ),
          datasets: [
            pw.LineDataSet<pw.PointChartValue>(
              data: [
                for (var index = 0; index < records.length; index++)
                  pw.PointChartValue(
                    index.toDouble(),
                    records[index].value.toDouble(),
                  ),
              ],
              color: PdfColors.teal700,
              drawSurface: true,
              isCurved: false,
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'Distribuição glicêmica',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(
        height: 180,
        child: pw.Chart(
          grid: pw.PieGrid(),
          datasets: distribution
              .map(
                (item) => pw.PieDataSet(
                  value: item.count,
                  legend: '${_level(item.level)} ${_number(item.percentage)}%',
                  color: _levelColor(item.level),
                  legendPosition: pw.PieLegendPosition.outside,
                ),
              )
              .toList(),
        ),
      ),
    ];
  }

  List<pw.Widget> _glycemiaTable(ReportData data) => _tableSection(
    'Registros glicêmicos',
    ['Data/hora', 'Glicemia', 'Período', 'Observação'],
    data.glycemia.records.reversed
        .map(
          (item) => [
            _dateTime(item.dateTime),
            '${item.value} mg/dL',
            item.period,
            item.notes ?? '-',
          ],
        )
        .toList(),
  );

  List<pw.Widget> _insulinTable(ReportData data) => _tableSection(
    'Aplicações de insulina',
    [
      'Data/hora',
      'Glicemia',
      'Carboidratos',
      'Recomendada',
      'Aplicada',
      'Observação',
    ],
    data.insulinApplications
        .map(
          (item) => [
            _dateTime(item.dateTime),
            '${item.glycemia}',
            '${_number(item.carbohydrates)} g',
            '${_number(item.recommendedDose)} UI',
            '${_number(item.appliedDose)} UI',
            item.observation ?? '-',
          ],
        )
        .toList(),
  );

  List<pw.Widget> _mealsTable(ReportData data) => _tableSection(
    'Refeições',
    ['Data/hora', 'Tipo', 'Alimentos', 'Carboidratos'],
    data.meals
        .map(
          (meal) => [
            _dateTime(meal.dateTime),
            meal.type.label,
            meal.items.isEmpty
                ? 'Não informados'
                : meal.items.map((item) => item.foodName).take(4).join(', '),
            '${_number(meal.totalCarbohydrates)} g',
          ],
        )
        .toList(),
  );

  List<pw.Widget> _tableSection(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) => [
    _section(title),
    if (rows.isEmpty)
      pw.Text('Nenhum registro no período.')
    else
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.all(4),
      ),
  ];

  pw.Widget _section(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.teal800,
      ),
    ),
  );

  PdfColor _levelColor(GlycemiaLevel level) => switch (level) {
    GlycemiaLevel.hypoglycemia => PdfColors.red600,
    GlycemiaLevel.normal => PdfColors.green600,
    GlycemiaLevel.hyperglycemia => PdfColors.amber700,
  };

  String _level(GlycemiaLevel level) => switch (level) {
    GlycemiaLevel.hypoglycemia => 'Hipoglicemia',
    GlycemiaLevel.normal => 'Normal',
    GlycemiaLevel.hyperglycemia => 'Hiperglicemia',
  };

  String _number(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
  String _date(DateTime value) =>
      '${_two(value.day)}/${_two(value.month)}/${value.year}';
  String _dateTime(DateTime value) =>
      '${_date(value)} ${_two(value.hour)}:${_two(value.minute)}';
  String _two(int value) => value.toString().padLeft(2, '0');
}
