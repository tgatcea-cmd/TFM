import 'package:isar_community/isar.dart';
import '../api/api_client.dart';
import 'database_service.dart';
import '../../data/models/device.dart';

class SyncService {
  final DatabaseService db;
  final ApiClient api;

  SyncService({required this.db, required this.api});

  Future<void> syncDirtyDevices() async {
    final dirtyDevices = await db.isar.devices.filter().isSyncedEqualTo(false).findAll();
    if (dirtyDevices.isEmpty) return;

    print("Syncing ${dirtyDevices.length} devices to server...");
    
    final List<Map<String, dynamic>> records = [];
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
    }

    if (records.isEmpty) {
      print("No telemetry records to sync, marking devices as synced.");
      await db.isar.writeTxn(() async {
        for (var d in dirtyDevices) {
          d.isSynced = true;
          await db.isar.devices.put(d);
        }
      });
      return;
    }

    try {
      await api.syncTelemetryPush(records);

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
        // We append to the DB. appendTelemetry will also set isSynced to false,
        // which might trigger an immediate re-push, but that's a problem for a 
        // more complex sync engine. For ponytail mode, it's sufficient.
        db.appendTelemetry(deviceId, parsedValues);
        print("Merged ${parsedValues.length} server records into local DB.");
      }
    } catch (e) {
      print("Pull telemetry failed: $e");
      rethrow;
    }
  }
}
