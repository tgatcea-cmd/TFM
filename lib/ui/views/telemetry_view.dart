import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/database_service.dart';
import '../../data/models/models.dart';
import '../../data/models/device.dart';
import '../widgets/charts/unified_chart.dart';
import '../../new_main.dart'; // To access providers
import '../../main.dart' as old_main; // To access weatherProvider

final customMetricsProvider = StateProvider<List<String>>((ref) => []);

class TelemetryView extends ConsumerWidget {
  const TelemetryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final settings = ref.watch(appSettingsProvider);
    final customMetrics = ref.watch(customMetricsProvider);
    final weatherState = ref.watch(old_main.weatherProvider);
    
    // Watch the update provider to redraw when DB changes (e.g. after ML inference)
    ref.watch(telemetryUpdateProvider);
    
    // In ponytail architecture, new_main handles BLE state. We just render what we have.
    final bleService = ref.read(bleServiceProvider);
    final deviceId = bleService.connectedDevice?.remoteId.str;
    
    if (deviceId == null) return const Center(child: Text("No device selected"));

    final dev = db.getSavedDevices().where((d) => d.deviceIdentifier == deviceId).firstOrNull;
    if (dev == null) return const Center(child: Text("Device not found in DB"));

    // 1. Map new HistoricValue objects to legacy SoilHumidityRecord for HumidityChart
    // Multiplied by 100 because ML models output 0.0 - 1.0 logic.
    final soilMoisture = dev.historicValues.where((v) => v.kind == 'soil_moisture').map((v) {
      return SoilHumidityRecord(v.tsMs ?? 0, (v.value ?? 0.0) * 100);
    }).toList();

    // 2. Map new Prediction objects to legacy PredictionRecord for HumidityChart
    final predictions = dev.newPredictions.map((p) {
      return PredictionRecord(p.tsMs ?? 0, (p.value ?? 0.0) * 100, 'Inferred');
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Telemetry Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMetricDialog(context, ref, dev),
              tooltip: 'Add Custom Chart',
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: UnifiedChart(
              history: soilMoisture,
              predictions: predictions,
              radiationForecast: weatherState.hourlyRadiationForecast,
              temperatureForecast: weatherState.hourlyForecast,
              weatherHistory: db.getWeatherHistory(),
              deviceHistory: dev.historicValues,
              customMetrics: customMetrics,
              timeOffsetHours: 0,
              minHumidity: settings.minHumidity,
              forecastZoneStartHour: settings.agronomicDayStart,
              forecastZoneEndHour: settings.agronomicDayEnd,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMetricDialog(BuildContext context, WidgetRef ref, Device dev) {
    final availableMetrics = dev.historicValues
        .map((h) => h.kind)
        .where((k) => k != null && k != 'soil_moisture' && k.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();

    final customMetrics = ref.read(customMetricsProvider);
    final unselected = availableMetrics.where((m) => !customMetrics.contains(m)).toList();

    if (unselected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No additional metrics available on device')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: unselected.map((m) => ListTile(
            title: Text(m.toUpperCase()),
            onTap: () {
              ref.read(customMetricsProvider.notifier).state = [...customMetrics, m];
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}
