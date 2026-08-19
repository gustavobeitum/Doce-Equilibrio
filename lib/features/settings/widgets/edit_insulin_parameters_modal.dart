import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/modal_feedback_message.dart';
import 'package:doce_equilibrio/core/utils/validators.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal para o usuário configurar os parâmetros usados no cálculo de
/// insulina (RF-002 / UC-05, UC-06, UC-07). O cálculo em si vem numa
/// sprint futura — aqui só definimos e persistimos os valores.
class EditInsulinParametersModal extends StatefulWidget {
  final UserModel currentUser;

  const EditInsulinParametersModal({super.key, required this.currentUser});

  /// Abre o modal. Retorna `true` se os parâmetros foram salvos.
  static Future<bool?> exibir(
    BuildContext context, {
    required UserModel currentUser,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditInsulinParametersModal(currentUser: currentUser),
    );
  }

  @override
  State<EditInsulinParametersModal> createState() =>
      _EditarParametrosModalState();
}

class _EditarParametrosModalState extends State<EditInsulinParametersModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fatorSensibilidadeController;
  late final TextEditingController _fatorCorrecaoController;
  late final TextEditingController _metaGlicemicaController;

  bool _isSaving = false;
  String? _modalError;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _fatorSensibilidadeController = TextEditingController(
      text: _formatNumber(user.sensitivityFactor),
    );
    _fatorCorrecaoController = TextEditingController(
      text: _formatNumber(user.correctionFactor),
    );
    _metaGlicemicaController = TextEditingController(
      text: user.glycemiaTarget.toString(),
    );
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _fatorSensibilidadeController.dispose();
    _fatorCorrecaoController.dispose();
    _metaGlicemicaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _modalError = null;
    });

    final controller = getIt<ProfileController>();
    final errorMessage = await controller.updateInsulinParameters(
      currentUser: widget.currentUser,
      sensitivityFactor: double.parse(
        _fatorSensibilidadeController.text.replaceAll(',', '.'),
      ),
      correctionFactor: double.parse(
        _fatorCorrecaoController.text.replaceAll(',', '.'),
      ),
      glycemiaTarget: int.parse(_metaGlicemicaController.text),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _modalError = errorMessage;
    });

    if (errorMessage == null) {
      Navigator.pop(context, true);
    }
  }

  InputDecoration _fieldDecoration({String? sufixo}) {
    return InputDecoration(
      suffixText: sufixo,
      filled: true,
      fillColor: const Color(0xFFF2F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
                        const Text(
                          'Parâmetros para Insulina',
                          style: TextStyle(
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
                    const SizedBox(height: 8),
                    Text(
                      'Esses valores serão usados futuramente para calcular '
                      'sua dose de insulina automaticamente.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Fator de Sensibilidade',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 UI de insulina anula quantos gramas de carboidratos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fatorSensibilidadeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _fieldDecoration(sufixo: 'g'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe um valor.';
                        }
                        final numero = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        if (numero == null || numero <= 0) {
                          return 'Informe um valor válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Fator de Correção',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 UI de insulina reduz quantos mg/dL de glicemia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fatorCorrecaoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _fieldDecoration(sufixo: 'mg/dL'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe um valor.';
                        }
                        final numero = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        if (numero == null || numero <= 0) {
                          return 'Informe um valor válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Meta Glicêmica',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valor que deseja manter no dia a dia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _metaGlicemicaController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _fieldDecoration(sufixo: 'mg/dL'),
                      validator: Validators.validateGlycemiaTarget,
                    ),
                    const SizedBox(height: 28),

                    if (_modalError != null) ...[
                      ModalFeedbackMessage(message: _modalError!),
                      const SizedBox(height: 12),
                    ],

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
                          : const Text(
                              'Salvar Parâmetros',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
