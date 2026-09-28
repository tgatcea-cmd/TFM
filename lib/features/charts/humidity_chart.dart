import 'package:flutter/material.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';
import 'package:tfm_app/core/models/device.dart';

import 'time_metric_chart.dart';

/// A widget that displays a time-series chart specifically configured for Soil Humidity.
/// 
/// This widget acts as a wrapper around [TimeMetricChart]. It automatically parses 
/// [SoilHumidityRecord] objects to populate historical data and [PredictionRecord] 
/// objects to build the forecasting vector.
class HumidityChart extends StatelessWidget {
  /// The list of historical soil humidity records.
  final List<SoilHumidityRecord> history;
  
  /// The list of predicted soil humidity records for forecasting.
  final List<PredictionRecord> predictions;
  
  /// An optional offset in hours applied to the current time, useful for testing or simulation.
  final int timeOffsetHours;
  
  /// The hour of the day (0-23) when the forecasting zone typically begins.
  final int forecastZoneStartHour;
  
  /// The hour of the day (0-23) when the forecasting zone typically ends.
  final int forecastZoneEndHour;

  const HumidityChart({
    super.key,
    required this.history,
    required this.predictions,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  /// Builds the widget tree for the humidity chart.
  ///
  /// Converts the [history] and [predictions] records into [ChartDataPoint]s 
  /// and configures the underlying [TimeMetricChart] for a percentage-based display.
  /// 
  /// Returns a configured [TimeMetricChart] instance.
  @override
  Widget build(BuildContext context) {
    final tealColor = Theme.of(context).colorScheme.primary;
    final orangeColor = Theme.of(context).colorScheme.secondary;

    final historyData = history.map((h) {
      return ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(h.timestamp),
        value: h.value,
      );
    }).toList();

    final forecastData = predictions.map((p) {
      return ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(p.timestamp),
        value: p.predictedHumidity,
      );
    }).toList();

    return TimeMetricChart(
      title: 'Soil Humidity',
      unit: '%',
      history: historyData,
      forecast: forecastData,
      historyColor: tealColor,
      forecastColor: orangeColor,
      timeOffsetHours: timeOffsetHours,
      forecastZoneStartHour: forecastZoneStartHour,
      forecastZoneEndHour: forecastZoneEndHour,
      minY: null, 
      maxY: null,
    );
  }
}

