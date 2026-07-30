import 'package:tfm_app/core/database/app_database.dart';
import 'package:tfm_app/core/database/secure_storage_service.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/network/cloud_api.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'package:tfm_app/features/ble/ble_controller.dart';
import 'package:tfm_app/features/ml_inference/inference_engine.dart';
import 'package:tfm_app/features/weather/open_meteo_api.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Central facade that initializes all architectural modules.
/// Ready to be consumed by a CLI interface or a UI.
class CliRoutines {
  late final DatabaseService db;
  late final SecureStorageService secureStorage;
  late final ApiClient cloudApi;
  late final BleService bleService;
  late final BleDataProcessor bleProcessor;
  late final InferenceBridge inferenceBridge;

  /// Call this first to initialize the entire application state
  Future<void> init() async {
    print('CLI Routines: Initializing prerequisites...');

    // 0. Prerequisites and status checks:
    // - bluetooth MUST BE enabled
    try {
      if (!await FlutterBluePlus.isSupported) {
        print('CLI Routines Warning: Bluetooth is not supported on this platform.');
      }
    } catch (e) {
      print('CLI Routines Warning: Failed to check Bluetooth support: $e');
    }

    // - location MAY BE enabled
    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        print('CLI Routines Info: Location services are currently disabled.');
      }
    } catch (e) {
      print('CLI Routines Info: Location service check skipped ($e).');
    }

    // 1. Initialize Database & Secure Storage
    db = DatabaseService();
    await db.init();
    secureStorage = SecureStorageService();

    // 2. Initialize Network API
    final settings = db.getAppSettings();
    cloudApi = ApiClient(
      serverUrl: settings.tfmServerUrl,
      port: settings.tfmServerPort,
      apiKey: settings.tfmServerApiKey,
    );

    // 3. Initialize BLE Domain
    bleService = BleService(handshakeModule: PicoHandshakeModule());
    bleProcessor = BleDataProcessor(bleService, db);

    // 4. Initialize Inference Domain
    inferenceBridge = InferenceBridge(db);

    print('CLI Routines Initialization Complete.');
  }

  /// Routine: Push device telemetry to the cloud
  Future<void> pushTelemetry(String deviceId) async {
    print('Pushing telemetry for $deviceId...');
    final telemetry = db.getDeviceTelemetry(deviceId);
    if (telemetry.isEmpty) {
      print('No telemetry found for device.');
      return;
    }
    
    // Map to the JSON format expected by the backend
    final records = telemetry.map<Map<String, dynamic>>((v) => {
      'tsMs': v.tsMs,
      'port': v.port,
      'kind': v.kind,
      'value': v.value,
      'depthCm': v.depthCm,
    }).toList();

    try {
      await cloudApi.syncTelemetryPush(records);
      print('Successfully pushed ${records.length} records.');
    } catch (e) {
      print('Failed to push telemetry: $e');
    }
  }

  /// Routine: Run local machine learning inference
  Future<void> runLocalInference(String deviceId) async {
    print('Starting ML Inference for $deviceId...');
    await inferenceBridge.runIrrigationRecommendation(deviceId);
    print('Inference finished. Verdict: ${inferenceBridge.status.value}');
  }

  /// Routine: Search for Nearby BLE Stations
  Future<List<ScanResult>> searchNearbyDevices() async {
    print('Searching for nearby BLE devices...');
    await bleService.startScan();
    await Future.delayed(const Duration(seconds: 1));
    await bleService.stopScan();
    return bleService.cachedDevices;
  }

  // Routine: Connect to BLE Device
  Future<bool> connectToDevice(BluetoothDevice device, String sharedSecret) async {
    print('Setting up handshake module with secret and connecting...');
    bleService.handshakeModule = PicoHandshakeModule(sharedSecret: sharedSecret);
    return await bleService.connect(device);
  }

  /// Routine: Read station status and update local DB
  Future<Map<String, dynamic>?> readStationStatus() async {
    final status = await bleService.readStatus();
    final devId = bleService.connectedDevice?.remoteId.str;
    if (status != null && devId != null) {
      db.updateDeviceStatus(devId, status);
      print('Persisted station status to DB for $devId.');
    }
    return status;
  }

  /// Routine: Read station configuration and update local DB
  Future<Map<String, dynamic>?> readStationConfig() async {
    final config = await bleService.readConfig();
    final devId = bleService.connectedDevice?.remoteId.str;
    if (config != null && devId != null) {
      db.updateDeviceConfig(devId, config);
      print('Persisted station config to DB for $devId.');
    }
    return config;
  }

  /// Routine: Request station telemetry data and save into local DB
  Future<Object?> requestStationData(String kind, {int? limit = 150}) async {
    final devId = bleService.connectedDevice?.remoteId.str;
    final futureData = bleService.dataStream.first.timeout(const Duration(seconds: 4));
    await bleService.requestData(kind, limit: limit);
    try {
      final data = await futureData;
      if (data is List && devId != null) {
        final List<HistoricValue> parsed = [];
        for (var item in data) {
          if (item is Map) {
            parsed.add(HistoricValue()
              ..tsMs = item['ts_ms'] as int? ?? item['tsMs'] as int? ?? item['hour_ms'] as int?
              ..value = (item['value'] as num?)?.toDouble() ?? (item['mean'] as num?)?.toDouble()
              ..depthCm = (item['depth_cm'] as num?)?.toDouble() ?? (item['depthCm'] as num?)?.toDouble()
              ..kind = item['kind'] as String? ?? 'soil_moisture'
              ..port = item['port'] as int?);
          }
        }
        if (parsed.isNotEmpty) {
          db.upsertTelemetry(devId, parsed, isFromCloud: false);
          print('Persisted ${parsed.length} telemetry records to DB for $devId.');
        }
      }
      return data;
    } catch (e) {
      print('Request station data timeout or error: $e');
      return null;
    }
  }

  /// Routine: Fetch weather forecast from Open-Meteo API, send to BLE station, and persist in local DB
  Future<void> sendHourlyForecast({DateTime? targetReferenceDate}) async {
    final devId = bleService.connectedDevice?.remoteId.str;
    final refDate = targetReferenceDate ?? (devId != null ? db.getReferenceTime(devId) : DateTime.now());
    final now = DateTime.now();
    final bool isEmulated = refDate.day != now.day || refDate.month != now.month || refDate.year != now.year;

    if (isEmulated) {
      print('=== [EMULATION NOTICE] ===');
      print('Operating relative to historical device reference timestamp: $refDate (Target Date: ${refDate.toIso8601String().split('T')[0]})');
      print('==========================');
    }

    print('Fetching location settings...');
    final loc = db.getLocationSettings();
    print('Fetching weather forecast for (${loc.latitude}, ${loc.longitude}) for reference timestamp $refDate via Open-Meteo...');
    final client = OpenMeteoClient(latitude: loc.latitude, longitude: loc.longitude);
    final weatherData = await client.fetchForecast(referenceDate: refDate);

    print('Fetched ${weatherData.temperature2m.length} hourly temperature records.');
    final temps = weatherData.temperature2m;

    List<double> past;
    List<double> future;

    if (temps.length >= 72) {
      // Pico station C firmware expects exactly 48 past hours and 24 future hours
      past = temps.sublist(0, 48);
      future = temps.sublist(48, 72);
    } else {
      final pastCount = (temps.length * 2) ~/ 3;
      past = temps.sublist(0, pastCount);
      future = temps.sublist(pastCount);
    }

    if (devId != null) {
      db.saveWeatherForecast(devId, weatherData);
      print('Persisted weather forecast records to DB for $devId.');
    }

    print('Sending forecast (Past: ${past.length}h, Future: ${future.length}h) to BLE station...');
    await bleService.sendHourlyForecast(past, future);
    print('Hourly forecast successfully transmitted to BLE station.');
  }

  /// Routine: Read latest prediction directly stored in connected BLE device
  Future<String> fetchLatestPredictionFromConnectedDevice() async {
    if (!bleService.isConnected) {
      throw Exception('No BLE device connected.');
    }

    print('[BLE Routine] Requesting latest prediction stored on device...');
    try {
      final streamFuture = bleService.dataStream.first.timeout(const Duration(seconds: 5));
      await bleService.requestData('pred', limit: 24);
      final rawData = await streamFuture;
      
      print('[BLE Routine] Raw prediction payload received: $rawData');
      
      final devId = bleService.connectedDevice?.remoteId.str;
      if (devId != null && devId.isNotEmpty) {
        final List<Prediction> parsedPreds = [];
        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map) {
              parsedPreds.add(Prediction()
                ..tsMs = item['ts_ms'] as int? ?? item['tsMs'] as int?
                ..value = (item['value'] as num?)?.toDouble()
                ..depthCm = (item['depth_cm'] as num?)?.toDouble() ?? (item['depthCm'] as num?)?.toDouble()
                ..kind = item['kind'] as String? ?? 'soil_humidity'
                ..confidence = (item['confidence'] as num?)?.toDouble()
                ..model = item['model'] as String? ?? 'LSTM');
            }
          }
        } else if (rawData is Map) {
          parsedPreds.add(Prediction()
            ..tsMs = rawData['ts_ms'] as int? ?? rawData['tsMs'] as int?
            ..value = (rawData['value'] as num?)?.toDouble()
            ..depthCm = (rawData['depth_cm'] as num?)?.toDouble() ?? (rawData['depthCm'] as num?)?.toDouble()
            ..kind = rawData['kind'] as String? ?? 'soil_humidity'
            ..confidence = (rawData['confidence'] as num?)?.toDouble()
            ..model = rawData['model'] as String? ?? 'LSTM');
        }

        if (parsedPreds.isNotEmpty) {
          db.updatePredictions(devId, parsedPreds, isFromCloud: false);
          print('[BLE Routine] Saved ${parsedPreds.length} prediction record(s) to local DB for $devId.');
        }
      }
      return 'Prediction: $rawData';
    } catch (e) {
      print('[BLE Routine] Fetch prediction error: $e');
      rethrow;
    }
  }

  /// Routine: Trigger station LSTM inference, poll for predictions, and persist in local DB (Steps 7-11)
  Future<String> triggerStationInference() async {
    if (!bleService.isConnected) {
      throw Exception('No BLE device connected.');
    }

    print('Step 7: Fetching latest prediction baseline from station...');
    Object? initialPred;
    try {
      final initialFuture = bleService.dataStream.first.timeout(const Duration(seconds: 4));
      await bleService.requestData('pred', limit: 24);
      initialPred = await initialFuture;
      print('Baseline prediction received: $initialPred');
    } catch (_) {
      print('Baseline prediction timeout/empty.');
    }

    print('Step 8: Sending inference trigger command...');
    await bleService.triggerInference();

    print('Steps 9 & 10: Polling station for new prediction result (up to 6 attempts)...');
    Object? newPred = initialPred;
    bool detectedNew = false;

    for (int attempt = 1; attempt <= 6; attempt++) {
      print('Polling attempt $attempt/6... waiting 3 seconds...');
      await Future.delayed(const Duration(seconds: 3));

      try {
        final pollFuture = bleService.dataStream.first.timeout(const Duration(seconds: 4));
        await bleService.requestData('pred', limit: 24);
        final polledData = await pollFuture;

        if (polledData.toString() != initialPred.toString()) {
          newPred = polledData;
          detectedNew = true;
          print('>>> New inference result detected on attempt $attempt! <<<');
          break;
        }
      } catch (_) {}
    }

    print('Step 11: Finalizing inference result...');
    final devId = bleService.connectedDevice?.remoteId.str;
    if (devId != null && newPred != null) {
      final List<Prediction> parsedPreds = [];
      if (newPred is List) {
        for (var item in newPred) {
          if (item is Map) {
            parsedPreds.add(Prediction()
              ..tsMs = item['ts_ms'] as int? ?? item['tsMs'] as int?
              ..value = (item['value'] as num?)?.toDouble()
              ..depthCm = (item['depth_cm'] as num?)?.toDouble() ?? (item['depthCm'] as num?)?.toDouble()
              ..kind = item['kind'] as String? ?? 'soil_humidity'
              ..confidence = (item['confidence'] as num?)?.toDouble()
              ..model = item['model'] as String? ?? 'LSTM');
          }
        }
      }
      if (parsedPreds.isNotEmpty) {
        db.updatePredictions(devId, parsedPreds);
        print('Persisted ${parsedPreds.length} predictions to DB for $devId.');
      }
    }

    final resultStr = 'Inference Complete (${detectedNew ? "New Result Detected" : "Baseline Kept"}):\n$newPred';
    print(resultStr);
    return resultStr;
  }

  /// Routine: Perform Cloud Emulation purely in RAM (dynamic memory) without mutating local Isar DB
  Future<Map<String, dynamic>> emulateCloudRecommendationInMemory(String deviceId) async {
    print('[Cloud Emulation RAM Verbose] === START RAM EMULATION ROUTINE ===');
    print('[Cloud Emulation RAM Verbose] Station ID: $deviceId');
    
    // 1. Fetch station details (location / coordinates)
    double lat = 40.4168; // Default Madrid
    double lon = -3.7038;
    try {
      final status = await cloudApi.getStationStatus(deviceId);
      print('[Cloud Emulation RAM Verbose] Station status payload from cloud: $status');
      if (status['location'] is Map) {
        lat = (status['location']['lat'] as num?)?.toDouble() ?? lat;
        lon = (status['location']['lon'] as num?)?.toDouble() ?? lon;
      }
    } catch (e) {
      print('[Cloud Emulation RAM Verbose] Station status fetch skipped/defaulted: $e');
    }
    print('[Cloud Emulation RAM Verbose] Target Coordinates: Lat=$lat, Lon=$lon');

    // 2. Fetch latest predictions from Cloud
    double predHum = 0.30;
    DateTime refDate = DateTime.now();

    try {
      final cloudPreds = await cloudApi.syncPredictionsPull(deviceId, 0);
      print('[Cloud Emulation RAM Verbose] Cloud predictions returned count: ${cloudPreds.length}');
      if (cloudPreds.isNotEmpty) {
        final lastPred = cloudPreds.last;
        print('[Cloud Emulation RAM Verbose] Latest cloud prediction raw record: $lastPred');
        if (lastPred is Map) {
          predHum = (lastPred['value'] as num?)?.toDouble() ?? predHum;
          final tsMs = lastPred['tsMs'] as int?;
          if (tsMs != null) {
            refDate = DateTime.fromMillisecondsSinceEpoch(tsMs);
          }
        }
      } else {
        print('[Cloud Emulation RAM Verbose] No predictions returned from Cloud API. Defaulting to now ($refDate) and predHum=$predHum');
      }
    } catch (e) {
      print('[Cloud Emulation RAM Verbose] Prediction pull failed: $e');
    }

    print('[Cloud Emulation RAM Verbose] Reference Timestamp: $refDate (ms: ${refDate.millisecondsSinceEpoch}) | Raw predHum: $predHum');

    // 3. Fetch weather for reference date using OpenMeteoClient
    print('[Cloud Emulation RAM Verbose] Fetching 48h weather forecast from Open-Meteo for ($lat, $lon) relative to $refDate...');
    final weatherClient = OpenMeteoClient(latitude: lat, longitude: lon);
    final weather = await weatherClient.fetchForecast(referenceDate: refDate);
    print('[Cloud Emulation RAM Verbose] Open-Meteo returned ${weather.shortwaveRadiation.length} shortwave radiation hourly records.');

    final double radSum = weather.shortwaveRadiation.isNotEmpty
        ? weather.shortwaveRadiation.reduce((a, b) => a + b)
        : 0.0;

    print('[Cloud Emulation RAM Verbose] Calculated 48h Shortwave Radiation Sum: $radSum J/m²');

    // 4. Run local Random Forest model in RAM
    final settings = db.getAppSettings();
    final result = inferenceBridge.evaluateRecommendation(
      radSum: radSum,
      predHum: predHum,
      refDate: refDate,
      invertModelOutput: settings.invertModelOutput,
      verbosePrefix: '[Cloud RAM Verbose]',
    );

    print('[Cloud Emulation RAM Verbose] Local RF Model Execution Finished in RAM! Verdict: ${result['verdict']}');
    print('[Cloud Emulation RAM Verbose] === END RAM EMULATION ROUTINE ===');
    return {
      'deviceIdentifier': deviceId,
      'referenceDate': refDate.toIso8601String(),
      'predictedHumidity': predHum,
      'shortwaveRadiationSum48h': radSum,
      'verdict': result['verdict'],
      'recommendation': result['recommendation'],
      'isEmulated': result['isEmulated'],
    };
  }

  /// Routine: Clear all local database records (testing utility)
  void clearLocalDatabase() {
    print('Clearing all local database records...');
    db.clearAllData();
    print('Local database successfully cleared.');
  }

  /// Cleanup resources
  void close() {
    db.close();
    bleService.dispose();
  }
}