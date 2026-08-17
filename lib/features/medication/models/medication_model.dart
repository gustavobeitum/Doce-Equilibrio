class MedicationModel {
  final int? id;
  final int usuarioId;
  final String nome;
  final String dosagem;
  final DateTime dataHora;
  final String? observacao;

  const MedicationModel({
    this.id,
    required this.usuarioId,
    required this.nome,
    required this.dosagem,
    required this.dataHora,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'nome': nome,
      'dosagem': dosagem,
      'dataHora': dataHora.toIso8601String(),
      'observacao': observacao,
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'],
      usuarioId: map['usuarioId'],
      nome: map['nome'],
      dosagem: map['dosagem'],
      dataHora: DateTime.parse(map['dataHora']),
      observacao: map['observacao'],
    );
  }
}
