import 'package:flutter/material.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'time_metric_chart.dart';

/// A specialized wrapper around [TimeMetricChart] configured to display Soil Humidity.
/// 
/// It automatically parses [SoilHumidityRecord] objects for historical data and
/// [PredictionRecord] objects for the forecasting vector.
class HumidityChart extends StatelessWidget {
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final int timeOffsetHours;
  final int forecastZoneStartHour;
  final int forecastZoneEndHour;

  const HumidityChart({
    super.key,
    required this.history,
    required this.predictions,
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  @override
  Widget build(BuildContext context) {
    final tealColor = AppStyles.primaryTeal(context);
    final orangeColor = AppStyles.accentOrange(context);

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

