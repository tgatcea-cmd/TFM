import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';
import '../db/database_service.dart';
import '../../data/models/device.dart';

/// ponytail: A simple function to execute the connection flow described in docs/new_main.txt
/// No unnecessary state machines, just a straight-line async function.
Future<bool> executeConnectionRoutine(
  BluetoothDevice targetDevice,
  BleService bleService,
  DatabaseService db,
) async {
  print('--- Executing Connection Routine ---');

  // 1. Stop scanning
  await bleService.stopScan();

  // 2. Connect
  final success = await bleService.connect(targetDevice);
  if (!success) {
    print('Failed to connect to device');
    return false;
  }

  // 3. Sync time
  // Assuming 0 offset for now; ideally we fetch timeZone offset if required
  print('Syncing time...');
  await bleService.syncTime(0);

  // 4. Check Inference Capabilities
  print('Checking Inference Capabilities...');
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

  // 5. Ensure device exists in local DB
  db.saveDeviceBasic(targetDevice.remoteId.str, targetDevice.platformName);

  // 6. Fetch saved data and cache it
  print('Fetching raw data from device...');
  final rawDataFuture = bleService.dataStream
      .firstWhere((data) => data is List)
      .timeout(const Duration(seconds: 15), onTimeout: () => []);

  await bleService.requestData('raw');
  final rawData = await rawDataFuture;

  // 7. Parse raw data into HistoricValues and save to DB
  if (rawData is List && rawData.isNotEmpty) {
    print('Received ${rawData.length} raw data points.');
    final List<HistoricValue> newValues = [];

    for (var item in rawData) {
      if (item is Map) {
        final hv = HistoricValue()
          ..tsMs =
              item['ts_ms'] as int? ??
              item['ms'] as int? ??
              item['tsMs'] as int?
          ..port = item['port'] as int?
          ..kind = item['kind'] as String?
          ..value = (item['value'] as num?)?.toDouble()
          ..depthCm = (item['depth_cm'] as num?)?.toDouble();

        newValues.add(hv);
      }
    }

    if (newValues.isNotEmpty) {
      print('Saving ${newValues.length} HistoricValues to DB...');
      db.appendTelemetry(targetDevice.remoteId.str, newValues);

      final latestHum = newValues
          .where((v) => v.kind == 'soil_moisture')
          .lastOrNull;
      if (latestHum != null && latestHum.tsMs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(latestHum.tsMs!);
        final now = DateTime.now();
        if (dt.year != now.year ||
            dt.month != now.month ||
            dt.day != now.day ||
            dt.hour != now.hour) {
          print(
            'Latest humidity point is outdated (${dt.toIso8601String()} vs ${now.toIso8601String()}). Injecting mock72Hours...',
          );
          await bleService.forceMock72Hours();

          final rawDataFuture = bleService.dataStream
              .firstWhere((data) => data is List)
              .timeout(const Duration(seconds: 15), onTimeout: () => []);

          await bleService.requestData('raw');
          final rawData = await rawDataFuture;

          if (rawData is List && rawData.isNotEmpty) {
            print('Received ${rawData.length} raw data points.');
            final List<HistoricValue> newValues = [];

            for (var item in rawData) {
              if (item is Map) {
                final hv = HistoricValue()
                  ..tsMs =
                      item['ts_ms'] as int? ??
                      item['ms'] as int? ??
                      item['tsMs'] as int?
                  ..port = item['port'] as int?
                  ..kind = item['kind'] as String?
                  ..value = (item['value'] as num?)?.toDouble()
                  ..depthCm = (item['depth_cm'] as num?)?.toDouble();

                newValues.add(hv);
              }
            }

            if (rawData.isNotEmpty) {
              final List<HistoricValue> mockValues = [];
              for (var item in rawData) {
                if (item is Map) {
                  final hv = HistoricValue()
                    ..tsMs =
                        item['ts_ms'] as int? ??
                        item['ms'] as int? ??
                        item['tsMs'] as int?
                    ..port = item['port'] as int?
                    ..kind = item['kind'] as String?
                    ..value = (item['value'] as num?)?.toDouble()
                    ..depthCm = (item['depth_cm'] as num?)?.toDouble();
                  mockValues.add(hv);
                }
              }
              if (mockValues.isNotEmpty) {
                print(
                  'Saving ${mockValues.length} mock HistoricValues to DB...',
                );
                db.appendTelemetry(targetDevice.remoteId.str, mockValues);
              }
            }
          }
        }
      }
    }
  } else {
    print('No raw data received or timeout.');
  }

  print('--- Connection Routine Complete ---');
  return true;
}
