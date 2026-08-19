import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_summary.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onAlternarFavorita;
  final VoidCallback? onUsarFavorita;

  const MealCard({
    super.key,
    required this.meal,
    required this.onEditar,
    required this.onExcluir,
    required this.onAlternarFavorita,
    this.onUsarFavorita,
  });

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final nomesItens = MealSummary.foodNames(meal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIcons.forkKnife,
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
                      meal.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${meal.dateTime.day.toString().padLeft(2, '0')}/'
                      '${meal.dateTime.month.toString().padLeft(2, '0')}/'
                      '${meal.dateTime.year} • '
                      '${meal.dateTime.hour.toString().padLeft(2, '0')}:'
                      '${meal.dateTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onAlternarFavorita,
                borderRadius: BorderRadius.circular(50),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    meal.favorite ? PhosphorIcons.starFill : PhosphorIcons.star,
                    color: meal.favorite
                        ? const Color(0xFFFFB300)
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nomesItens,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(meal.totalCarbohydrates)}g de carboidratos',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Row(
                children: [
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
            ],
          ),
          if (onUsarFavorita != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUsarFavorita,
                icon: const Icon(PhosphorIcons.copy, size: 18),
                label: const Text('Usar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
