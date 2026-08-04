import 'dart:math';
import 'package:tfm_app/features/weather/weather_data.dart';
import 'package:tfm_app/features/weather/daily_weather.dart';

class WeatherProcessor {
  /// Aggregates hourly data into daily statistics.
  static List<ProcessedWeatherDay> process(WeatherData data) {
    final Map<String, List<int>> dailyIndices = {};

    for (int i = 0; i < data.time.length; i++) {
      final String dayKey = data.time[i].toIso8601String().split('T')[0];
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

    double minVal = values[0];
    double maxVal = values[0];
    double sumVal = 0.0;

    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
      sumVal += v;
    }
    final meanVal = sumVal / values.length;

    double sumSqDiff = 0.0;
    for (int i = 0; i < values.length; i++) {
      final diff = values[i] - meanVal;
      sumSqDiff += diff * diff;
    }
    final stdDevVal = sqrt(sumSqDiff / values.length);

    return DailyStats(
      min: minVal,
      max: maxVal,
      mean: meanVal,
      stdDev: stdDevVal,
      sum: sumVal,
    );
  }
}

