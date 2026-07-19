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
    
    final payload = dirtyDevices.map((d) => {
      'deviceIdentifier': d.deviceIdentifier,
      'updatedAt': d.updatedAt.toIso8601String(),
      'loraEnabled': d.loraEnabled
    }).toList();

    try {
      // Uses the generic API client
      await api.post('/sync', {'devices': payload});

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
    }
  }
}
