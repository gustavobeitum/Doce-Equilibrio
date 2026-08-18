/// Tipo da refeição registrada (UC-12).
enum MealType {
  cafeDaManha,
  almoco,
  lanche,
  jantar,
  outro;

  String get label {
    switch (this) {
      case MealType.cafeDaManha:
        return 'Café da Manhã';
      case MealType.almoco:
        return 'Almoço';
      case MealType.lanche:
        return 'Lanche';
      case MealType.jantar:
        return 'Jantar';
      case MealType.outro:
        return 'Outro';
    }
  }

  static MealType fromValor(String value) {
    return MealType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MealType.outro,
    );
  }
}
