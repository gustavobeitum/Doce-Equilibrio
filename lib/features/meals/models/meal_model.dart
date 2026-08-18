import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/domain/services/carbohydrate_calculator.dart';

/// Uma refeição registrada (UC-12), com os alimentos que a compõem.
/// Pode ser marcada como favorita (UC-14) pra ser reutilizada depois.
class MealModel {
  final int? id;
  final int userId;
  final MealType type;
  final DateTime dateTime;
  final bool favorite;
  final List<MealItemModel> items;

  const MealModel({
    this.id,
    required this.userId,
    required this.type,
    required this.dateTime,
    this.favorite = false,
    this.items = const [],
  });

  /// Total de carboidratos da refeição (RF-006 / UC-13): soma dos itens.
  double get totalCarbohydrates {
    return CarbohydrateCalculator.total(
      items.map((item) => item.carbohydrates),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': userId,
      'tipo': type.name,
      'dataHora': dateTime.toIso8601String(),
      'favorita': favorite ? 1 : 0,
    };
  }

  factory MealModel.fromMap(
    Map<String, dynamic> map, {
    List<MealItemModel> items = const [],
  }) {
    return MealModel(
      id: map['id'],
      userId: map['usuarioId'],
      type: MealType.fromValor(map['tipo']),
      dateTime: DateTime.parse(map['dataHora']),
      favorite: (map['favorita'] as int) == 1,
      items: items,
    );
  }

  MealModel copyWith({List<MealItemModel>? items, bool? favorite}) {
    return MealModel(
      id: id,
      userId: userId,
      type: type,
      dateTime: dateTime,
      favorite: favorite ?? this.favorite,
      items: items ?? this.items,
    );
  }
}
