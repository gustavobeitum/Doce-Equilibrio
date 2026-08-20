import 'package:doce_equilibrio/features/activity/models/activity_type.dart';
import 'package:doce_equilibrio/features/activity/models/activity_intensity.dart';

class ActivityModel {
  final int? id;
  final int usuarioId;
  final ActivityType tipo;
  final int duracaoMinutos;
  final DateTime dataHora;
  final ActivityIntensity? intensidade;
  final String? observacao;

  const ActivityModel({
    this.id,
    required this.usuarioId,
    required this.tipo,
    required this.duracaoMinutos,
    required this.dataHora,
    this.intensidade,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'tipo': tipo.name,
      'duracaoMinutos': duracaoMinutos,
      'dataHora': dataHora.toIso8601String(),
      'intensidade': intensidade?.label,
      'observacao': observacao,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      usuarioId: map['usuarioId'],
      tipo: ActivityType.fromValor(map['tipo']),
      duracaoMinutos: map['duracaoMinutos'],
      dataHora: DateTime.parse(map['dataHora']),
      intensidade: ActivityIntensity.fromValue(map['intensidade'] as String?),
      observacao: map['observacao'],
    );
  }
}
