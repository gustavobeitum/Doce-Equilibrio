import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_food_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_item_quantity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal de selecionar um alimento da biblioteca (UC-13). Ao tocar num
/// alimento, pede a quantidade e devolve um [RefeicaoItemModel] pronto
/// pra entrar na lista da refeição sendo montada.
class MealFoodSelectionModal extends StatefulWidget {
  const MealFoodSelectionModal({super.key});

  static Future<MealItemModel?> exibir(BuildContext context) {
    return showModalBottomSheet<MealItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MealFoodSelectionModal(),
    );
  }

  @override
  State<MealFoodSelectionModal> createState() =>
      _SelecionarAlimentoModalState();
}

class _SelecionarAlimentoModalState extends State<MealFoodSelectionModal> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<FoodModel> _foods = [];
  String _query = '';
  int _searchRevision = 0;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    final revision = ++_searchRevision;
    final foods = await getIt<MealFoodController>().searchFoods(_query);
    if (!mounted || revision != _searchRevision) return;
    setState(() {
      _foods = foods;
      _isLoading = false;
    });
  }

  Future<void> _searchFoods(String query) async {
    final revision = ++_searchRevision;
    final foods = await getIt<MealFoodController>().searchFoods(query);
    if (!mounted || revision != _searchRevision) return;
    setState(() {
      _query = query.trim();
      _foods = foods;
    });
  }

  Future<void> _openLibrary() async {
    await getIt<MealFoodController>().openFoodLibrary(context);
    await _loadFoods();
  }

  Future<void> _select(FoodModel food) async {
    final quantity = await MealItemQuantityDialog.show(
      context,
      foodName: food.name,
      initialQuantity: 100,
    );

    if (quantity == null || !mounted) return;

    Navigator.pop(
      context,
      MealItemModel(
        foodId: food.id!,
        foodName: food.name,
        carbohydratesPer100g: food.carbohydratesPer100g,
        quantityGrams: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selecionar Alimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(PhosphorIcons.x, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _searchFoods,
                  decoration: InputDecoration(
                    hintText: 'Buscar alimento',
                    prefixIcon: const Icon(PhosphorIcons.magnifyingGlass),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _searchFoods('');
                            },
                            icon: const Icon(PhosphorIcons.x),
                          ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : _foods.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                PhosphorIcons.bowlFood,
                                size: 40,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _query.isEmpty
                                    ? 'Você ainda não tem alimentos cadastrados.'
                                    : 'Nenhum alimento encontrado.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _openLibrary,
                                icon: const Icon(PhosphorIcons.plus, size: 18),
                                label: const Text('Cadastrar Alimento'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                  side: const BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _foods.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey.shade200, height: 1),
                          itemBuilder: (context, index) {
                            final food = _foods[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${food.carbohydratesPer100g}g de carboidratos / 100g',
                                ),
                                trailing: const Icon(
                                  PhosphorIcons.plusCircle,
                                  color: AppColors.primaryColor,
                                ),
                                onTap: () => _select(food),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
