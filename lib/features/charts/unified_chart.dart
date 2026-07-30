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
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final List<double> radiationForecast;
  final List<double> temperatureForecast;
  final List<WeatherRecord> weatherHistory;
  final List<HistoricValue> deviceHistory;
  final List<String> customMetrics;
  final int timeOffsetHours;
  final double minHumidity;
  final int forecastZoneStartHour;
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

