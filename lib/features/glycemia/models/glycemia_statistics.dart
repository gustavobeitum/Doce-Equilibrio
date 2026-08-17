/// Estatísticas resumidas exibidas no topo da tela de Histórico de Glicemia.
class GlycemiaStatistics {
  final int average;
  final int totalReadings;
  final int lastSevenDays;

  const GlycemiaStatistics({
    required this.average,
    required this.totalReadings,
    required this.lastSevenDays,
  });

  factory GlycemiaStatistics.empty() {
    return const GlycemiaStatistics(
      average: 0,
      totalReadings: 0,
      lastSevenDays: 0,
    );
  }
}
