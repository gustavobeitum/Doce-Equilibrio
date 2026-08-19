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
  final double servingQuantity;
  final String servingUnit;
  final double carbohydratesPerServing;
  final double consumedQuantity;

  const MealItemModel({
    this.id,
    this.mealId,
    required this.foodId,
    required this.foodName,
    double? servingQuantity,
    this.servingUnit = 'g',
    double? carbohydratesPerServing,
    double? consumedQuantity,
    double? carbohydratesPer100g,
    double? quantityGrams,
  }) : servingQuantity = servingQuantity ?? 100,
       carbohydratesPerServing =
           carbohydratesPerServing ?? carbohydratesPer100g ?? 0,
       consumedQuantity = consumedQuantity ?? quantityGrams ?? 0;

  double get quantityGrams => consumedQuantity;

  double get carbohydratesPer100g => servingUnit == 'g' && servingQuantity > 0
      ? (carbohydratesPerServing / servingQuantity) * 100
      : carbohydratesPerServing;

  /// Carboidratos deste item (RF-006 / UC-13): regra de três simples a
  /// partir do valor por 100g e da quantidade usada na refeição.
  double get carbohydrates => CarbohydrateCalculator.forItem(
    carbohydratesPerServing: carbohydratesPerServing,
    standardServing: servingQuantity,
    consumedQuantity: consumedQuantity,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'refeicaoId': mealId,
      'alimentoId': foodId,
      'nomeAlimento': foodName,
      'carboidratosPor100g': carbohydratesPer100g,
      'quantidadeGramas': consumedQuantity,
      'porcaoQuantidade': servingQuantity,
      'porcaoUnidade': servingUnit,
      'carboidratosPorPorcao': carbohydratesPerServing,
      'quantidadeConsumida': consumedQuantity,
    };
  }

  factory MealItemModel.fromMap(Map<String, dynamic> map) {
    return MealItemModel(
      id: map['id'],
      mealId: map['refeicaoId'],
      foodId: map['alimentoId'],
      foodName: map['nomeAlimento'],
      servingQuantity: (map['porcaoQuantidade'] as num?)?.toDouble() ?? 100,
      servingUnit: map['porcaoUnidade'] as String? ?? 'g',
      carbohydratesPerServing:
          (map['carboidratosPorPorcao'] as num?)?.toDouble() ??
          (map['carboidratosPor100g'] as num).toDouble(),
      consumedQuantity:
          (map['quantidadeConsumida'] as num?)?.toDouble() ??
          (map['quantidadeGramas'] as num).toDouble(),
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
      servingQuantity: servingQuantity,
      servingUnit: servingUnit,
      carbohydratesPerServing: carbohydratesPerServing,
      consumedQuantity: quantityGrams ?? consumedQuantity,
    );
  }
}
