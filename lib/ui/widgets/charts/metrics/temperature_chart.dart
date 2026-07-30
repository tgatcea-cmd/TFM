import 'package:flutter/material.dart';
import '../../../../../../data/models/models.dart';
import '../../../../../../data/models/chart_data_point.dart';
import '../../../widgets/charts/time_metric_chart.dart';

/// A specialized wrapper around [TimeMetricChart] configured to display Temperature.
/// 
/// Example chart demonstrating how to map historical [WeatherRecord] data
/// and forecast vectors into the unified charting system.
class TemperatureChart extends StatelessWidget {
  final List<WeatherRecord> weatherHistory;
  final List<double> temperatureForecast;
  final int timeOffsetHours;
  final int forecastZoneStartHour;
  final int forecastZoneEndHour;

  const TemperatureChart({
    super.key,
    required this.weatherHistory,
    required this.temperatureForecast,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  @override
  Widget build(BuildContext context) {
    final historyData = weatherHistory.map((w) {
      return ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(w.timestamp),
        value: w.temperature,
      );
    }).toList();

    final nowMs = DateTime.now().add(Duration(hours: timeOffsetHours)).millisecondsSinceEpoch;
    final forecastData = <ChartDataPoint>[];
    for (int i = 0; i < temperatureForecast.length; i++) {
      forecastData.add(ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(nowMs + (i * 3600000)),
        value: temperatureForecast[i],
      ));
    }

    return TimeMetricChart(
      title: 'Temperature',
      unit: '°C',
      history: historyData,
      forecast: forecastData,
      historyColor: Colors.deepPurple,
      forecastColor: Colors.pinkAccent,
      timeOffsetHours: timeOffsetHours,
      forecastZoneStartHour: forecastZoneStartHour,
      forecastZoneEndHour: forecastZoneEndHour,
      minY: null, 
      maxY: null,
    );
  }
}
