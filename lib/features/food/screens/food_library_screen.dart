import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:doce_equilibrio/features/food/widgets/food_card.dart';
import 'package:doce_equilibrio/features/food/widgets/food_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _BibliotecaFoodsScreenState();
}

class _BibliotecaFoodsScreenState extends State<FoodLibraryScreen> {
  late final FoodController _controller;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<FoodModel> _foods = [];
  String _query = '';
  int _searchRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller = getIt<FoodController>();
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
    final foods = await _controller.search(_query);

    if (!mounted || revision != _searchRevision) return;
    setState(() {
      _foods = foods;
      _isLoading = false;
    });
  }

  Future<void> _searchFoods(String query) async {
    final revision = ++_searchRevision;
    final foods = await _controller.search(query);
    if (!mounted || revision != _searchRevision) return;
    setState(() {
      _query = query.trim();
      _foods = foods;
    });
  }

  Future<void> _openModal({FoodModel? existingFood}) async {
    final saved = await FoodModal.exibir(context, existingFood: existingFood);
    if (saved == true) {
      await _loadFoods();
    }
  }

  Future<void> _confirmDeletion(FoodModel food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Excluir Alimento'),
          content: Text(
            'Deseja realmente excluir "${food.name}" da sua biblioteca?',
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

    if (confirmed == true && food.id != null) {
      final deleted = await _controller.delete(food.id!);
      if (!mounted) return;

      if (deleted) {
        await _loadFoods();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o alimento.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
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
                        onRefresh: _loadFoods,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openModal(),
                              icon: const Icon(PhosphorIcons.plus, size: 18),
                              label: const Text('Novo Alimento'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              onChanged: _searchFoods,
                              decoration: InputDecoration(
                                hintText: 'Buscar alimento',
                                prefixIcon: const Icon(
                                  PhosphorIcons.magnifyingGlass,
                                ),
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
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_foods.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.bowlFood,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _query.isEmpty
                                          ? 'Nenhum alimento cadastrado.\nToque em "Novo Alimento" para começar.'
                                          : 'Nenhum alimento encontrado.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._foods.map(
                                (food) => FoodCard(
                                  food: food,
                                  onEditar: () =>
                                      _openModal(existingFood: food),
                                  onExcluir: () => _confirmDeletion(food),
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

      Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
    color: AppColors.primaryColor,
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(PhosphorIcons.caretLeft, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Icon(
          PhosphorIcons.bowlFood,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Meus Alimentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gerencie seus alimentos cadastrados',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
