class DailyStats {
  final double min;
  final double max;
  final double mean;
  final double stdDev;
  final double sum; // For radiation and precipitation (accumulated)

  DailyStats({
    required this.min,
    required this.max,
    required this.mean,
    required this.stdDev,
    required this.sum,
  });

  @override
  String toString() => 'Min: $min, Max: $max, Mean: $mean, Std: $stdDev, Sum: $sum';
}

class ProcessedWeatherDay {
  final DateTime date;
  final DailyStats temperature;
  final DailyStats humidity;
  final DailyStats radiation;
  final DailyStats precipitation;

  ProcessedWeatherDay({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.radiation,
    required this.precipitation,
  });
}
