import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/models/device.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/location_settings.dart';

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await Isar.initializeIsarCore(download: true);
      } catch (_) {}
    }

    String dirPath = '.';
    try {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    } catch (_) {}

    isar = await Isar.open(
      [DeviceSchema, AppSettingsSchema],
      directory: dirPath, 
    );
    
    // Initialize default settings if missing
    if (isar.appSettings.countSync() == 0) {
      isar.writeTxnSync(() {
        isar.appSettings.putSync(AppSettings());
      });
    }
  }

  // Helper method: Write with auto-retry for unique IDs
  Future<void> saveDevice(Device device) async {
    device.updatedAt = DateTime.now();
    device.isSynced = false;

    await isar.writeTxn(() async {
      final existing = await isar.devices.where().deviceIdentifierEqualTo(device.deviceIdentifier).findFirst();
      if (existing != null) device.id = existing.id;
      await isar.devices.put(device);
    });
  }

  void saveDeviceBasic(String id, String name) {
    isar.writeTxnSync(() {
      final existing = isar.devices.where().deviceIdentifierEqualTo(id).findFirstSync();
      if (existing != null) {
        existing.name = name;
        isar.devices.putSync(existing);
      } else {
        final d = Device()
          ..deviceIdentifier = id
          ..name = name
          ..handshakePassword = '';
        isar.devices.putSync(d);
      }
    });
  }
  
  // Backwards compatibility methods for main.dart
  
  AppSettings getAppSettings() {
    return isar.appSettings.getSync(1) ?? AppSettings();
  }
  
  void saveAppSettings({
    required String tfmServerUrl,
    required int tfmServerPort,
    required String tfmServerApiKey,
    required String selectedTfliteModel,
    required bool invertModelOutput,
    required bool permitOpenMeteoFill,
    required bool alwaysForceInference,
  }) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.tfmServerUrl = tfmServerUrl;
      s.tfmServerPort = tfmServerPort;
      s.tfmServerApiKey = tfmServerApiKey;
      s.selectedTfliteModel = selectedTfliteModel;
      s.invertModelOutput = invertModelOutput;
      s.permitOpenMeteoFill = permitOpenMeteoFill;
      s.alwaysForceInference = alwaysForceInference;
      isar.appSettings.putSync(s);
    });
  }

  LocationSettings getLocationSettings() {
    final s = getAppSettings();
    return LocationSettings(s.manualLat, s.manualLon, s.isGpsEnabled);
  }

  void saveLocationSettings(double lat, double lon, bool isGps) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.manualLat = lat;
      s.manualLon = lon;
      s.isGpsEnabled = isGps;
      isar.appSettings.putSync(s);
    });
  }

  LocationSettings getGpsConfig() {
    final s = getAppSettings();
    return LocationSettings(s.gpsLat, s.gpsLon, true);
  }

  void saveGpsConfig(double lat, double lon) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.gpsLat = lat;
      s.gpsLon = lon;
      isar.appSettings.putSync(s);
    });
  }

  double getMinHumidity() {
    return getAppSettings().minHumidity;
  }

  void saveMinHumidity(double value) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.minHumidity = value;
      isar.appSettings.putSync(s);
    });
  }

  List<Device> getSavedDevices() {
    return isar.devices.where().findAllSync();
  }
  
  void deleteDevice(String id) {
    isar.writeTxnSync(() {
      final dev = isar.devices.where().deviceIdentifierEqualTo(id).findFirstSync();
      if (dev != null) isar.devices.deleteSync(dev.id);
    });
  }

  // --- STUBS for deprecated global methods to keep UI compiling ---
  // The new architecture uses device.historicValues instead of global records.
  
  void saveWeather(int timestamp, double temp, double hum, double rad, double prec) {}
  
  List<WeatherRecord> getWeatherHistory() { return []; }
  
  List<SoilHumidityRecord> getSoilHumidityHistory() {
    return [];
  }

  int getSoilHumidityCount(int sinceMs) {
    return 0;
  }

  int getWeatherCount(int sinceMs) {
    return 0;
  }

  List<PredictionRecord> getPredictionHistory() {
    return [];
  }
  
  void savePrediction(int ts, double predHum, String rec) {}
  
  void clearAllData() {
    isar.writeTxnSync(() {
      isar.devices.clearSync();
    });
  }

  void close() {
    isar.close();
  }
}
