import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ModalFeedbackMessage extends StatelessWidget {
  final String message;

  const ModalFeedbackMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('modal-feedback-message'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.dangerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.dangerColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
