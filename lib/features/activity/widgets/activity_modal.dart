import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/modal_feedback_message.dart';
import 'package:doce_equilibrio/features/activity/controllers/activity_controller.dart';
import 'package:doce_equilibrio/features/activity/models/activity_model.dart';
import 'package:doce_equilibrio/features/activity/models/activity_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ActivityModal extends StatefulWidget {
  final ActivityModel? existingActivity;

  const ActivityModal({super.key, this.existingActivity});

  static Future<bool?> exibir(
    BuildContext context, {
    ActivityModel? existingActivity,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityModal(existingActivity: existingActivity),
    );
  }

  @override
  State<ActivityModal> createState() => _AtividadeModalState();
}

class _AtividadeModalState extends State<ActivityModal> {
  final _formKey = GlobalKey<FormState>();
  final _duracaoController = TextEditingController();
  final _observacaoController = TextEditingController();

  ActivityType _tipoSelecionado = ActivityType.caminhada;
  late DateTime _data;
  late TimeOfDay _hora;
  bool _isSaving = false;
  String? _modalError;

  bool get _isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();
    final atividade = widget.existingActivity;

    if (atividade != null) {
      _tipoSelecionado = atividade.tipo;
      _duracaoController.text = atividade.duracaoMinutos.toString();
      _observacaoController.text = atividade.observacao ?? '';
      _data = atividade.dataHora;
      _hora = TimeOfDay.fromDateTime(atividade.dataHora);
    } else {
      final agora = DateTime.now();
      _data = agora;
      _hora = TimeOfDay.fromDateTime(agora);
    }
  }

  @override
  void dispose() {
    _duracaoController.dispose();
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
      return;
    }

    setState(() {
      _isSaving = true;
      _modalError = null;
    });

    final dataHora = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );

    final controller = getIt<ActivityController>();
    final mensagemErro = await controller.salvar(
      id: widget.existingActivity?.id,
      tipo: _tipoSelecionado,
      duracaoMinutos: int.parse(_duracaoController.text),
      dataHora: dataHora,
      observacao: _observacaoController.text,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _modalError = mensagemErro;
    });

    if (mensagemErro == null) {
      Navigator.pop(context, true);
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
                              ? 'Editar Atividade'
                              : 'Registrar Atividade',
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
                      'Tipo de Atividade',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ActivityType>(
                      initialValue: _tipoSelecionado,
                      decoration: _fieldDecoration(),
                      items: ActivityType.values.map((tipo) {
                        return DropdownMenuItem<ActivityType>(
                          value: tipo,
                          child: Text(tipo.rotulo),
                        );
                      }).toList(),
                      onChanged: (tipo) {
                        if (tipo == null) return;
                        setState(() => _tipoSelecionado = tipo);
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Duração',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _duracaoController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(
                        hintText: 'Ex: 30',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Align(
                            widthFactor: 1,
                            child: Text(
                              'min',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a duração.';
                        }
                        final numero = int.tryParse(value);
                        if (numero == null || numero <= 0) {
                          return 'Informe um valor válido.';
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
                        hintText:
                            'Ex: intensidade, percurso, como se sentiu...',
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_modalError != null) ...[
                      ModalFeedbackMessage(message: _modalError!),
                      const SizedBox(height: 12),
                    ],

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
