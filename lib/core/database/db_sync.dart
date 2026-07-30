import 'app_database.dart';
import 'package:isar_community/isar.dart';
import 'package:tfm_app/core/network/cloud_api.dart';
import 'package:tfm_app/core/models/device.dart';

class SyncService {
  final DatabaseService db;
  final ApiClient api;

  SyncService({required this.db, required this.api});

  Future<void> syncDirtyDevices() async {
    final dirtyDevices = await db.isar.devices.filter().isSyncedEqualTo(false).findAll();
    if (dirtyDevices.isEmpty) return;

    print("Syncing ${dirtyDevices.length} devices to server...");
    
    final List<Map<String, dynamic>> records = [];
    final List<Map<String, dynamic>> predRecords = [];

    for (var d in dirtyDevices) {
      for (var val in d.historicValues) {
        if (val.tsMs != null && val.value != null && val.depthCm != null) {
          records.add({
            'deviceIdentifier': d.deviceIdentifier,
            'tsMs': val.tsMs,
            'value': val.value,
            'depthCm': val.depthCm,
          });
        }
      }
      for (var p in d.newPredictions) {
        if (p.tsMs != null && p.value != null) {
          predRecords.add({
            'deviceIdentifier': d.deviceIdentifier,
            'tsMs': p.tsMs,
            'value': p.value,
            'depthCm': p.depthCm ?? 30.0,
            'kind': p.kind ?? 'prediction',
            'model': p.model ?? 'LSTM',
            'confidence': p.confidence ?? 0.95,
          });
        }
      }
    }

    try {
      if (records.isNotEmpty) {
        await api.syncTelemetryPush(records);
      }
      if (predRecords.isNotEmpty) {
        await api.syncPredictionsPush(predRecords);
        print("Pushed ${predRecords.length} prediction records to server.");
      }

      // Mark as synced locally
      await db.isar.writeTxn(() async {
        for (var d in dirtyDevices) {
          d.isSynced = true;
          await db.isar.devices.put(d);
        }
      });
      print("Sync complete.");
    } catch (e) {
      print("Sync failed: $e");
      rethrow;
    }
  }

  /// Pull new telemetry from the server and merge into local database
  Future<void> pullTelemetry(String deviceId, int sinceMs) async {
    try {
      final newRecords = await api.syncTelemetryPull(deviceId, sinceMs);
      print("Pulled ${newRecords.length} records for $deviceId from server.");
      
      if (newRecords.isEmpty) return;

      final List<HistoricValue> parsedValues = [];
      for (var record in newRecords) {
        if (record is Map) {
          final hv = HistoricValue()
            ..tsMs = record['tsMs'] as int?
            ..value = (record['value'] as num?)?.toDouble()
            ..depthCm = (record['depthCm'] as num?)?.toDouble()
            ..kind = 'soil_moisture'; // Assuming soil moisture if not specified
          parsedValues.add(hv);
        }
      }

      if (parsedValues.isNotEmpty) {
        final updated = db.upsertTelemetry(deviceId, parsedValues, isFromCloud: true);
        if (updated) {
          print("Upserted server records into local DB for $deviceId.");
        } else {
          print("No changes required for $deviceId (local DB already up-to-date with server).");
        }
      }
    } catch (e) {
      print("Pull telemetry failed: $e");
      rethrow;
    }
  }

  /// Pull new predictions from the server and merge into local database (Section 1.4.2)
  Future<void> pullPredictions(String deviceId, int sinceMs) async {
    try {
      final newRecords = await api.syncPredictionsPull(deviceId, sinceMs);
      print("Pulled ${newRecords.length} prediction records for $deviceId from server.");
      
      if (newRecords.isEmpty) return;

      final List<Prediction> parsedPreds = [];
      for (var record in newRecords) {
        if (record is Map) {
          final p = Prediction()
            ..tsMs = record['tsMs'] as int?
            ..value = (record['value'] as num?)?.toDouble()
            ..depthCm = (record['depthCm'] as num?)?.toDouble()
            ..kind = record['kind'] as String? ?? 'prediction'
            ..model = record['model'] as String? ?? 'LSTM'
            ..confidence = (record['confidence'] as num?)?.toDouble();
          parsedPreds.add(p);
        }
      }

      if (parsedPreds.isNotEmpty) {
        db.updatePredictions(deviceId, parsedPreds, isFromCloud: true);
        print("Merged ${parsedPreds.length} prediction records into local DB for $deviceId.");
      }
    } catch (e) {
      print("Pull predictions failed: $e");
    }
  }

  /// Discovers registered picos / stations from Cloud API (Section 1.3: GET /api/picos)
  /// and repopulates local Isar DB with station metadata, location, and telemetry history.
  Future<void> discoverAndSyncCloudDevices() async {
    print('[SyncService Verbose] Starting Pico station repopulation routine...');
    try {
      final cloudDevices = await api.getRegisteredDevices();
      print('[SyncService Verbose] Cloud discovery returned ${cloudDevices.length} item(s): $cloudDevices');

      if (cloudDevices.isEmpty) {
        print('[SyncService Verbose] No Pico stations returned from cloud endpoint.');
        return;
      }

      for (int i = 0; i < cloudDevices.length; i++) {
        final devMap = cloudDevices[i];
        print('[SyncService Verbose] Parsing Pico item [$i]: $devMap');
        if (devMap is Map) {
          final id = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? devMap['deviceId'])?.toString();
          final name = (devMap['name'] ?? devMap['deviceName'] ?? 'Pico $id')?.toString() ?? "Pico $id";
          final lat = (devMap['lat'] ?? devMap['latitude'] as num?)?.toDouble();
          final lon = (devMap['lon'] ?? devMap['longitude'] as num?)?.toDouble();

          if (id != null && id.isNotEmpty) {
            print('[SyncService Verbose] Repopulating station "$name" [ID: $id, Lat: $lat, Lon: $lon] in local Isar DB...');
            db.saveDeviceBasic(id, name, lat: lat, lon: lon, isFromCloud: true);
            
            print('[SyncService Verbose] Pulling full telemetry & prediction history for $id (since 0)...');
            await pullTelemetry(id, 0);
            await pullPredictions(id, 0);

            try {
              final status = await api.getStationStatus(id);
              print('[SyncService Verbose] Station $id Status Metadata: $status');
              db.updateDeviceStatus(id, status, isFromCloud: true);
            } catch (statusErr) {
              print('[SyncService Verbose] Station status fetch skipped for $id: $statusErr');
            }

            db.markDeviceSynced(id);
          } else {
            print('[SyncService Verbose] Item [$i] does not contain a valid deviceIdentifier field.');
          }
        }
      }
    } catch (e) {
      print('[SyncService Verbose] Error in discoverAndSyncCloudDevices: $e');
    }
  }
}

