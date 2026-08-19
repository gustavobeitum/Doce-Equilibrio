import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/modal_feedback_message.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/material.dart';

class EditVitalDataDialog extends StatefulWidget {
  const EditVitalDataDialog({
    super.key,
    required this.currentUser,
    required this.controller,
  });

  final UserModel currentUser;
  final ProfileController controller;

  static Future<bool?> show(
    BuildContext context, {
    required UserModel currentUser,
    required ProfileController controller,
  }) => showDialog<bool>(
    context: context,
    builder: (_) =>
        EditVitalDataDialog(currentUser: currentUser, controller: controller),
  );

  @override
  State<EditVitalDataDialog> createState() => _EditVitalDataDialogState();
}

class _EditVitalDataDialogState extends State<EditVitalDataDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.currentUser.weight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.currentUser.height?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.controller.updateVitalData(
        currentUser: widget.currentUser,
        weight: double.parse(_weightController.text.replaceAll(',', '.')),
        height: int.parse(_heightController.text),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Não foi possível salvar os dados. Tente novamente.';
      });
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.backgroundColor,
    title: const Text('Editar Dados Vitais'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration('Peso (kg)', 'Ex: 70,5'),
            validator: (value) =>
                value == null ||
                    double.tryParse(value.replaceAll(',', '.')) == null
                ? 'Informe um peso válido'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: _decoration('Altura (cm)', 'Ex: 175'),
            validator: (value) => value == null || int.tryParse(value) == null
                ? 'Informe uma altura válida'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            ModalFeedbackMessage(message: _error!),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Salvar'),
      ),
    ],
  );
}
