import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_model.dart';
import 'package:doce_equilibrio/features/reminders/models/reminder_type.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

const List<({String label, int weekday})> _displayWeekdays = [
  (label: 'D', weekday: DateTime.sunday),
  (label: 'S', weekday: DateTime.monday),
  (label: 'T', weekday: DateTime.tuesday),
  (label: 'Q', weekday: DateTime.wednesday),
  (label: 'Q', weekday: DateTime.thursday),
  (label: 'S', weekday: DateTime.friday),
  (label: 'S', weekday: DateTime.saturday),
];

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final ValueChanged<bool> onAlternarAtivo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onAlternarAtivo,
    required this.onEditar,
    required this.onExcluir,
  });

  IconData _iconFor(ReminderType type) {
    switch (type) {
      case ReminderType.insulinaBasal:
        return PhosphorIcons.drop;
      case ReminderType.medication:
        return PhosphorIcons.pill;
      case ReminderType.outro:
        return PhosphorIcons.bellSimple;
    }
  }

  bool _hasTriggered() {
    final date = reminder.date;
    if (date == null) return false;
    final scheduledFor = DateTime(
      date.year,
      date.month,
      date.day,
      reminder.time,
      reminder.minute,
    );
    return scheduledFor.isBefore(DateTime.now());
  }

  String _singleDateLabel() {
    final date = reminder.date;
    if (date == null) return 'Uma vez';

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    return _hasTriggered() ? '$formattedDate • já disparou' : formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    final opacidade = reminder.active ? 1.0 : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Opacity(
        opacity: opacidade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(reminder.type),
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reminder.time.toString().padLeft(2, '0')}:'
                        '${reminder.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${reminder.type.label} • ${reminder.title}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (reminder.medicationName != null)
                        Text(
                          'Medicamento: ${reminder.medicationName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.active,
                  onChanged: onAlternarAtivo,
                  activeTrackColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (reminder.repeat)
                  Row(
                    children: _displayWeekdays.map((day) {
                      final selected = reminder.weekdays.contains(day.weekday);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primaryColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                          child: Text(
                            day.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    _singleDateLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hasTriggered()
                          ? Colors.grey.shade400
                          : AppColors.primaryColor,
                    ),
                  ),
                Row(
                  children: [
                    InkWell(
                      onTap: onEditar,
                      borderRadius: BorderRadius.circular(50),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          PhosphorIcons.pencilSimple,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onExcluir,
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          PhosphorIcons.trash,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
