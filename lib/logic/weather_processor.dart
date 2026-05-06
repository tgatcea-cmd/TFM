import 'dart:math';
import '../data/models/weather_data.dart';
import '../data/models/processed/daily_weather.dart';

class WeatherProcessor {
  /// Aggregates hourly data into daily statistics.
  static List<ProcessedWeatherDay> process(WeatherData data) {
    Map<String, List<int>> dailyIndices = {};

    for (int i = 0; i < data.time.length; i++) {
      String dayKey = data.time[i].toIso8601String().split('T')[0];
      dailyIndices.putIfAbsent(dayKey, () => []).add(i);
    }

    return dailyIndices.entries.map((entry) {
      final indices = entry.value;
      final date = DateTime.parse(entry.key);

      return ProcessedWeatherDay(
        date: date,
        temperature: _calculateStats(indices.map((i) => data.temperature2m[i]).toList()),
        humidity: _calculateStats(indices.map((i) => data.relativeHumidity2m[i]).toList()),
        radiation: _calculateStats(indices.map((i) => data.shortwaveRadiation[i]).toList()),
        precipitation: _calculateStats(indices.map((i) => data.precipitation[i]).toList()),
      );
    }).toList();
  }

  static DailyStats _calculateStats(List<double> values) {
    if (values.isEmpty) return DailyStats(min: 0, max: 0, mean: 0, stdDev: 0, sum: 0);

    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final sumVal = values.reduce((a, b) => a + b);
    final meanVal = sumVal / values.length;

    final variance = values.map((v) => pow(v - meanVal, 2)).reduce((a, b) => a + b) / values.length;
    final stdDevVal = sqrt(variance);

    return DailyStats(
      min: minVal,
      max: maxVal,
      mean: meanVal,
      stdDev: stdDevVal,
      sum: sumVal,
    );
  }
}
