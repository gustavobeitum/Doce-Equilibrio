import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_calculation_controller.dart';
import 'package:doce_equilibrio/features/insulin/models/insulin_calculation_result.dart';
import 'package:doce_equilibrio/features/settings/widgets/edit_insulin_parameters_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class InsulinCalculatorScreen extends StatefulWidget {
  const InsulinCalculatorScreen({super.key});

  @override
  State<InsulinCalculatorScreen> createState() =>
      _InsulinCalculatorScreenState();
}

class _InsulinCalculatorScreenState extends State<InsulinCalculatorScreen> {
  final _glycemiaController = TextEditingController();
  final _carbohydratesController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  InsulinCalculationResult? _resultado;
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _glycemiaController.dispose();
    _carbohydratesController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);

    final userId = await getIt<SessionService>().getCurrentUserId();
    UserModel? user;

    if (userId != null) {
      user = await getIt<UserRepositoryInterface>().find(userId);
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _openEditParameters() async {
    if (_user == null) return;

    final saved = await EditInsulinParametersModal.exibir(
      context,
      currentUser: _user!,
    );

    if (saved == true) {
      // Os parâmetros mudaram — qualquer resultado calculado antes já não
      // reflete mais a configuração atual.
      setState(() => _resultado = null);
      await _loadUser();
    }
  }

  void _calculate() {
    if (_user == null) return;

    final glycemiaText = _glycemiaController.text.trim();
    final carbohydratesText = _carbohydratesController.text.trim();

    if (glycemiaText.isEmpty && carbohydratesText.isEmpty) {
      setState(() {
        _erroValidacao =
            'Informe a glicemia atual e/ou os carboidratos da refeição.';
        _resultado = null;
      });
      return;
    }

    final currentGlycemia = glycemiaText.isEmpty
        ? null
        : int.tryParse(glycemiaText);
    final carbohydrates = carbohydratesText.isEmpty
        ? null
        : double.tryParse(carbohydratesText.replaceAll(',', '.'));

    if ((glycemiaText.isNotEmpty && currentGlycemia == null) ||
        (carbohydratesText.isNotEmpty && carbohydrates == null)) {
      setState(() {
        _erroValidacao = 'Informe apenas números válidos.';
        _resultado = null;
      });
      return;
    }

    final result = InsulinCalculationController.calculate(
      currentGlycemia: currentGlycemia,
      carbohydratesGrams: carbohydrates,
      glycemiaTarget: _user!.glycemiaTarget,
      correctionFactor: _user!.correctionFactor,
      sensitivityFactor: _user!.sensitivityFactor,
    );

    setState(() {
      _erroValidacao = null;
      _resultado = result;
    });
  }

  void _clearCalculation() {
    setState(() {
      _glycemiaController.clear();
      _carbohydratesController.clear();
      _resultado = null;
      _erroValidacao = null;
    });
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    TextStyle? hintStyle,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          hintStyle ??
          TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _parameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
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
                      PhosphorIcons.calculator,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculadora de Insulina',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Calcule a dose necessária',
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
                child: _isLoading || _user == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Seus Parâmetros Atuais
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Seus Parâmetros Atuais',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _openEditParameters,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        PhosphorIcons.pencilSimple,
                                        size: 16,
                                        color: AppColors.primaryColor,
                                      ),
                                      label: const Text(
                                        'Editar',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _parameterRow(
                                  'Meta Glicêmica:',
                                  '${_user!.glycemiaTarget} mg/dL',
                                ),
                                _parameterRow(
                                  'Fator de Correção:',
                                  '1 UI / ${_formatNumber(_user!.correctionFactor)} mg/dL',
                                ),
                                _parameterRow(
                                  'Razão Insulina/Carbo:',
                                  '1 UI / ${_formatNumber(_user!.sensitivityFactor)}g',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Glicemia Atual (mg/dL)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _glycemiaController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                            decoration: _fieldDecoration(
                              hintText: '120',
                              hintStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade300,
                              ),
                              prefixIcon: Icon(
                                PhosphorIcons.drop,
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Carboidratos da Refeição',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Escolha UMA das opções: digite manualmente OU '
                            'selecione alimentos da biblioteca',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _carbohydratesController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _fieldDecoration(
                              hintText: 'Ex: 45g',
                              prefixIcon: Icon(
                                PhosphorIcons.bowlFood,
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // "Selecionar Alimentos" ainda não tem ação: a
                          // biblioteca de Alimentos é uma sprint futura do
                          // roadmap (visível, mas sem função, como o card
                          // de Alarmes em Configurações).
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              PhosphorIcons.plus,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            label: const Text('Selecionar Alimentos'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              foregroundColor: AppColors.primaryColor,
                              backgroundColor: AppColors.primaryColor
                                  .withValues(alpha: 0.06),
                              side: BorderSide(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_erroValidacao != null) ...[
                            Text(
                              _erroValidacao!,
                              style: const TextStyle(
                                color: AppColors.dangerColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _clearCalculation,
                                icon: const Icon(
                                  PhosphorIcons.arrowCounterClockwise,
                                  size: 18,
                                ),
                                label: const Text('Limpar'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  foregroundColor: Colors.grey.shade700,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _calculate,
                                  icon: const Icon(PhosphorIcons.calculator),
                                  label: const Text('Calcular Dose'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_resultado != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dose Sugerida',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatNumber(_resultado!.totalDose),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'UI',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  _parameterRow(
                                    'Correção da glicemia',
                                    '${_formatNumber(_resultado!.correctionDose)} UI',
                                  ),
                                  _parameterRow(
                                    'Carboidratos da refeição',
                                    '${_formatNumber(_resultado!.carbohydrateDose)} UI',
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  PhosphorIcons.warning,
                                  color: Colors.amber.shade800,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Este é apenas um cálculo estimado. '
                                    'Sempre consulte seu médico antes de '
                                    'ajustar suas doses de insulina.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.amber.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
