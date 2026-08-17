class GlycemiaRecordModel {
  final int? id;
  final int userId;
  final int value;
  final String period;
  final DateTime dateTime;
  final String? notes;

  const GlycemiaRecordModel({
    this.id,
    required this.userId,
    required this.value,
    required this.period,
    required this.dateTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': userId,
      'valor': value,
      'periodo': period,
      'dataHora': dateTime.toIso8601String(),
      'observacao': notes,
    };
  }

  factory GlycemiaRecordModel.fromMap(Map<String, dynamic> map) {
    return GlycemiaRecordModel(
      id: map['id'],
      userId: map['usuarioId'],
      value: map['valor'],
      period: map['periodo'],
      dateTime: DateTime.parse(map['dataHora']),
      notes: map['observacao'],
    );
  }
}
