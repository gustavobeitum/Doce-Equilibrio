import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/modal_feedback_message.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal para personalizar os limites das três classificações glicêmicas.
class CustomizeGlycemiaTargetsModal extends StatefulWidget {
  final UserModel currentUser;

  const CustomizeGlycemiaTargetsModal({super.key, required this.currentUser});

  /// Abre o modal. Retorna `true` se as metas foram salvas.
  static Future<bool?> exibir(
    BuildContext context, {
    required UserModel currentUser,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CustomizeGlycemiaTargetsModal(currentUser: currentUser),
    );
  }

  @override
  State<CustomizeGlycemiaTargetsModal> createState() =>
      _PersonalizarMetasModalState();
}

class _PersonalizarMetasModalState
    extends State<CustomizeGlycemiaTargetsModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lowAlertController;
  late final TextEditingController _highDangerController;

  bool _isSaving = false;
  String? _modalError;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _lowAlertController = TextEditingController(
      text: user.normalMinimumThreshold.toString(),
    );
    _highDangerController = TextEditingController(
      text: user.highDangerThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _lowAlertController.dispose();
    _highDangerController.dispose();
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
    final errorMessage = await controller.updateGlycemiaTargets(
      currentUser: widget.currentUser,
      lowAlertThreshold: int.parse(_lowAlertController.text),
      highDangerThreshold: int.parse(_highDangerController.text),
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

  InputDecoration _fieldDecoration({String? hintText, String? sufixo}) {
    return InputDecoration(
      hintText: hintText,
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

  Widget _thresholdField({
    required String label,
    required String descricao,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          descricao,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: _fieldDecoration(sufixo: 'mg/dL'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe um valor.';
            }
            final numero = int.tryParse(value);
            if (numero == null || numero <= 0 || numero > 999) {
              return 'Informe um valor entre 1 e 999.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
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
                          'Personalizar Metas Glicêmicas',
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
                      'Esses valores definem como suas leituras de glicemia '
                      'serão classificadas como Hipoglicemia, Normal ou Hiperglicemia.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _thresholdField(
                      label: 'Hipoglicemia — abaixo de',
                      descricao: 'Valores abaixo deste limite.',
                      controller: _lowAlertController,
                    ),
                    _thresholdField(
                      label: 'Hiperglicemia — acima de',
                      descricao: 'Valores acima deste limite.',
                      controller: _highDangerController,
                    ),

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
                              'Salvar Metas',
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
