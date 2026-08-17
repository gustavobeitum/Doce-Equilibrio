import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const FoodCard({
    super.key,
    required this.food,
    required this.onEditar,
    required this.onExcluir,
  });

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIcons.bowlFood,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatNumber(food.carbohydratesPer100g)}g de carboidratos / 100g',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEditar,
            borderRadius: BorderRadius.circular(50),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                PhosphorIcons.pencilSimple,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onExcluir,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                PhosphorIcons.trash,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
