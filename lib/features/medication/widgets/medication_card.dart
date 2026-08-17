import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medicamento;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const MedicationCard({
    super.key,
    required this.medicamento,
    required this.onEditar,
    required this.onExcluir,
  });

  String _formatDate(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIcons.pill,
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
                  medicamento.nome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  medicamento.dosagem,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(medicamento.dataHora),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (medicamento.observacao != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    medicamento.observacao!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
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
