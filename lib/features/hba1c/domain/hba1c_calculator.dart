class HbA1cEstimate {
  const HbA1cEstimate({
    required this.averageGlycemiaMgDl,
    required this.percentage,
    required this.recordCount,
  });

  final double averageGlycemiaMgDl;
  final double percentage;
  final int recordCount;
}

class HbA1cCalculator {
  const HbA1cCalculator();

  HbA1cEstimate? calculate(Iterable<int> glycemiaValuesMgDl) {
    var count = 0;
    var sum = 0.0;
    for (final value in glycemiaValuesMgDl) {
      sum += value;
      count++;
    }
    if (count == 0) return null;

    final average = sum / count;
    return HbA1cEstimate(
      averageGlycemiaMgDl: average,
      percentage: (average + 46.7) / 28.7,
      recordCount: count,
    );
  }
}
