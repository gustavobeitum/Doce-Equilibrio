class UsuarioModel {
  final int? id;
  final String nome;
  final String email;
  final String tipoDiabetes;
  final int anoDiagnostico;
  final String senha;

  UsuarioModel({
    this.id,
    required this.nome,
    required this.email,
    required this.tipoDiabetes,
    required this.anoDiagnostico,
    required this.senha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipoDiabetes': tipoDiabetes,
      'anoDiagnostico': anoDiagnostico,
      'senha': senha,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      tipoDiabetes: map['tipoDiabetes'],
      anoDiagnostico: map['anoDiagnostico'],
      senha: map['senha'],
    );
  }
}

