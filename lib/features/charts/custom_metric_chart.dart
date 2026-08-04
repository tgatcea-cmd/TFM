import 'package:flutter/material.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';
import 'package:tfm_app/core/models/device.dart';

import 'package:tfm_app/features/charts/time_metric_chart.dart';

/// A specialized wrapper around [TimeMetricChart] for generic custom telemetry data.
class CustomMetricChart extends StatelessWidget {
  final String title;
  final String unit;
  final String kind;
  final List<HistoricValue> history;
  final int timeOffsetHours;
  final int forecastZoneStartHour;
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

