import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/custom_text_field.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _yearController;

  String? _selectedDiabetesType;
  bool _isLoading = false;

  final List<String> _tiposDiabetes = ['Tipo 1', 'Tipo 2', 'Gestacional'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
    _yearController = TextEditingController(
      text: widget.currentUser.diagnosisYear.toString(),
    );
    _selectedDiabetesType = widget.currentUser.diabetesType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedUser = UserModel(
        id: widget.currentUser.id,
        name: _nameController.text,
        email: _emailController.text,
        diabetesType: _selectedDiabetesType!,
        diagnosisYear: int.parse(_yearController.text),
        password: widget.currentUser.password,
        salt: widget.currentUser.salt,
        weight: widget.currentUser.weight,
        height: widget.currentUser.height,
        lowDangerThreshold: widget.currentUser.lowDangerThreshold,
        normalMinimumThreshold: widget.currentUser.normalMinimumThreshold,
        normalMaximumThreshold: widget.currentUser.normalMaximumThreshold,
        highDangerThreshold: widget.currentUser.highDangerThreshold,
        sensitivityFactor: widget.currentUser.sensitivityFactor,
        correctionFactor: widget.currentUser.correctionFactor,
        glycemiaTarget: widget.currentUser.glycemiaTarget,
      );

      await getIt<ProfileController>().updateProfile(updatedUser);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        leading: IconButton(
          icon: const Icon(PhosphorIcons.caretLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Nome Completo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome é obrigatório.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O email é obrigatório.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Email inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Tipo de Diabetes',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  initialValue: _selectedDiabetesType,
                  items: _tiposDiabetes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDiabetesType = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _yearController,
                  labelText: 'Ano do Diagnóstico',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Obrigatório.';
                    }
                    final year = int.tryParse(value);
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year) {
                      return 'Ano inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _salvarAlteracoes,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Salvar Alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
