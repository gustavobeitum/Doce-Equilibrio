import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_food_controller.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/screens/meal_registration_screen.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  late final MealController _controller;

  bool _isLoading = true;
  List<MealModel> _meals = [];

  @override
  void initState() {
    super.initState();
    _controller = getIt<MealController>();
    _carregarRefeicoes();
  }

  Future<void> _carregarRefeicoes() async {
    setState(() => _isLoading = true);
    final meals = await _controller.list();

    if (!mounted) return;
    setState(() {
      _meals = meals;
      _isLoading = false;
    });
  }

  Future<void> _abrirRegistrarRefeicao({
    MealModel? existingMeal,
    MealModel? favoriteTemplate,
  }) async {
    final initialItems = favoriteTemplate == null
        ? const <MealItemModel>[]
        : _controller.reuseFavoriteItems(favoriteTemplate);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MealRegistrationScreen(
          existingMeal: existingMeal,
          initialType: favoriteTemplate?.type,
          initialItems: initialItems,
        ),
      ),
    );
    if (saved == true) {
      await _carregarRefeicoes();
    }
  }

  Future<void> _useFavorite(MealModel meal) {
    return _abrirRegistrarRefeicao(favoriteTemplate: meal);
  }

  Future<void> _openLibrary() async {
    await getIt<MealFoodController>().openFoodLibrary(context);
    // A biblioteca não muda as refeições já registradas (o valor é um
    // retrato do momento do registro), então não precisa recarregar aqui.
  }

  Future<void> _alternarFavorita(MealModel meal) async {
    setState(() {
      final index = _meals.indexWhere((r) => r.id == meal.id);
      if (index != -1) {
        _meals[index] = meal.copyWith(favorite: !meal.favorite);
      }
    });

    final updated =
        meal.id != null &&
        await _controller.setFavorite(meal.id!, !meal.favorite);

    if (!updated) {
      await _carregarRefeicoes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar a refeição.')),
      );
    }
  }

  Future<void> _confirmDeletion(MealModel meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Excluir Refeição'),
          content: Text(
            'Deseja realmente excluir esta refeição (${meal.type.label})?',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: Colors.grey.shade700,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.dangerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Excluir',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && meal.id != null) {
      final deleted = await _controller.delete(meal.id!);
      if (!mounted) return;

      if (deleted) {
        await _carregarRefeicoes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a refeição.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              color: AppColors.primaryColor,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      PhosphorIcons.forkKnife,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alimentos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Registre suas refeições',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundColor,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: _carregarRefeicoes,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _abrirRegistrarRefeicao(),
                              icon: const Icon(PhosphorIcons.plus, size: 18),
                              label: const Text('Registrar Refeição'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _openLibrary,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          PhosphorIcons.bowlFood,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Meus Alimentos',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              'Gerenciar sua biblioteca',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        PhosphorIcons.caretRight,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_meals.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.forkKnife,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nenhuma refeição registrada.\nToque em "Registrar Refeição" para começar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._meals.map(
                                (meal) => MealCard(
                                  meal: meal,
                                  onEditar: () => _abrirRegistrarRefeicao(
                                    existingMeal: meal,
                                  ),
                                  onExcluir: () => _confirmDeletion(meal),
                                  onAlternarFavorita: () =>
                                      _alternarFavorita(meal),
                                  onUsarFavorita: meal.favorite
                                      ? () => _useFavorite(meal)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
