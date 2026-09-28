import 'package:flutter/material.dart';
import 'radiation_chart.dart';
import 'humidity_chart.dart';
import 'custom_metric_chart.dart';
import 'package:tfm_app/core/models/device.dart';

/// A master dashboard widget that aggregates multiple time-metric charts vertically.
/// 
/// It automatically calculates the current system state ("ETAPA ESPERAR DATOS" vs 
/// "ETAPA DATOS LISTOS") based on the current time and the configured 
/// [forecastZoneStartHour] and [forecastZoneEndHour], displaying a synchronized header.
class UnifiedChart extends StatelessWidget {
  /// The list of historical soil humidity records.
  final List<SoilHumidityRecord> history;
  
  /// The list of predicted soil humidity records for forecasting.
  final List<PredictionRecord> predictions;
  
  /// The list of predicted hourly radiation values for forecasting.
  final List<double> radiationForecast;
  
  /// The list of predicted hourly temperature values for forecasting.
  final List<double> temperatureForecast;
  
  /// The list of historical weather records (used for past radiation and temperature).
  final List<WeatherRecord> weatherHistory;
  
  /// The complete list of historical telemetry data for generic custom metrics.
  final List<HistoricValue> deviceHistory;
  
  /// A list of identifiers for custom metrics that should be rendered as additional charts.
  final List<String> customMetrics;
  
  /// An optional offset in hours applied to the current time, useful for testing or simulation.
  final int timeOffsetHours;
  
  /// The minimum acceptable humidity threshold (e.g., for setting alert lines).
  final double minHumidity;
  
  /// The hour of the day (0-23) when the forecasting zone typically begins.
  final int forecastZoneStartHour;
  
  /// The hour of the day (0-23) when the forecasting zone typically ends.
  final int forecastZoneEndHour;

  const UnifiedChart({
    super.key,
    required this.history,
    required this.predictions,
    required this.radiationForecast,
    required this.temperatureForecast,
    required this.weatherHistory,
    required this.deviceHistory,
    required this.minHumidity,
    this.customMetrics = const [],
    this.timeOffsetHours = 0,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
  });

  /// Builds the aggregated chart dashboard widget tree.
  ///
  /// Evaluates whether the current time falls inside the "waiting data" period
  /// to display the appropriate status header. Then renders the [RadiationChart],
  /// [HumidityChart], and dynamically builds [CustomMetricChart]s based on [customMetrics].
  /// 
  /// Returns a vertically scrolling [Column] of charts.
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().add(Duration(hours: timeOffsetHours));
    
    // Calculate if we are in the waiting data (Gathering) zone
    bool isWaitingData = false;
    final int h = now.hour;
    final int gatheringStartHour = (forecastZoneEndHour + 1) % 24;
    final int fStart = forecastZoneStartHour % 24;
    
    if (gatheringStartHour < fStart) {
       isWaitingData = (h >= gatheringStartHour && h < fStart);
    } else {
       isWaitingData = (h >= gatheringStartHour || h < fStart);
    }
    
    final headerColor = isWaitingData
        ? Colors.amber.shade700
        : Colors.green.shade700;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWaitingData
                  ? Icons.hourglass_empty
                  : Icons.check_circle_outline,
              color: headerColor,
            ),
            const SizedBox(width: 8),
            Text(
              isWaitingData ? "ETAPA ESPERAR DATOS" : "ETAPA DATOS LISTOS",
              style: TextStyle(fontWeight: FontWeight.bold, color: headerColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RadiationChart(
          weatherHistory: weatherHistory,
          radiationForecast: radiationForecast,
          timeOffsetHours: timeOffsetHours,
          forecastZoneStartHour: forecastZoneStartHour,
          forecastZoneEndHour: forecastZoneEndHour,
        ),
        const SizedBox(height: 16),
        HumidityChart(
          history: history,
          predictions: predictions,
          timeOffsetHours: timeOffsetHours,
          forecastZoneStartHour: forecastZoneStartHour,
          forecastZoneEndHour: forecastZoneEndHour,
        ),
        const SizedBox(height: 16),
        ...customMetrics.map((kind) => Column(
          children: [
            const SizedBox(height: 16),
            CustomMetricChart(
              title: kind.toUpperCase(),
              unit: '',
              kind: kind,
              history: deviceHistory,
              timeOffsetHours: timeOffsetHours,
              forecastZoneStartHour: forecastZoneStartHour,
              forecastZoneEndHour: forecastZoneEndHour,
            ),
          ],
        )),
      ],
    );
  }
}

