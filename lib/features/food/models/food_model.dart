/// Um alimento cadastrado pelo usuário na sua biblioteca (UC-11), com a
/// informação nutricional necessária pra calcular carboidratos (RF-005).
class FoodModel {
  final int? id;
  final int userId;
  final String name;
  final double servingQuantity;
  final String servingUnit;
  final double carbohydratesPerServing;

  const FoodModel({
    this.id,
    required this.userId,
    required this.name,
    this.servingQuantity = 100,
    this.servingUnit = 'g',
    double? carbohydratesPerServing,
    double? carbohydratesPer100g,
  }) : carbohydratesPerServing =
           carbohydratesPerServing ?? carbohydratesPer100g ?? 0;

  double get carbohydratesPer100g => servingUnit == 'g' && servingQuantity > 0
      ? (carbohydratesPerServing / servingQuantity) * 100
      : carbohydratesPerServing;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': userId,
      'nome': name,
      'carboidratosPor100g': carbohydratesPer100g,
      'porcaoQuantidade': servingQuantity,
      'porcaoUnidade': servingUnit,
      'carboidratosPorPorcao': carbohydratesPerServing,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'],
      userId: map['usuarioId'],
      name: map['nome'],
      servingQuantity: (map['porcaoQuantidade'] as num?)?.toDouble() ?? 100,
      servingUnit: map['porcaoUnidade'] as String? ?? 'g',
      carbohydratesPerServing:
          (map['carboidratosPorPorcao'] as num?)?.toDouble() ??
          (map['carboidratosPor100g'] as num).toDouble(),
    );
  }
}
