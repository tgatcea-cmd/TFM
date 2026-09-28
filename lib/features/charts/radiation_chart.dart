import 'package:flutter/material.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';
import 'package:tfm_app/core/models/device.dart';

import 'time_metric_chart.dart';

/// A widget that displays a time-series chart specifically configured for Solar Radiation.
/// 
/// This widget acts as a wrapper around [TimeMetricChart]. It automatically parses 
/// [WeatherRecord] objects to populate historical radiation data and uses a raw 
/// list of doubles to build the hourly forecasting vector.
class RadiationChart extends StatelessWidget {
  /// The list of historical weather records, from which radiation data is extracted.
  final List<WeatherRecord> weatherHistory;
  
  /// The list of predicted hourly radiation values for forecasting.
  final List<double> radiationForecast;
  
  /// An optional offset in hours applied to the current time, useful for testing or simulation.
  final int timeOffsetHours;
  
  /// The hour of the day (0-23) when the forecasting zone typically begins.
  final int forecastZoneStartHour;
  
  /// The hour of the day (0-23) when the forecasting zone typically ends.
  final int forecastZoneEndHour;

  const RadiationChart({
    super.key,
    required this.weatherHistory,
    required this.radiationForecast,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  /// Builds the widget tree for the solar radiation chart.
  ///
  /// Extracts radiation points from [weatherHistory], projects [radiationForecast] 
  /// into future hourly timestamps, and configures the underlying [TimeMetricChart].
  /// 
  /// Returns a configured [TimeMetricChart] instance.
  @override
  Widget build(BuildContext context) {
    final redColor = Theme.of(context).colorScheme.error;
    final orangeColor = Theme.of(context).colorScheme.secondary;

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
      unit: 'W/mÂ²',
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

