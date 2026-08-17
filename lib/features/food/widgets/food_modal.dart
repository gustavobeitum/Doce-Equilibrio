import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal de criar/editar um alimento da biblioteca (UC-11).
class FoodModal extends StatefulWidget {
  final FoodModel? existingFood;

  const FoodModal({super.key, this.existingFood});

  /// Abre o modal. Retorna `true` se o alimento foi criado/atualizado.
  static Future<bool?> exibir(BuildContext context, {FoodModel? existingFood}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodModal(existingFood: existingFood),
    );
  }

  @override
  State<FoodModal> createState() => _AlimentoModalState();
}

class _AlimentoModalState extends State<FoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _carbohydratesController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.existingFood != null;

  @override
  void initState() {
    super.initState();
    final food = widget.existingFood;
    if (food != null) {
      _nameController.text = food.name;
      _carbohydratesController.text = _formatNumber(food.carbohydratesPer100g);
    }
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carbohydratesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos obrigatórios antes de salvar.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final controller = getIt<FoodController>();
    final errorMessage = await controller.save(
      id: widget.existingFood?.id,
      name: _nameController.text,
      carbohydratesPer100g: double.parse(
        _carbohydratesController.text.replaceAll(',', '.'),
      ),
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

  InputDecoration _fieldDecoration({String? hintText, String? sufixo}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      suffixText: sufixo,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dangerColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dangerColor, width: 2),
      ),
      errorStyle: const TextStyle(
        color: AppColors.dangerColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditing ? 'Editar Alimento' : 'Novo Alimento',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context, false),
                          borderRadius: BorderRadius.circular(50),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(PhosphorIcons.x, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Nome do Alimento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration(
                        hintText: 'Ex: Arroz branco',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do alimento.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Carboidratos por 100g',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Consulte a tabela nutricional da embalagem.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _carbohydratesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        hintText: 'Ex: 28',
                        sufixo: 'g',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe um valor.';
                        }
                        final numero = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        if (numero == null || numero < 0) {
                          return 'Informe um valor válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
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
                                  : 'Salvar Alimento',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
