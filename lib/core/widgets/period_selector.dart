import 'package:doce_equilibrio/core/history/history_period.dart';
import 'package:doce_equilibrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.periods,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final List<HistoryPeriod> periods;
  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;
  final bool enabled;

  final EdgeInsetsGeometry padding;

  static String labelFor(HistoryPeriod period) => switch (period) {
    HistoryPeriod.today => 'Hoje',
    HistoryPeriod.last7Days => '7 dias',
    HistoryPeriod.last30Days => '30 dias',
    HistoryPeriod.last90Days => '90 dias',
    HistoryPeriod.custom => 'Personalizado',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PeriodPill(
              label: labelFor(period),
              selected: isSelected,
              onTap: enabled ? () => onSelected(period) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}