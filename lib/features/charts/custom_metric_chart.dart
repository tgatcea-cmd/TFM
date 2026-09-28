import 'package:flutter/material.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';
import 'package:tfm_app/core/models/device.dart';

import 'package:tfm_app/features/charts/time_metric_chart.dart';

/// A widget that displays a time-series chart for a specific custom metric.
///
/// This widget acts as a wrapper around [TimeMetricChart], filtering a generic list of 
/// [HistoricValue] records to display only the data points matching the specified [kind].
/// It is useful for rendering arbitrary sensor data that do not have a specialized chart widget.
class CustomMetricChart extends StatelessWidget {
  /// The display title of the chart.
  final String title;
  
  /// The unit of measurement for the metric data.
  final String unit;
  
  /// The specific metric identifier used to filter the [history] records.
  final String kind;
  
  /// The complete list of historical telemetry data to be filtered and displayed.
  final List<HistoricValue> history;
  
  /// An optional offset in hours applied to the current time, useful for testing or simulation.
  final int timeOffsetHours;
  
  /// The hour of the day (0-23) when the forecasting zone typically begins.
  final int forecastZoneStartHour;
  
  /// The hour of the day (0-23) when the forecasting zone typically ends.
  final int forecastZoneEndHour;

  const CustomMetricChart({
    super.key,
    required this.title,
    required this.unit,
    required this.kind,
    required this.history,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  /// Builds the widget tree for the chart.
  ///
  /// Extracts the relevant data points from [history] matching the [kind] property
  /// and passes them to the underlying [TimeMetricChart] widget.
  /// 
  /// Returns a configured [TimeMetricChart] instance.
  @override
  Widget build(BuildContext context) {
    final historyColor = Theme.of(context).colorScheme.primary;

    final historyData = history
        .where((h) => h.kind == kind && h.tsMs != null && h.value != null)
        .map((h) {
      return ChartDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(h.tsMs!),
        value: h.value!,
      );
    }).toList();

    return TimeMetricChart(
      title: title,
      unit: unit,
      history: historyData,
      forecast: const [],
      historyColor: historyColor,
      forecastColor: Colors.grey,
      timeOffsetHours: timeOffsetHours,
      forecastZoneStartHour: forecastZoneStartHour,
      forecastZoneEndHour: forecastZoneEndHour,
      minY: null,
      maxY: null,
    );
  }
}

