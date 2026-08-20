import 'package:doce_equilibrio/features/activity/models/activity_intensity.dart';
import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantém exatamente as três intensidades oficiais', () {
    expect(ActivityIntensity.values.map((value) => value.label), [
      'Leve',
      'Moderada',
      'Intensa',
    ]);
  });

  test('registro legado sem intensidade continua válido', () {
    final activity = ActivityModel.fromMap({
      'id': 1,
      'usuarioId': 2,
      'tipo': 'caminhada',
      'duracaoMinutos': 30,
      'dataHora': '2026-08-20T10:00:00.000',
      'observacao': null,
    });

    expect(activity.intensidade, isNull);
    expect(activity.toMap()['intensidade'], isNull);
  });
}
