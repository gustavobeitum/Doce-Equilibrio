import 'package:doce_equilibrio/features/settings/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/auth/screens/login_screen.dart';
import 'package:doce_equilibrio/features/settings/widgets/config_header.dart';
import 'package:doce_equilibrio/features/settings/widgets/vital_data_card.dart';
import 'package:doce_equilibrio/features/settings/widgets/glycemic_goals_card.dart';
import 'package:doce_equilibrio/features/settings/widgets/parameters_card.dart';
import 'package:doce_equilibrio/features/settings/widgets/alarms_card.dart';
import 'package:doce_equilibrio/features/settings/widgets/register_glycemia_card.dart';
import 'package:doce_equilibrio/features/settings/widgets/logout_card.dart';
import 'package:doce_equilibrio/features/glycemia/screens/glycemia_history_screen.dart';
import 'package:doce_equilibrio/features/settings/widgets/customize_glycemia_targets_modal.dart';
import 'package:doce_equilibrio/features/settings/widgets/edit_insulin_parameters_modal.dart';
import 'package:doce_equilibrio/features/reminders/screens/reminders_screen.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<SettingsScreen> {
  late final ProfileController _controller;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ProfileController>();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final foundUser = await _controller.loadCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = foundUser;
      _isLoading = false;
    });
  }

  Future<void> _abrirTelaEdicao() async {
    if (_user == null) return;

    final atualizou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _user!),
      ),
    );

    if (atualizou == true) {
      setState(() => _isLoading = true);
      await _carregarDadosUsuario();
    }
  }

  Future<void> _abrirEdicaoDadosVitais() async {
    if (_user == null) return;

    final weightController = TextEditingController(
      text: _user!.weight != null ? _user!.weight.toString() : '',
    );
    final heightController = TextEditingController(
      text: _user!.height != null ? _user!.height.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final atualizou = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundColor,
              title: const Text('Editar Dados Vitais'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Peso (kg)',
                        hintText: 'Ex: 70.5',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o peso';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Altura (cm)',
                        hintText: 'Ex: 175',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a altura';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: Colors.grey.shade700,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setStateDialog(() => isSaving = true);

                                  final formattedWeight = double.parse(
                                    weightController.text.replaceAll(',', '.'),
                                  );

                                  final formattedHeight = int.parse(
                                    heightController.text,
                                  );

                                  await _controller.updateVitalData(
                                    currentUser: _user!,
                                    weight: formattedWeight,
                                    height: formattedHeight,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Salvar',
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
      },
    );

    if (atualizou == true) {
      setState(() => _isLoading = true);
      await _carregarDadosUsuario();
    }
  }

  void _abrirLembretes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersScreen()),
    );
  }

  void _abrirHistoricoGlicemia() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GlycemiaHistoryScreen()),
    );
  }

  Future<void> _abrirModalMetas() async {
    if (_user == null) return;

    final saved = await CustomizeGlycemiaTargetsModal.exibir(
      context,
      currentUser: _user!,
    );

    if (saved == true) {
      setState(() => _isLoading = true);
      await _carregarDadosUsuario();
    }
  }

  Future<void> _abrirModalParametros() async {
    if (_user == null) return;

    final saved = await EditInsulinParametersModal.exibir(
      context,
      currentUser: _user!,
    );

    if (saved == true) {
      setState(() => _isLoading = true);
      await _carregarDadosUsuario();
    }
  }

  Future<void> _confirmarLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text('Sair da Conta'),
          content: const Text(
            'Tem certeza que deseja sair? Você precisará fazer login novamente para acessar o aplicativo.',
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
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Sair',
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

    if (confirmed == true) {
      await _realizarLogout();
    }
  }

  Future<void> _realizarLogout() async {
    await _controller.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Container(
          color: AppColors.backgroundColor,
          height: double.infinity,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_user != null)
                        ConfigHeader(
                          currentUser: _user!,
                          name: _user!.name,
                          email: _user!.email,
                          detalhesDiabetes:
                              '${_user!.diabetesType} - Desde ${_user!.diagnosisYear}',
                          onEdit: _abrirTelaEdicao,
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            VitalDataCard(
                              weight: _user?.weight,
                              height: _user?.height,
                              onEditPressed: _abrirEdicaoDadosVitais,
                            ),
                            SizedBox(height: 16),
                            GlycemicGoalsCard(
                              user: _user!,
                              onPersonalizar: _abrirModalMetas,
                            ),
                            SizedBox(height: 16),
                            ParametersCard(
                              user: _user!,
                              onEditar: _abrirModalParametros,
                            ),
                            SizedBox(height: 16),
                            AlarmsCard(onTap: _abrirLembretes),
                            SizedBox(height: 16),
                            RegisterGlycemiaCard(
                              onTap: _abrirHistoricoGlicemia,
                            ),
                            SizedBox(height: 16),
                            LogoutCard(onTap: _confirmarLogout),
                            SizedBox(height: 32),
                          ],
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
