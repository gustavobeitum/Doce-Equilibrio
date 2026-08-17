import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/food/screens/food_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal de selecionar um alimento da biblioteca (UC-13). Ao tocar num
/// alimento, pede a quantidade e devolve um [RefeicaoItemModel] pronto
/// pra entrar na lista da refeição sendo montada.
class FoodSelectionModal extends StatefulWidget {
  const FoodSelectionModal({super.key});

  static Future<MealItemModel?> exibir(BuildContext context) {
    return showModalBottomSheet<MealItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FoodSelectionModal(),
    );
  }

  @override
  State<FoodSelectionModal> createState() => _SelecionarAlimentoModalState();
}

class _SelecionarAlimentoModalState extends State<FoodSelectionModal> {
  bool _isLoading = true;
  List<FoodModel> _foods = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    final foods = await getIt<FoodController>().list();
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _isLoading = false;
    });
  }

  Future<void> _openLibrary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodLibraryScreen()),
    );
    await _loadFoods();
  }

  Future<void> _select(FoodModel food) async {
    final quantityController = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    final quantity = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(food.name),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                final numero = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                if (numero == null || numero <= 0) {
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: Colors.grey.shade700,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(
                          context,
                          double.parse(
                            quantityController.text.replaceAll(',', '.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Adicionar'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              'Você ainda não tem alimentos cadastrados.',
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
                          return ListTile(
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
