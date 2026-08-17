import 'package:doce_equilibrio/core/utils/glycemia_classification.dart';
import 'package:doce_equilibrio/core/utils/formatters.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:flutter/material.dart';

class LastReadingCard extends StatelessWidget {
  final GlycemiaRecordModel? latestReading;
  final UserModel? user;

  const LastReadingCard({super.key, this.latestReading, this.user});

  @override
  Widget build(BuildContext context) {
    final record = latestReading;

    if (record == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.water_drop_outlined,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nenhuma leitura registrada ainda. Toque em "Registrar Glicemia" para começar.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final classification = GlycemiaClassification.classify(
      record.value,
      lowDangerThreshold: user?.lowDangerThreshold ?? 50,
      normalMinimumThreshold: user?.normalMinimumThreshold ?? 70,
      normalMaximumThreshold: user?.normalMaximumThreshold ?? 140,
      highDangerThreshold: user?.highDangerThreshold ?? 180,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Última leitura • ${Formatters.time(record.dateTime)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: classification.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  classification.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${record.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'mg/dL',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            'Meta: ${user?.normalMinimumThreshold ?? 70} - '
            '${user?.normalMaximumThreshold ?? 140} mg/dL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
