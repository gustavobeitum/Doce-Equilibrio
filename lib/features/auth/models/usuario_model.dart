class UsuarioModel {
  final int? id;
  final String nome;
  final String email;
  final String tipoDiabetes;
  final double peso;
  final double altura;
  final double imc;

  UsuarioModel({
    this.id,
    required this.nome,
    required this.email,
    required this.tipoDiabetes,
    required this.peso,
    required this.altura,
    required this.imc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipoDiabetes': tipoDiabetes,
      'peso': peso,
      'altura': altura,
      'imc': imc,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      tipoDiabetes: map['tipoDiabetes'],
      peso: map['peso'],
      altura: map['altura'],
      imc: map['imc'],
    );
  }
}