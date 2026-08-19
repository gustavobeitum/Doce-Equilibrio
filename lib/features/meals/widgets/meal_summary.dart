import 'package:doce_equilibrio/core/utils/formatters.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:flutter/material.dart';

class MealSummary extends StatelessWidget {
  const MealSummary({super.key, required this.meal, this.maxFoodNames = 3});

  final MealModel meal;
  final int maxFoodNames;

  static String foodNames(MealModel meal, {int limit = 3}) {
    final names = meal.items
        .map((item) => item.foodName.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Alimentos não informados';
    final visible = names.take(limit).join(', ');
    final remaining = names.length - limit;
    return remaining > 0 ? '$visible +$remaining' : visible;
  }

  static String carbohydrates(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        meal.type.label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      const SizedBox(height: 3),
      Text(
        foodNames(meal, limit: maxFoodNames),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 3),
      Text(
        '${Formatters.date(meal.dateTime)} • ${Formatters.time(meal.dateTime)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 3),
      Text(
        '${carbohydrates(meal.totalCarbohydrates)} g de carboidratos',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  );
}
