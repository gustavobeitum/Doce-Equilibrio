import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';

/// Um lembrete/alarme configurado pelo usuário (UC-17).
///
/// Pode ser de dois tipos:
/// - Repetição semanal ([repetir] = `true`): dispara toda semana nos dias
///   marcados em [diasSemana] (convenção do `DateTime.weekday`: 1 =
///   segunda-feira ... 7 = domingo). [data] fica `null`.
/// - Disparo único ([repetir] = `false`): dispara uma única vez em [data],
///   como um alarme de celular configurado "uma vez só" — depois de
///   disparar, não volta a repetir. [diasSemana] fica vazio.
class ReminderModel {
  final int? id;
  final int userId;
  final ReminderType type;
  final String title;
  final int time;
  final int minute;
  final bool repeat;
  final List<int> weekdays;
  final DateTime? date;
  final bool active;
  final int? medicationId;
  final String? medicationName;

  const ReminderModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.time,
    required this.minute,
    required this.repeat,
    this.weekdays = const [],
    this.date,
    this.active = true,
    this.medicationId,
    this.medicationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': userId,
      'tipo': type.name,
      'titulo': title,
      'hora': time,
      'minuto': minute,
      'repetir': repeat ? 1 : 0,
      'diasSemana': weekdays.join(','),
      'data': date?.toIso8601String(),
      'ativo': active ? 1 : 0,
      'medicamentoId': medicationId,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      userId: map['usuarioId'],
      type: ReminderType.fromValor(map['tipo']),
      title: map['titulo'],
      time: map['hora'],
      minute: map['minuto'],
      repeat: (map['repetir'] as int) == 1,
      weekdays: (map['diasSemana'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList(),
      date: map['data'] != null ? DateTime.parse(map['data']) : null,
      active: (map['ativo'] as int) == 1,
      medicationId: map['medicamentoId'] as int?,
      medicationName: map['medicamentoNome'] as String?,
    );
  }

  /// Cria uma cópia trocando só o que for informado — usado principalmente
  /// pelo switch de ativar/desativar rápido na listagem.
  ReminderModel copyWith({
    int? id,
    ReminderType? type,
    String? title,
    int? time,
    int? minute,
    bool? repeat,
    List<int>? weekdays,
    DateTime? date,
    bool? active,
    int? medicationId,
    bool clearMedication = false,
    String? medicationName,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      weekdays: weekdays ?? this.weekdays,
      date: date ?? this.date,
      active: active ?? this.active,
      medicationId: clearMedication ? null : medicationId ?? this.medicationId,
      medicationName: clearMedication
          ? null
          : medicationName ?? this.medicationName,
    );
  }
}
