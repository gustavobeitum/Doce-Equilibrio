/// Tipo do lembrete/alarme. Genérico o suficiente pra cobrir Medicamento
/// e "Outro" antes mesmo do cadastro de Medicamento (UC-18) existir —
/// nessa sprint é só uma categoria informativa, sem ligação com nenhuma
/// outra tabela ainda.
enum ReminderType {
  insulinaBasal,
  medication,
  outro;

  String get label {
    switch (this) {
      case ReminderType.insulinaBasal:
        return 'Insulina Basal';
      case ReminderType.medication:
        return 'Medicamento';
      case ReminderType.outro:
        return 'Outro';
    }
  }

  static ReminderType fromValor(String value) {
    return ReminderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReminderType.outro,
    );
  }
}
