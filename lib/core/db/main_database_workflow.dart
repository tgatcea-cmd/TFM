import 'dart:io';
import '../api/api_client.dart';
import 'database_service.dart';
import '../../data/models/device.dart';
import 'sync_service.dart';

// ponytail: wiring it all together using the new hierarchy
void main() async {
  // 1. Init API
  final api = ApiClient(baseUrl: "http://localhost:3000/api");

  // 2. Init DB
  final db = DatabaseService();
  await db.init();

  // 3. Write Example using the DB layer
  final device = Device()
    ..deviceIdentifier = 'MAC:11:22:33'
    ..handshakePassword = 'secret_handshake'
    ..localInferenceCapabilities = true
    ..historicValues = [
      HistoricValue()..tsMs = DateTime.now().millisecondsSinceEpoch..depthCm = 30.0..value = 0.82
    ];

  await db.saveDevice(device);
  print("Saved device locally.");

  // 4. Run Sync using the separated Sync Service
  final syncService = SyncService(db: db, api: api);
  await syncService.syncDirtyDevices();

  print('\nInspector running. Press Enter to close Isar and exit...');
  stdin.readLineSync();

  await db.isar.close();
}
