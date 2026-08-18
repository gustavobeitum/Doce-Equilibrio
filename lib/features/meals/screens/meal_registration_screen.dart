import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/models/meal_item_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_model.dart';
import 'package:doce_equilibrio/features/meals/models/meal_type.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_food_selection_modal.dart';
import 'package:doce_equilibrio/features/meals/widgets/favorite_meal_selection_modal.dart';
import 'package:doce_equilibrio/features/meals/widgets/meal_item_quantity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MealRegistrationScreen extends StatefulWidget {
  final MealModel? existingMeal;
  final MealType? initialType;
  final List<MealItemModel> initialItems;

  const MealRegistrationScreen({
    super.key,
    this.existingMeal,
    this.initialType,
    this.initialItems = const [],
  });

  @override
  State<MealRegistrationScreen> createState() =>
      _RegistrarRefeicaoScreenState();
}

class _RegistrarRefeicaoScreenState extends State<MealRegistrationScreen> {
  late final MealController _controller;
  late MealType _selectedType;
  late DateTime _date;
  late TimeOfDay _time;
  late List<MealItemModel> _items;
  late bool _favorita;
  bool _isSaving = false;

  bool get _isEditing => widget.existingMeal != null;

  @override
  void initState() {
    super.initState();
    _controller = getIt<MealController>();
    final meal = widget.existingMeal;

    if (meal != null) {
      _selectedType = meal.type;
      _date = meal.dateTime;
      _time = TimeOfDay.fromDateTime(meal.dateTime);
      _items = List.from(meal.items);
      _favorita = meal.favorite;
    } else {
      final now = DateTime.now();
      _selectedType = widget.initialType ?? MealType.almoco;
      _date = now;
      _time = TimeOfDay.fromDateTime(now);
      _items = List.from(widget.initialItems);
      _favorita = false;
    }
  }

  double get _totalCarboidratos => _controller.totalCarbohydrates(_items);

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Future<void> _selectDate() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dataEscolhida != null) {
      setState(() => _date = dataEscolhida);
    }
  }

  Future<void> _selectTime() async {
    final horaEscolhida = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (horaEscolhida != null) {
      setState(() => _time = horaEscolhida);
    }
  }

  Future<void> _addFood() async {
    final item = await MealFoodSelectionModal.exibir(context);
    if (item != null) {
      setState(() => _items.add(item));
    }
  }

  Future<void> _useFavorite() async {
    final favorite = await FavoriteMealSelectionModal.show(
      context,
      _controller,
    );
    if (favorite == null || !mounted) return;

    if (_items.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Substituir alimentos?'),
          content: const Text(
            'Os alimentos adicionados serão substituídos pelos itens da '
            'refeição favorita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    setState(() {
      _selectedType = favorite.type;
      _items = _controller.reuseFavoriteItems(favorite);
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _editItemQuantity(int index) async {
    final item = _items[index];
    final quantity = await MealItemQuantityDialog.show(
      context,
      foodName: item.foodName,
      initialQuantity: item.quantityGrams,
    );
    if (quantity == null || !mounted) return;
    setState(() {
      _items[index] = item.copyWith(quantityGrams: quantity);
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um alimento à refeição.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final errorMessage = await _controller.save(
      id: widget.existingMeal?.id,
      type: _selectedType,
      dateTime: dateTime,
      items: _items,
      favorite: _favorita,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errorMessage == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  InputDecoration _fieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _circularIcon({required IconData icone, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, color: Colors.white, size: 22),
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              color: AppColors.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _circularIcon(
                    icone: PhosphorIcons.caretLeft,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'Editar Refeição' : 'Registrar Refeição',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Adicione os alimentos e a quantidade de cada um',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundColor,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Tipo de Refeição',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MealType>(
                      initialValue: _selectedType,
                      decoration: _fieldDecoration(),
                      items: MealType.values.map((type) {
                        return DropdownMenuItem<MealType>(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (type) {
                        if (type == null) return;
                        setState(() => _selectedType = type);
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _fieldDecoration(
                                    suffixIcon: const Icon(
                                      PhosphorIcons.calendarBlank,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  child: Text(
                                    '${_date.day.toString().padLeft(2, '0')}/'
                                    '${_date.month.toString().padLeft(2, '0')}/'
                                    '${_date.year}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectTime,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _fieldDecoration(
                                    suffixIcon: const Icon(
                                      PhosphorIcons.clock,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  child: Text(
                                    '${_time.hour.toString().padLeft(2, '0')}:'
                                    '${_time.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (!_isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('use-favorite-meal-button'),
                          onPressed: _useFavorite,
                          icon: const Icon(PhosphorIcons.star, size: 19),
                          label: const Text('Usar refeição favorita'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            foregroundColor: AppColors.primaryColor,
                            side: const BorderSide(
                              color: AppColors.primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Alimentos da Refeição',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addFood,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(PhosphorIcons.plus, size: 16),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              PhosphorIcons.bowlFood,
                              size: 36,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhum alimento adicionado ainda.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: List.generate(_items.length, (index) {
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.foodName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${_formatNumber(item.quantityGrams)}g • '
                                          '${_formatNumber(item.carbohydrates)}g carboidratos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _editItemQuantity(index),
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
                                        onTap: () => _removeItem(index),
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
                          }),
                        ),
                      ),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total de Carboidratos',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_formatNumber(_totalCarboidratos)}g',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _favorita,
                        onChanged: (value) => setState(() => _favorita = value),
                        activeTrackColor: AppColors.primaryColor,
                        title: const Text(
                          'Marcar como favorita',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Fica em destaque pra reaproveitar depois',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      key: const ValueKey('save-meal-button'),
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? 'Salvar Alterações'
                                  : 'Salvar Refeição',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
