import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/reminders/controllers/reminder_controller.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Rótulo (D S T Q Q S S) e o número de `DateTime.weekday` correspondente,
/// na ordem de exibição Domingo → Sábado.
const List<({String label, int weekday})> _displayWeekdays = [
  (label: 'D', weekday: DateTime.sunday),
  (label: 'S', weekday: DateTime.monday),
  (label: 'T', weekday: DateTime.tuesday),
  (label: 'Q', weekday: DateTime.wednesday),
  (label: 'Q', weekday: DateTime.thursday),
  (label: 'S', weekday: DateTime.friday),
  (label: 'S', weekday: DateTime.saturday),
];

class ReminderModal extends StatefulWidget {
  final ReminderModel? existingReminder;

  const ReminderModal({super.key, this.existingReminder});

  /// Abre o modal. Retorna `true` se o lembrete foi criado/atualizado.
  static Future<bool?> exibir(
    BuildContext context, {
    ReminderModel? existingReminder,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderModal(existingReminder: existingReminder),
    );
  }

  @override
  State<ReminderModal> createState() => _LembreteModalState();
}

class _LembreteModalState extends State<ReminderModal> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();

  ReminderType _selectedType = ReminderType.insulinaBasal;
  late TimeOfDay _time;
  bool _repeat = true;
  final Set<int> _selectedDays = {};
  late DateTime _date;
  bool _isSaving = false;
  bool _tituloEditadoManualmente = false;

  bool get _isEditing => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.existingReminder;

    if (reminder != null) {
      _selectedType = reminder.type;
      _tituloController.text = reminder.title;
      _tituloEditadoManualmente = true;
      _time = TimeOfDay(hour: reminder.time, minute: reminder.minute);
      _repeat = reminder.repeat;
      _selectedDays.addAll(reminder.weekdays);
      _date = reminder.date ?? DateTime.now();
    } else {
      _time = TimeOfDay.now();
      _date = DateTime.now();
      _tituloController.text = _selectedType.label;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
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

  Future<void> _selectDate() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dataEscolhida != null) {
      setState(() => _date = dataEscolhida);
    }
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_selectedDays.contains(weekday)) {
        _selectedDays.remove(weekday);
      } else {
        _selectedDays.add(weekday);
      }
    });
  }

  Widget _frequencyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? AppColors.primaryColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState!.validate();
    final validDays = !_repeat || _selectedDays.isNotEmpty;

    if (!validForm || !validDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !validDays
                ? 'Selecione ao menos um dia da semana.'
                : 'Preencha todos os campos obrigatórios antes de salvar.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final controller = getIt<ReminderController>();
    final errorMessage = await controller.save(
      id: widget.existingReminder?.id,
      type: _selectedType,
      title: _tituloController.text,
      time: _time.hour,
      minute: _time.minute,
      repeat: _repeat,
      weekdays: _repeat ? _selectedDays.toList() : const [],
      date: _repeat ? null : _date,
      active: widget.existingReminder?.active ?? true,
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
                          _isEditing ? 'Editar Lembrete' : 'Novo Lembrete',
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
                      'Tipo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ReminderType>(
                      initialValue: _selectedType,
                      decoration: _fieldDecoration(),
                      items: ReminderType.values.map((type) {
                        return DropdownMenuItem<ReminderType>(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (type) {
                        if (type == null) return;
                        setState(() {
                          _selectedType = type;
                          // Só sobrescreve o título automaticamente se o
                          // usuário ainda não digitou nada próprio.
                          if (!_tituloEditadoManualmente) {
                            _tituloController.text = type.label;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Título',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tituloController,
                      decoration: _fieldDecoration(
                        hintText: 'Ex: Insulina Basal, Metformina...',
                      ),
                      onChanged: (_) =>
                          setState(() => _tituloEditadoManualmente = true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe um título.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Horário',
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
                          '${_time.hour.toString().padLeft(2, '0')}:'
                          '${_time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Frequência',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _frequencyButton(
                            label: 'Repetir semanalmente',
                            selected: _repeat,
                            onTap: () => setState(() => _repeat = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _frequencyButton(
                            label: 'Uma vez',
                            selected: !_repeat,
                            onTap: () => setState(() => _repeat = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_repeat) ...[
                      const Text(
                        'Repetir nos dias',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _displayWeekdays.map((day) {
                          final selected = _selectedDays.contains(day.weekday);
                          return InkWell(
                            onTap: () => _toggleDay(day.weekday),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.primaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                day.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
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
                            '${_date.day.toString().padLeft(2, '0')}/'
                            '${_date.month.toString().padLeft(2, '0')}/'
                            '${_date.year}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Esse lembrete dispara uma única vez e não repete.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
                                  : 'Salvar Lembrete',
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
