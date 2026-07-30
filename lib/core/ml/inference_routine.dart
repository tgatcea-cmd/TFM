import 'dart:async';
import '../ble/ble_service.dart';
import '../db/database_service.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/device.dart';
import '../api/open_meteo_client.dart';

/// ponytail: A straight-line asynchronous function that executes the inference flow
/// No unnecessary state managers, just clear sequential logic based on docs/new_main.txt
Future<bool> executeInferenceRoutine(
  String deviceId,
  BleService bleService,
  DatabaseService db,
  AppSettings settings,
) async {
  print('--- Executing Inference Routine ---');

  // 0. Zone Check: LSTM inference is only permitted during Green Zone (Forecasting Available)
  final now = DateTime.now();
  final h = now.hour;
  final startH = settings.agronomicDayStart; // e.g. 19
  final endH = settings.agronomicDayEnd;     // e.g. 9
  
  final bool isYellowZone = (endH < startH) 
      ? (h >= endH && h < startH)
      : (h >= endH || h < startH);

  if (isYellowZone && !settings.alwaysForceInference) {
    print('LSTM Inference skipped: Currently in Yellow Zone (Gathering Stage $endH:00 - $startH:00). Allowed only in Green Zone.');
    return false;
  }

  // 1. Check for sufficient historical telemetry (48h at 30cm depth)
  // We use the helper we created in Step 2.
  final cutoff = DateTime.now().subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
  final telemetry = db.getDeviceTelemetry(deviceId, kind: 'soil_moisture', depthCm: 30.0, sinceMs: cutoff);
  
  // We expect at least 48 hours of data
  // ponytail: Just a simple count check, no complex validation for missing chunks
  if (telemetry.length < 48 && !settings.alwaysForceInference) {
    print('Inference skipped: Not enough data (${telemetry.length}/48 records found).');
    // If the UI is watching, it can read a state variable, but for now we just return false
    return false;
  }
  print('Found sufficient data (${telemetry.length} records) for inference.');

  // 2. Fetch OpenMeteo Forecast
  print('Fetching OpenMeteo data for Lat: ${settings.gpsLat}, Lon: ${settings.gpsLon}...');
  final meteoClient = OpenMeteoClient(latitude: settings.gpsLat, longitude: settings.gpsLon);
  
  try {
    final weatherData = await meteoClient.fetchForecast();
    
    // Time alignment logic from main_ble_workflow.dart
    final now = DateTime.now();
    int currentIndex = weatherData.time.indexWhere((t) => t.isAfter(now) || t.isAtSameMomentAs(now));
    if (currentIndex == -1) currentIndex = 0;
    
    if (currentIndex > 0 && weatherData.time[currentIndex].difference(now).abs() > now.difference(weatherData.time[currentIndex - 1]).abs()) {
        currentIndex--;
    }

    final List<double> futureTemps = [];
    for (int i = 0; i < 24; i++) {
      futureTemps.add(currentIndex + i < weatherData.temperature2m.length 
        ? weatherData.temperature2m[currentIndex + i] 
        : 20.0);
    }

    final List<double> pastTemps = [];
    for (int i = 48; i > 0; i--) {
      pastTemps.add(currentIndex - i >= 0 
        ? weatherData.temperature2m[currentIndex - i] 
        : 20.0);
    }

    // 3. Send past and future temps to station
    print('Sending 48h past & 24h future forecast to station...');
    await bleService.sendHourlyForecast(pastTemps, futureTemps);
  } catch (e) {
    print('OpenMeteo fetch failed: $e');
    if (!settings.permitOpenMeteoFill) return false;
  }

  // 4. Fetch OLD Predictions to detect changes
  print('Fetching OLD Predictions...');
  final oldPredFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 5), onTimeout: () => [-1]);
  await bleService.requestData('pred');
  final oldPredictionsRaw = await oldPredFuture;
  final List<dynamic> oldPredictions = (oldPredictionsRaw is List && oldPredictionsRaw.isNotEmpty && oldPredictionsRaw.first != -1) ? oldPredictionsRaw : [];

  // 5. Trigger Inference
  print('Triggering hardware inference...');
  final inferenceFuture = bleService.dataStream.firstWhere((data) => data is Map && data.containsKey('count')).timeout(const Duration(seconds: 30), onTimeout: () => {'count': -1});
  await bleService.triggerInference();

  final inferenceResult = await inferenceFuture;
  if (inferenceResult is Map && inferenceResult['count'] == -1) {
    print('Timeout waiting for inference ACK.');
    return false;
  }
  
  // 6. Polling for Predictions
  print('Polling for new predictions...');
  List<dynamic>? finalPredictions;
  const int maxPolls = 6;
  
  for (int i = 0; i < maxPolls; i++) {
    final predictionsFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 2), onTimeout: () => [-1]);
    await bleService.requestData('pred');
    final predictions = await predictionsFuture;
    
    if (predictions is List && predictions.isNotEmpty && predictions.first == -1) {
      continue;
    } else if (predictions is List && predictions.isNotEmpty) {
      final bool isDifferent = predictions.toString() != oldPredictions.toString();
      
      if (isDifferent || oldPredictions.isEmpty) {
        finalPredictions = predictions;
        print('Detected new predictions!');
        break;
      } else if (i == maxPolls - 1) {
        finalPredictions = predictions;
        print('Predictions identical to previous. Assuming finished and outputs overlap.');
        break;
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // 7. Parse and Save Predictions
  if (finalPredictions != null) {
    print('Inference complete! Saving ${finalPredictions.length} predictions to DB...');
    final List<Prediction> newPreds = [];
    
    for (var item in finalPredictions) {
      if (item is Map) {
        final p = Prediction()
          ..tsMs = item['ts_ms'] as int? ?? item['ms'] as int? ?? item['tsMs'] as int?
          ..model = item['model'] as String?
          ..kind = item['kind'] as String?
          ..value = (item['value'] as num?)?.toDouble()
          ..confidence = (item['confidence'] as num?)?.toDouble();
        newPreds.add(p);
      }
    }
    
    if (newPreds.isNotEmpty) {
      db.updatePredictions(deviceId, newPreds);
      print('--- Inference Routine Complete ---');
      return true;
    }
  }

  print('Failed to poll new predictions.');
  return false;
}
