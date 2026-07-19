//import 'dart:io';

import 'dart:async';
import 'package:flutter/material.dart';
import 'ble_service.dart';
import '../api/open_meteo_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final BleService bleService = BleService(handshakeModule: PicoHandshakeModule());

  print('1. Start Scan');
  await bleService.startScan();

  print('2. Connect to Savia (88:A2:9E:13:CE:09)');
  BluetoothDevice? targetDevice;
  
  final scanSub = bleService.scanResults.listen((results) {
    for (var r in results) {
      if (r.device.remoteId.str == '88:A2:9E:13:CE:09' || 
          r.advertisementData.advName == 'Savia' || 
          r.device.platformName == 'Savia') {
        targetDevice = r.device;
      }
    }
  });

  // Wait up to 15 seconds to find the device
  for(int i = 0; i < 3; i++) {
    if (targetDevice != null) break;
    await Future.delayed(const Duration(seconds: 1));
  }
  
  await scanSub.cancel();

  if (targetDevice != null) {
    print('Device found! Connecting...');
    await bleService.connect(targetDevice!);
  } else {
    print('Device not found. Exiting test.');
    return;
  }

  print('3. Stop Scan');
  await bleService.stopScan();

  print('4. Sync Time');
  await bleService.syncTime(0);

  print('4.5. Check Inference Capabilities');
  final config = await bleService.readConfig();
  if (config != null) {
    if (config['infer_dev'] == true) {
      print('   Device is capable of local inference. Forcing local mode...');
      await bleService.setInferenceMode('local');
    } else {
      print('   Device is NOT capable of local inference (infer_dev != true).');
    }
  } else {
    print('   Failed to read device configuration.');
  }

  print('5. Fetch & Send Hourly Forecast');
  final meteoClient = OpenMeteoClient(latitude: 40.4168, longitude: -3.7038); // Madrid coords as an example
  print('   Fetching from OpenMeteo...');
  final weatherData = await meteoClient.fetchForecast();
  
  final now = DateTime.now();
  int currentIndex = weatherData.time.indexWhere((t) => t.isAfter(now) || t.isAtSameMomentAs(now));
  if (currentIndex == -1) currentIndex = 0;
  
  // Pick the closest hour
  if (currentIndex > 0 && weatherData.time[currentIndex].difference(now).abs() > now.difference(weatherData.time[currentIndex - 1]).abs()) {
      currentIndex--;
  }

  final List<double> futureTemps = [];
  for (int i = 0; i < 24; i++) {
    if (currentIndex + i < weatherData.temperature2m.length) {
      futureTemps.add(weatherData.temperature2m[currentIndex + i]);
    } else {
      futureTemps.add(20.0); // fallback
    }
  }

  final List<double> pastTemps = [];
  // Go backwards to get the past 48 hours in chronological order
  for (int i = 48; i > 0; i--) {
    if (currentIndex - i >= 0) {
      pastTemps.add(weatherData.temperature2m[currentIndex - i]);
    } else {
      pastTemps.add(20.0); // fallback if missing
    }
  }
  
  print('   Sending 48h past & 24h future forecast temperatures...');
  await bleService.sendHourlyForecast(pastTemps, futureTemps);

  print('6. Check if it has enough data (48 values), if not -> mock');
  bool hasEnoughData = false;
  
  final dataSub = bleService.dataStream.listen((data) {
    print('\n[DataStream] Received: $data');
  });

  final rawDataFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 10), onTimeout: () => []);
  await bleService.requestData('raw');
  
  final rawData = await rawDataFuture;
  if (rawData is List && rawData.isNotEmpty) {
    final List<Map<String, dynamic>> depth30Moisture = [];
    for (var item in rawData) {
      if (item is Map && item['kind'] == 'soil_moisture' && item['depth_cm'] == 30) {
        depth30Moisture.add(item.cast<String, dynamic>());
      }
    }
    print('Found ${depth30Moisture.length} soil moisture values at 30cm.');
    if (depth30Moisture.length >= 48) {
      hasEnoughData = true;
      print('First few aligned values: ${depth30Moisture.take(3).toList()}');
    }
  }

  if (!hasEnoughData) {
    print('Not enough data (or no response), forcing 72h mock...');
    await bleService.forceMock72Hours();
    print('Waiting 10 seconds for mock data to be generated and stored...');
    await Future.delayed(const Duration(seconds: 10));
  } else {
    print('Found sufficient data in memory!');
  }

  print('6.5. Fetch OLD Predictions to detect changes...');
  final oldPredFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 5), onTimeout: () => [-1]);
  await bleService.requestData('pred');
  final oldPredictionsRaw = await oldPredFuture;
  final List<dynamic> oldPredictions = (oldPredictionsRaw is List && oldPredictionsRaw.isNotEmpty && oldPredictionsRaw.first != -1) ? oldPredictionsRaw : [];

  print('7. Trigger Inference');
  final inferenceFuture = bleService.dataStream.firstWhere((data) => data is Map && data.containsKey('count')).timeout(const Duration(seconds: 30), onTimeout: () => {'count': -1});
  await bleService.triggerInference();

  print('8. Wait for Inference to complete...');
  final inferenceResult = await inferenceFuture;
  if (inferenceResult is Map && inferenceResult['count'] == -1) {
    print('Timeout waiting for inference ACK.');
  } else {
    print('Inference queued successfully. Proceeding to poll for predictions.');
  }
  
  print('9. Fetch Predictions (Polling)...');
  List<dynamic>? finalPredictions;
  const int maxPolls = 6; // 3 seconds total max polling time
  
  for (int i = 0; i < maxPolls; i++) {
    final predictionsFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 2), onTimeout: () => [-1]);
    await bleService.requestData('pred');
    final predictions = await predictionsFuture;
    
    if (predictions is List && predictions.isNotEmpty && predictions.first == -1) {
      // Timeout reading
      continue;
    } else if (predictions is List && predictions.isNotEmpty) {
      // Check if it's identical to old predictions
      final bool isDifferent = predictions.toString() != oldPredictions.toString();
      
      if (isDifferent || oldPredictions.isEmpty) {
        finalPredictions = predictions;
        print('   Detected new predictions (values changed)!');
        break;
      } else {
        if (i == maxPolls - 1) {
          finalPredictions = predictions;
          print('   Predictions are identical to the previous run. Assuming inference finished and outputs overlap.');
          break;
        }
        // Still identical to old predictions, might be stale. Keep polling.
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  if (finalPredictions != null) {
    print('Predictions fetched successfully!');
    for (var p in finalPredictions) {
      print('   $p');
    }
  } else {
    print('Timeout: Predictions remained empty ([]) after polling.');
  }
  
  print('9.5. Check Status Characteristic for weather_updated_ms');
  final status = await bleService.readStatus();
  if (status != null) {
    print('   Status map: $status');
    if (status['weather_updated_ms'] == null) {
      print('   WARNING: weather_updated_ms is null! Weather was not successfully cached.');
    } else {
      print('   weather_updated_ms: ${status['weather_updated_ms']}');
    }
  } else {
    print('   Failed to read status.');
  }

  print('9.6. Fetch Pico diagnostic logs...');
  final logsFuture = bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 15), onTimeout: () => [-1]);
  await bleService.requestData('logs');
  final picoLogs = await logsFuture;
  
  if (picoLogs is List && picoLogs.isNotEmpty && picoLogs.first == -1) {
    print('   Timeout waiting for Pico logs.');
  } else if (picoLogs is List && picoLogs.isNotEmpty) {
    print('   --- PICO LOGS ---');
    for (var line in picoLogs) {
      if (line is Map) {
        print('   $line');
      } else {
        print('   ${line.toString()}');
      }
    }
    print('   -----------------');
  } else {
    print('   Pico logs are empty ([]).');
  }

  await dataSub.cancel();

  // print('10. Clear Storage');
  // await bleService.clearStorage();
  // await Future.delayed(const Duration(seconds: 2));

  print('11. Disconnect');
  await bleService.disconnect();
  
  print('Testing complete.');
}