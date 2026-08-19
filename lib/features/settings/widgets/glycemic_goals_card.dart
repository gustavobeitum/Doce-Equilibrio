import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';

class GlycemicGoalsCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onPersonalizar;

  const GlycemicGoalsCard({
    super.key,
    required this.user,
    required this.onPersonalizar,
  });

  static const Color _colorHypoglycemia = Color(0xFFE53935);
  static const Color _colorHyperglycemia = Color(0xFFFFB300);
  static const Color _colorNormal = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // 1. Cabeçalho do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIcons.target,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Metas Glicêmicas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onPersonalizar,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Personalizar',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildLegendItem(
            _colorHypoglycemia,
            'Hipoglicemia: <${user.normalMinimumThreshold} mg/dL',
          ),
          _buildLegendItem(
            _colorNormal,
            'Normal: ${user.normalMinimumThreshold} - '
            '${user.highDangerThreshold} mg/dL',
          ),
          _buildLegendItem(
            _colorHyperglycemia,
            'Hiperglicemia: >${user.highDangerThreshold} mg/dL',
          ),

          const SizedBox(height: 24),

          Container(
            height: 24,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _buildBarSegment(
                  flex: 2,
                  color: _colorHypoglycemia,
                  label: '<${user.normalMinimumThreshold}',
                ),
                _buildBarSegment(
                  flex: 6,
                  color: _colorNormal,
                  label:
                      '${user.normalMinimumThreshold}-'
                      '${user.highDangerThreshold}',
                ),
                _buildBarSegment(
                  flex: 2,
                  color: _colorHyperglycemia,
                  label: '>${user.highDangerThreshold}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarSegment({
    required int flex,
    required Color color,
    required String label,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        color: color,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
