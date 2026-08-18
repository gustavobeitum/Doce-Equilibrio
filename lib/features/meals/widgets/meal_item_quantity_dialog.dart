import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class MealItemQuantityDialog {
  static Future<double?> show(
    BuildContext context, {
    required String foodName,
    required double initialQuantity,
  }) {
    var quantityText = initialQuantity == initialQuantity.roundToDouble()
        ? initialQuantity.toInt().toString()
        : initialQuantity.toString();
    final formKey = GlobalKey<FormState>();

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(foodName),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: quantityText,
            onChanged: (value) => quantityText = value,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantidade',
              suffixText: 'g',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              final number = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              if (number == null || number <= 0) {
                return 'Informe uma quantidade válida.';
              }
              return null;
            },
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      double.parse(quantityText.replaceAll(',', '.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
