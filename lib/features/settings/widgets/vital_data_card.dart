import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/profile/domain/services/bmi_calculator.dart';

class VitalDataCard extends StatelessWidget {
  final double? weight;
  final int? height;
  final VoidCallback? onEditPressed;

  const VitalDataCard({
    super.key,
    this.weight,
    this.height,
    this.onEditPressed,
  });

  String _calculateBmi() {
    if (weight == null || height == null || height == 0) return '--';

    final result = BmiCalculator.calculate(
      weightKg: weight!,
      heightMeters: height! / 100,
    );
    return result.value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIcons.scales,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Dados Vitais',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onEditPressed,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIcons.scales,
                  value: weight != null ? weight.toString() : '--',
                  label: 'Peso (kg)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIcons.ruler,
                  value: height != null ? height.toString() : '--',
                  label: 'Altura (cm)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIcons.activity,
                  value: _calculateBmi(),
                  label: 'IMC',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.1,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
