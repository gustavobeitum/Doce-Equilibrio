class InsulinApplicationModel {
  final int? id;
  final int userId;
  final int glycemia;
  final double carbohydrates;
  final double carbohydrateDose;
  final double correctionDose;
  final double recommendedDose;
  final double appliedDose;
  final DateTime dateTime;
  final String? observation;
  final int? mealId;

  const InsulinApplicationModel({
    this.id,
    required this.userId,
    required this.glycemia,
    required this.carbohydrates,
    required this.carbohydrateDose,
    required this.correctionDose,
    required this.recommendedDose,
    required this.appliedDose,
    required this.dateTime,
    this.observation,
    this.mealId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuarioId': userId,
    'glicemia': glycemia,
    'carboidratos': carbohydrates,
    'doseAlimentar': carbohydrateDose,
    'doseCorrecao': correctionDose,
    'doseRecomendada': recommendedDose,
    'doseAplicada': appliedDose,
    'dataHora': dateTime.toIso8601String(),
    'observacao': observation,
    'refeicaoId': mealId,
  };

  factory InsulinApplicationModel.fromMap(Map<String, dynamic> map) {
    return InsulinApplicationModel(
      id: map['id'] as int?,
      userId: map['usuarioId'] as int,
      glycemia: map['glicemia'] as int,
      carbohydrates: (map['carboidratos'] as num).toDouble(),
      carbohydrateDose: (map['doseAlimentar'] as num).toDouble(),
      correctionDose: (map['doseCorrecao'] as num).toDouble(),
      recommendedDose: (map['doseRecomendada'] as num).toDouble(),
      appliedDose: (map['doseAplicada'] as num).toDouble(),
      dateTime: DateTime.parse(map['dataHora'] as String),
      observation: map['observacao'] as String?,
      mealId: map['refeicaoId'] as int?,
    );
  }
}
