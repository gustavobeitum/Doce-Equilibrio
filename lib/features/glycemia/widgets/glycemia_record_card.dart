import 'package:doce_equilibrio/core/utils/glycemia_classification.dart';
import 'package:doce_equilibrio/core/utils/formatters.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class GlycemiaRecordCard extends StatelessWidget {
  final GlycemiaRecordModel record;
  final UserModel user;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const GlycemiaRecordCard({
    super.key,
    required this.record,
    required this.user,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final classification = GlycemiaClassification.classify(
      record.value,
      lowDangerThreshold: user.lowDangerThreshold,
      normalMinimumThreshold: user.normalMinimumThreshold,
      normalMaximumThreshold: user.normalMaximumThreshold,
      highDangerThreshold: user.highDangerThreshold,
    );

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: classification.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.drop,
              color: classification.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record.value}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'mg/dL',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: classification.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        classification.label,
                        style: TextStyle(
                          color: classification.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.dateTime(record.dateTime),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Período: ${record.period}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
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
              const SizedBox(height: 8),
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
    );
  }
}
