import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_summary.dart';
import 'package:flutter/material.dart';

class MealImportModal extends StatelessWidget {
  const MealImportModal({
    super.key,
    required this.meals,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final List<MealModel> meals;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Importar refeição',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha uma refeição para importar seus carboidratos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Flexible(child: _content(context)),
        ],
      ),
    ),
  );

  Widget _content(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (meals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nenhuma refeição registrada.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: meals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(meal),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: MealSummary(meal: meal),
            ),
          ),
        );
      },
    );
  }
}
