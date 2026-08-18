import 'package:doce_equilibrio/features/meals/domain/services/carbohydrate_calculator.dart';

/// Um alimento dentro de uma refeição registrada, com a quantidade usada
/// e um retrato ("snapshot") do valor nutricional no momento do registro
/// — assim, se o usuário editar o alimento na biblioteca depois, o
/// histórico de refeições já registradas não muda de valor.
class MealItemModel {
  final int? id;
  final int? mealId;
  final int foodId;
  final String foodName;
  final double carbohydratesPer100g;
  final double quantityGrams;

  const MealItemModel({
    this.id,
    this.mealId,
    required this.foodId,
    required this.foodName,
    required this.carbohydratesPer100g,
    required this.quantityGrams,
  });

  /// Carboidratos deste item (RF-006 / UC-13): regra de três simples a
  /// partir do valor por 100g e da quantidade usada na refeição.
  double get carbohydrates => CarbohydrateCalculator.forItem(
    carbohydratesPerServing: carbohydratesPer100g,
    standardServing: 100,
    consumedQuantity: quantityGrams,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'refeicaoId': mealId,
      'alimentoId': foodId,
      'nomeAlimento': foodName,
      'carboidratosPor100g': carbohydratesPer100g,
      'quantidadeGramas': quantityGrams,
    };
  }

  factory MealItemModel.fromMap(Map<String, dynamic> map) {
    return MealItemModel(
      id: map['id'],
      mealId: map['refeicaoId'],
      foodId: map['alimentoId'],
      foodName: map['nomeAlimento'],
      carbohydratesPer100g: (map['carboidratosPor100g'] as num).toDouble(),
      quantityGrams: (map['quantidadeGramas'] as num).toDouble(),
    );
  }

  MealItemModel copyWith({
    int? id,
    int? mealId,
    double? quantityGrams,
    bool clearPersistenceIds = false,
  }) {
    return MealItemModel(
      id: clearPersistenceIds ? null : id ?? this.id,
      mealId: clearPersistenceIds ? null : mealId ?? this.mealId,
      foodId: foodId,
      foodName: foodName,
      carbohydratesPer100g: carbohydratesPer100g,
      quantityGrams: quantityGrams ?? this.quantityGrams,
    );
  }
}
