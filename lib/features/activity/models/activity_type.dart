enum ActivityType {
  caminhada,
  corrida,
  musculacao,
  ciclismo,
  outro;

  String get rotulo {
    switch (this) {
      case ActivityType.caminhada:
        return 'Caminhada';
      case ActivityType.corrida:
        return 'Corrida';
      case ActivityType.musculacao:
        return 'Musculação';
      case ActivityType.ciclismo:
        return 'Ciclismo';
      case ActivityType.outro:
        return 'Outro';
    }
  }

  static ActivityType fromValor(String valor) {
    return ActivityType.values.firstWhere(
      (tipo) => tipo.name == valor,
      orElse: () => ActivityType.outro,
    );
  }
}
