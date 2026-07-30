import 'package:flutter/material.dart';
import '../../../../../../data/models/models.dart';
import '../../../../../../data/models/chart_data_point.dart';
import '../../../styles.dart';
import '../../../widgets/charts/time_metric_chart.dart';

/// A specialized wrapper around [TimeMetricChart] configured to display Solar Radiation.
/// 
/// It automatically parses [WeatherRecord] objects for historical radiation data and
/// raw doubles for the forecasting vector.
class RadiationChart extends StatelessWidget {
  final List<WeatherRecord> weatherHistory;
  final List<double> radiationForecast;
  final int timeOffsetHours;
  final int forecastZoneStartHour;
  final int forecastZoneEndHour;

  const RadiationChart({
    super.key,
    required this.weatherHistory,
    required this.radiationForecast,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  @override
  Widget build(BuildContext context) {
    final redColor = AppStyles.dangerRed(context);
    final orangeColor = AppStyles.accentOrange(context);

    final historyData = weatherHistory.map((w) {
      return ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(w.timestamp),
        value: w.radiation,
      );
    }).toList();

    final nowMs = DateTime.now().add(Duration(hours: timeOffsetHours)).millisecondsSinceEpoch;
    final forecastData = <ChartDataPoint>[];
    for (int i = 0; i < radiationForecast.length; i++) {
      forecastData.add(ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(nowMs + (i * 3600000)),
        value: radiationForecast[i],
      ));
    }

    return TimeMetricChart(
      title: 'Solar Radiation',
      unit: 'W/m²',
      history: historyData,
      forecast: forecastData,
      historyColor: redColor,
      forecastColor: orangeColor,
      timeOffsetHours: timeOffsetHours,
      forecastZoneStartHour: forecastZoneStartHour,
      forecastZoneEndHour: forecastZoneEndHour,
      minY: null, 
      maxY: null,
    );
  }
}
