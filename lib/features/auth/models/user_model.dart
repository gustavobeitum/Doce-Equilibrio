class UserModel {
  final int? id;
  final String name;
  final String email;
  final String diabetesType;
  final int diagnosisYear;
  final String password;
  final String salt;
  final double? weight;
  final int? height;

  final int normalMinimumThreshold;
  final int highDangerThreshold;

  // Parâmetros para o cálculo de insulina (RF-002 / UC-05, UC-06, UC-07).
  final double sensitivityFactor;
  final double correctionFactor;
  final int glycemiaTarget;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.diabetesType, 
    required this.diagnosisYear, 
    required this.password, 
    required this.salt, 
    this.weight, 
    this.height,  
    this.normalMinimumThreshold = 70, 
    this.highDangerThreshold = 180, 
    this.sensitivityFactor = 15, 
    this.correctionFactor = 20, 
    this.glycemiaTarget = 100, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': name,
      'email': email,
      'tipoDiabetes': diabetesType,
      'anoDiagnostico': diagnosisYear,
      'senha': password,
      'salt': salt,
      'peso': weight,
      'altura': height,
      'limiteNormalMinimo': normalMinimumThreshold,
      'limitePerigoAlto': highDangerThreshold,
      'fatorSensibilidade': sensitivityFactor,
      'fatorCorrecao': correctionFactor,
      'metaGlicemica': glycemiaTarget,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['nome'],
      email: map['email'],
      diabetesType: map['tipoDiabetes'],
      diagnosisYear: map['anoDiagnostico'],
      password: map['senha'],
      salt: map['salt'] as String? ?? '',
      weight: map['peso'] != null ? (map['peso'] as num).toDouble() : null,
      height: map['altura'] != null ? (map['altura'] as num).toInt() : null,
      normalMinimumThreshold:
          (map['limiteNormalMinimo'] as num?)?.toInt() ?? 70,
      highDangerThreshold: (map['limitePerigoAlto'] as num?)?.toInt() ?? 180,
      sensitivityFactor: (map['fatorSensibilidade'] as num?)?.toDouble() ?? 15,
      correctionFactor: (map['fatorCorrecao'] as num?)?.toDouble() ?? 20,
      glycemiaTarget: (map['metaGlicemica'] as num?)?.toInt() ?? 100,
    );
  }
}
