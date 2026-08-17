import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/medication/controllers/medication_controller.dart';
import 'package:doce_equilibrio/features/medication/models/medication_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MedicationModal extends StatefulWidget {
  final MedicationModel? existingMedication;

  const MedicationModal({super.key, this.existingMedication});

  static Future<bool?> exibir(
    BuildContext context, {
    MedicationModel? existingMedication,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MedicationModal(existingMedication: existingMedication),
    );
  }

  @override
  State<MedicationModal> createState() => _MedicamentoModalState();
}

class _MedicamentoModalState extends State<MedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final _observacaoController = TextEditingController();

  late DateTime _data;
  late TimeOfDay _hora;
  bool _isSaving = false;

  bool get _isEditing => widget.existingMedication != null;

  @override
  void initState() {
    super.initState();
    final medicamento = widget.existingMedication;

    if (medicamento != null) {
      _nomeController.text = medicamento.nome;
      _dosagemController.text = medicamento.dosagem;
      _observacaoController.text = medicamento.observacao ?? '';
      _data = medicamento.dataHora;
      _hora = TimeOfDay.fromDateTime(medicamento.dataHora);
    } else {
      final agora = DateTime.now();
      _data = agora;
      _hora = TimeOfDay.fromDateTime(agora);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dataEscolhida != null) {
      setState(() => _data = dataEscolhida);
    }
  }

  Future<void> _selectTime() async {
    final horaEscolhida = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (horaEscolhida != null) {
      setState(() => _hora = horaEscolhida);
    }
  }

  Future<void> _salvar() async {
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

    final dataHora = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );

    final controller = getIt<MedicationController>();
    final mensagemErro = await controller.salvar(
      id: widget.existingMedication?.id,
      nome: _nomeController.text,
      dosagem: _dosagemController.text,
      dataHora: dataHora,
      observacao: _observacaoController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (mensagemErro == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagemErro)));
    }
  }

  InputDecoration _fieldDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
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
                          _isEditing
                              ? 'Editar Medicamento'
                              : 'Registrar Medicamento',
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
                      'Nome do Medicamento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: _fieldDecoration(hintText: 'Ex: Metformina'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do medicamento.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Dosagem',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosagemController,
                      decoration: _fieldDecoration(
                        hintText: 'Ex: 500mg, 1 comprimido...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a dosagem.';
                        }
                        return null;
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
                                    '${_data.day.toString().padLeft(2, '0')}/'
                                    '${_data.month.toString().padLeft(2, '0')}/'
                                    '${_data.year}',
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
                                    '${_hora.hour.toString().padLeft(2, '0')}:'
                                    '${_hora.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Observações (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observacaoController,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        hintText: 'Ex: tomado com o café da manhã',
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _salvar,
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
                                  : 'Salvar Registro',
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
