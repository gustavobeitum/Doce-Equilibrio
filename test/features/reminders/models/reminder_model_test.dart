import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva vínculo e nome do medicamento ao ler consulta', () {
    final reminder = ReminderModel.fromMap({
      'id': 4,
      'usuarioId': 1,
      'tipo': 'medication',
      'titulo': 'Dose da manhã',
      'hora': 8,
      'minuto': 0,
      'repetir': 1,
      'diasSemana': '1,2,3,4,5',
      'data': null,
      'ativo': 1,
      'medicamentoId': 9,
      'medicamentoNome': 'Metformina',
    });

    expect(reminder.medicationId, 9);
    expect(reminder.medicationName, 'Metformina');
    expect(reminder.toMap()['medicamentoId'], 9);
  });

  test('aceita lembrete legado sem medicamento', () {
    final reminder = ReminderModel.fromMap({
      'id': 4,
      'usuarioId': 1,
      'tipo': 'medication',
      'titulo': 'Medicamento',
      'hora': 8,
      'minuto': 0,
      'repetir': 1,
      'diasSemana': '1',
      'data': null,
      'ativo': 1,
    });

    expect(reminder.medicationId, isNull);
    expect(reminder.medicationName, isNull);
  });
}
