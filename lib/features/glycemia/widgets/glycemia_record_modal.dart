import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/core/widgets/modal_feedback_message.dart';
import 'package:doce_equilibrio/core/utils/formatters.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_record_model.dart';
import 'package:doce_equilibrio/features/glycemia/models/glycemia_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Modal (bottom sheet) de registro/edição de uma leitura de glicemia.
///
/// Reaproveitado tanto pelo botão "+ Registrar Glicemia" da Home quanto
/// pela tela de Histórico (para registrar ou editar uma leitura).
class GlycemiaRecordModal extends StatefulWidget {
  final GlycemiaRecordModel? existingRecord;

  const GlycemiaRecordModal({super.key, this.existingRecord});

  /// Abre o modal. Retorna `true` se um registro foi criado/atualizado
  /// (sinal para a tela que chamou recarregar os dados), ou `null`/`false`
  /// se o usuário cancelou.
  static Future<bool?> exibir(
    BuildContext context, {
    GlycemiaRecordModel? existingRecord,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlycemiaRecordModal(existingRecord: existingRecord),
    );
  }

  @override
  State<GlycemiaRecordModal> createState() => _RegistroGlicemiaModalState();
}

class _RegistroGlicemiaModalState extends State<GlycemiaRecordModal> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPeriod;
  late DateTime _date;
  late TimeOfDay _time;
  bool _isSaving = false;
  String? _modalError;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;

    if (record != null) {
      _valueController.text = record.value.toString();
      _selectedPeriod = record.period;
      _date = record.dateTime;
      _time = TimeOfDay.fromDateTime(record.dateTime);
      _notesController.text = record.notes ?? '';
    } else {
      final now = DateTime.now();
      _date = now;
      _time = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _modalError = null;
    });

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final controller = getIt<GlycemiaController>();
    final errorMessage = await controller.save(
      id: widget.existingRecord?.id,
      value: int.parse(_valueController.text),
      period: _selectedPeriod!,
      dateTime: dateTime,
      notes: _notesController.text,
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

  String _formatTime(TimeOfDay time) {
    final timeText = time.hour.toString().padLeft(2, '0');
    final minuteText = time.minute.toString().padLeft(2, '0');
    return '$timeText:$minuteText';
  }

  InputDecoration _fieldDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
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
                        Text(
                          _isEditing
                              ? 'Editar Leitura'
                              : 'Nova Leitura de Glicemia',
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
                      'Glicemia (mg/dL)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                      decoration: _fieldDecoration(hintText: '120'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o valor da glicemia.';
                        }
                        final parsedValue = int.tryParse(value);
                        if (parsedValue == null) {
                          return 'Informe apenas números.';
                        }
                        if (parsedValue <= 0 || parsedValue > 999) {
                          return 'Informe um valor entre 1 e 999 mg/dL.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Período',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPeriod,
                      decoration: _fieldDecoration(
                        hintText: 'Selecione o período',
                      ),
                      items: GlycemiaPeriod.options.map((period) {
                        return DropdownMenuItem<String>(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPeriod = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione o período da medição.';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  child: Text(Formatters.date(_date)),
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
                                  child: Text(_formatTime(_time)),
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
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        hintText: 'Como está se sentindo, o que comeu, etc.',
                      ),
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
                          : Text(
                              _isEditing
                                  ? 'Salvar Alterações'
                                  : 'Salvar Leitura',
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
