/// Um alimento cadastrado pelo usuário na sua biblioteca (UC-11), com a
/// informação nutricional necessária pra calcular carboidratos (RF-005).
class FoodModel {
  final int? id;
  final int userId;
  final String name;
  final double carbohydratesPer100g;

  const FoodModel({
    this.id,
    required this.userId,
    required this.name,
    required this.carbohydratesPer100g,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': userId,
      'nome': name,
      'carboidratosPor100g': carbohydratesPer100g,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'],
      userId: map['usuarioId'],
      name: map['nome'],
      carbohydratesPer100g: (map['carboidratosPor100g'] as num).toDouble(),
    );
  }
}
