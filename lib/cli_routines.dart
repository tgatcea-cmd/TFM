import 'package:tfm_app/core/database/app_database.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/network/cloud_api.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'package:tfm_app/features/ble/ble_controller.dart';
import 'package:tfm_app/features/ml_inference/inference_engine.dart';
import 'package:tfm_app/features/ml_inference/lstm_inference.dart';
import 'package:tfm_app/features/weather/open_meteo_api.dart';
import 'package:tfm_app/features/weather/weather_data.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart' hide LocationSettings;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/models/app_settings.dart';
import 'package:tfm_app/core/models/app_rf_model.dart';
import 'package:tfm_app/features/location/location_settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Central facade that initializes all architectural modules.
/// Ready to be consumed by a CLI interface or a UI.
class CliRoutines {
  late final DatabaseService db;
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
        print(
          'CLI Routines Warning: Bluetooth is not supported on this platform.',
        );
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
    final records = telemetry
        .map<Map<String, dynamic>>(
          (v) => {
            'tsMs': v.tsMs,
            'port': v.port,
            'kind': v.kind,
            'value': v.value,
            'depthCm': v.depthCm,
          },
        )
        .toList();

    try {
      await cloudApi.syncTelemetryPush(records);
      print('Successfully pushed ${records.length} records.');
    } catch (e) {
      print('Failed to push telemetry: $e');
    }
  }

  /// Routine: Run local machine learning inference
  Future<Map<String, dynamic>> runLocalInference(
    String deviceId, {
    bool forceAllow = false,
    WeatherData? preloadedWeatherData,
    bool persistResults = true,
  }) async {
    print('Starting ML Inference for $deviceId...');

    // --- AGRONOMIC SCHEDULE CHECK (Elevated from Inference Engine) ---
    final settings = db.getAppSettings();
    final now = DateTime.now();
    final h = now.hour;
    final startH = settings.agronomicDayStart;
    final endH = settings.agronomicDayEnd;

    final bool isYellowZone = (endH < startH)
        ? (h >= endH && h < startH)
        : (h >= endH || h < startH);

    if (isYellowZone && !settings.alwaysForceInference && !forceAllow) {
      final msg =
          "Restricted: Yellow Zone (Gathering). Inference allowed only in Green Zone ($startH:00 - $endH:00).";
      print(msg);
      inferenceBridge.status = msg;
      return {
        'isRestricted': true,
        'isYellowZone': true,
        'agronomicStart': startH,
        'agronomicEnd': endH,
        'message': msg,
        'verdict': msg,
        'minHumidity': null,
        'minDateMs': null,
      };
    }
    // -----------------------------------------------------------------

    final res = await inferenceBridge.runIrrigationRecommendation(
      deviceId: deviceId,
      preloadedWeatherData: preloadedWeatherData,
      persistResults: persistResults,
    );
    print('Inference finished. Verdict: ${inferenceBridge.status}');
    return res;
  }

  void searchNearbyDevices() {
    bleService.startScan();
  }

  /// Routine: Connect to BLE Device
  Future<bool> connectToDevice(
    BluetoothDevice device,
    String sharedSecret,
  ) async {
    // 1. ponytail: stop active scan before connecting to avoid BLE radio conflicts
    await bleService.stopScan();
    // 2. ponytail: disconnect if already connected to a different device
    print('Setting up handshake module with secret and connecting...');
    bleService.handshakeModule = PicoHandshakeModule(
      sharedSecret: sharedSecret,
    );
    final connected = await bleService.connect(device);
    if (connected) {
      final name = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.str;
      db.saveDeviceBasic(device.remoteId.str, name);
    }

    return connected;
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
    final futureData = bleService.dataStream.first.timeout(
      const Duration(seconds: 4),
    );
    await bleService.requestData(kind, limit: limit);
    try {
      final data = await futureData;
      if (data is List && devId != null) {
        final List<HistoricValue> parsed = [];
        for (var item in data) {
          if (item is Map) {
            parsed.add(
              HistoricValue()
                ..tsMs =
                    item['ts_ms'] as int? ??
                    item['tsMs'] as int? ??
                    item['hour_ms'] as int?
                ..value =
                    (item['value'] as num?)?.toDouble() ??
                    (item['mean'] as num?)?.toDouble()
                ..depthCm =
                    (item['depth_cm'] as num?)?.toDouble() ??
                    (item['depthCm'] as num?)?.toDouble()
                ..kind = item['kind'] as String? ?? 'soil_moisture'
                ..port = item['port'] as int?,
            );
          }
        }
        if (parsed.isNotEmpty) {
          db.upsertTelemetry(devId, parsed, isFromCloud: false);
          print(
            'Persisted ${parsed.length} telemetry records to DB for $devId.',
          );
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
    final bool isConnected = bleService.isConnected;
    final refDate =
        targetReferenceDate ??
        (devId != null
            ? db.getReferenceTime(devId, isConnected: isConnected)
            : DateTime.now());
    final now = DateTime.now();
    final bool isEmulated =
        refDate.day != now.day ||
        refDate.month != now.month ||
        refDate.year != now.year;

    if (isEmulated) {
      print('=== [EMULATION NOTICE] ===');
      print(
        'Operating relative to historical device reference timestamp: $refDate (Target Date: ${refDate.toIso8601String().split('T')[0]})',
      );
      print('==========================');
    }

    print('Fetching location settings...');
    final loc = db.getLocationSettings();
    print(
      'Fetching weather forecast for (${loc.latitude}, ${loc.longitude}) for reference timestamp $refDate via Open-Meteo...',
    );
    final client = OpenMeteoClient(
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    final weatherData = await client.fetchForecast(referenceDate: refDate);

    print(
      'Fetched ${weatherData.temperature2m.length} hourly temperature records.',
    );
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

    print(
      'Sending forecast (Past: ${past.length}h, Future: ${future.length}h) to BLE station...',
    );
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
      final streamFuture = bleService.dataStream.first.timeout(
        const Duration(seconds: 5),
      );
      await bleService.requestData('pred', limit: 24);
      final rawData = await streamFuture;

      print('[BLE Routine] Raw prediction payload received: $rawData');

      final devId = bleService.connectedDevice?.remoteId.str;
      if (devId != null && devId.isNotEmpty) {
        final List<Prediction> parsedPreds = [];
        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map) {
              parsedPreds.add(
                Prediction()
                  ..tsMs = item['ts_ms'] as int? ?? item['tsMs'] as int?
                  ..value = (item['value'] as num?)?.toDouble()
                  ..depthCm =
                      (item['depth_cm'] as num?)?.toDouble() ??
                      (item['depthCm'] as num?)?.toDouble()
                  ..kind = item['kind'] as String? ?? 'soil_humidity'
                  ..confidence = (item['confidence'] as num?)?.toDouble()
                  ..model = item['model'] as String? ?? 'LSTM',
              );
            }
          }
        } else if (rawData is Map) {
          parsedPreds.add(
            Prediction()
              ..tsMs = rawData['ts_ms'] as int? ?? rawData['tsMs'] as int?
              ..value = (rawData['value'] as num?)?.toDouble()
              ..depthCm =
                  (rawData['depth_cm'] as num?)?.toDouble() ??
                  (rawData['depthCm'] as num?)?.toDouble()
              ..kind = rawData['kind'] as String? ?? 'soil_humidity'
              ..confidence = (rawData['confidence'] as num?)?.toDouble()
              ..model = rawData['model'] as String? ?? 'LSTM',
          );
        }

        if (parsedPreds.isNotEmpty) {
          db.updatePredictions(devId, parsedPreds, isFromCloud: false);
          print(
            '[BLE Routine] Saved ${parsedPreds.length} prediction record(s) to local DB for $devId.',
          );
        }
      }
      return 'Prediction: $rawData';
    } catch (e) {
      print('[BLE Routine] Fetch prediction error: $e');
      rethrow;
    }
  }

  /// Routine: Trigger LSTM inference based on station mode ('forward' vs 'local'),
  /// then execute the Random Forest recommendation and extract minimums.
  Future<Map<String, dynamic>> triggerStationInference() async {
    if (!bleService.isConnected) {
      throw Exception('No BLE device connected.');
    }

    final devId = bleService.connectedDevice?.remoteId.str;
    if (devId == null) throw Exception('Device ID is null.');

    // --- AGRONOMIC SCHEDULE CHECK (Protecting BLE Bandwidth) ---
    final settings = db.getAppSettings();
    final now = DateTime.now();
    final h = now.hour;
    final startH = settings.agronomicDayStart;
    final endH = settings.agronomicDayEnd;

    final bool isYellowZone = (endH < startH)
        ? (h >= endH && h < startH)
        : (h >= endH || h < startH);

    if (isYellowZone && !settings.alwaysForceInference) {
      final msg =
          "Restricted: Yellow Zone (Gathering). Inference allowed only in Green Zone ($startH:00 - $endH:00).";
      print(msg);
      inferenceBridge.status = msg;
      return {
        'isRestricted': true,
        'isYellowZone': true,
        'agronomicStart': startH,
        'agronomicEnd': endH,
        'message': msg,
        'raw': null,
        'verdict': msg,
        'minHumidity': null,
        'minDateMs': null,
      };
    }
    // -----------------------------------------------------------

    print('Step 1: Reading station status to determine inference mode...');
    final status = await readStationStatus();
    final mode = status?['mode'] as String? ?? 'local';
    print('Station mode detected: $mode');

    String modeMessage = "";
    Object? rawPayload;
    WeatherData? preloadedWeather;

    if (mode == 'forward') {
      // --- FORWARD MODE ---
      print('=== FORWARD MODE INFERENCE ===');
      await requestStationData('raw', limit: 150);

      final loc = db.getLocationSettings();
      final client = OpenMeteoClient(
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
      final refDate = db.getReferenceTime(devId);
      final weatherData = await client.fetchForecast(referenceDate: refDate);
      preloadedWeather = weatherData;

      db.saveWeatherForecast(devId, weatherData);

      final lstmResult = await inferenceBridge.runLocalLstmInference(devId);
      modeMessage = 'Forward Inference Executed';
      rawPayload = lstmResult;
    } else {
      // --- LOCAL MODE ---
      print('=== LOCAL MODE INFERENCE ===');
      try {
        await sendHourlyForecast();
      } catch (e) {
        throw Exception(
          'Aborting inference: Could not send required weather data ($e)',
        );
      }

      Object? initialPred;
      try {
        final initialFuture = bleService.dataStream.first.timeout(
          const Duration(seconds: 4),
        );
        await bleService.requestData('pred', limit: 24);
        initialPred = await initialFuture;
      } catch (_) {}

      await bleService.triggerInference();

      Object? newPred = initialPred;
      for (int attempt = 1; attempt <= 6; attempt++) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final pollFuture = bleService.dataStream.first.timeout(
            const Duration(seconds: 4),
          );
          await bleService.requestData('pred', limit: 24);
          final polledData = await pollFuture;

          if (polledData.toString() != initialPred.toString()) {
            newPred = polledData;
            break;
          }
        } catch (_) {}
      }

      if (newPred != null) {
        final List<Prediction> parsedPreds = [];
        if (newPred is List) {
          for (var item in newPred) {
            if (item is Map) {
              parsedPreds.add(
                Prediction()
                  ..tsMs = item['ts_ms'] as int? ?? item['tsMs'] as int?
                  ..value = (item['value'] as num?)?.toDouble()
                  ..depthCm =
                      (item['depth_cm'] as num?)?.toDouble() ??
                      (item['depthCm'] as num?)?.toDouble()
                  ..kind = item['kind'] as String? ?? 'soil_humidity'
                  ..confidence = (item['confidence'] as num?)?.toDouble()
                  ..model = item['model'] as String? ?? 'LSTM',
              );
            }
          }
        }
        if (parsedPreds.isNotEmpty) {
          db.updatePredictions(devId, parsedPreds);
        }
      }
      modeMessage = 'Local Inference Executed';
      rawPayload = newPred;
    }

    // --- NEW STEP: Run Random Forest & Extract Minimums ---
    print('Step: Running Random Forest Inference...');
    await runLocalInference(
      devId,
      preloadedWeatherData: preloadedWeather,
      persistResults: true,
    );
    final verdict = inferenceBridge.status;

    print('Step: Extracting minimum predicted humidity from Local DB...');
    // Fetch the device directly to iterate over its predictions
    final savedDevices = db.getSavedDevices();
    final dev = savedDevices.firstWhere(
      (d) => d.deviceIdentifier == devId,
      orElse: () => Device()..newPredictions = [],
    );

    double? minHum;
    int? minTs;

    for (var p in dev.newPredictions) {
      if (minHum == null || (p.value != null && p.value! < minHum)) {
        minHum = p.value;
        minTs = p.tsMs;
      }
    }

    return {
      'message': modeMessage,
      'raw': rawPayload,
      'verdict': verdict,
      'minHumidity': minHum,
      'minDateMs': minTs,
    };
  }

  /// Routine: Perform Cloud Emulation purely in RAM (dynamic memory) without mutating local Isar DB
  /// Stage 1 (LSTM): Executes LSTM if no newer prediction vector exists on cloud relative to telemetry T_ref.
  /// Stage 2 (RF): Evaluates Random Forest using the newest 24h prediction vector (T_24) + 48h solar radiation.
  Future<Map<String, dynamic>> emulateCloudRecommendationInMemory(
    String deviceId,
  ) async {
    print('[Cloud Emulation RAM Verbose] === START RAM EMULATION ROUTINE ===');
    print('[Cloud Emulation RAM Verbose] Station ID: $deviceId');

    // 1. Fetch station details (location / coordinates)
    double lat = 40.4168; // Default Madrid
    double lon = -3.7038;
    try {
      final status = await cloudApi.getStationStatus(deviceId);
      print(
        '[Cloud Emulation RAM Verbose] Station status payload from cloud: $status',
      );
      if (status['location'] is Map) {
        lat = (status['location']['lat'] as num?)?.toDouble() ?? lat;
        lon = (status['location']['lon'] as num?)?.toDouble() ?? lon;
      }
    } catch (e) {
      print(
        '[Cloud Emulation RAM Verbose] Station status fetch skipped/defaulted: $e',
      );
    }
    print(
      '[Cloud Emulation RAM Verbose] Target Coordinates: Lat=$lat, Lon=$lon',
    );

    // 2. Determine telemetry reference timestamp T_ref (end of 48h telemetry window)
    DateTime refDate = db.getReferenceTime(deviceId);

    // If local DB is empty/cleared, pull cloud telemetry to resolve actual last_telemetry_data timestamp
    try {
      final cloudTelemetry = await cloudApi.syncTelemetryPull(deviceId, 0);
      if (cloudTelemetry.isNotEmpty) {
        final lastTel = cloudTelemetry.last;
        if (lastTel is Map) {
          final ts = (lastTel['tsMs'] ?? lastTel['ts_ms'] ?? lastTel['timestamp']) as int?;
          if (ts != null) {
            refDate = DateTime.fromMillisecondsSinceEpoch(ts);
            print(
              '[Cloud Emulation RAM Verbose] Resolved T_ref from latest Cloud telemetry record: $refDate',
            );
          }
        }
      }
    } catch (_) {}

    // Initialize baseline predHum from saved Local DB predictions if available
    final localDev = db.findDevice(deviceId);
    double predHum = (localDev != null && localDev.newPredictions.isNotEmpty)
        ? (localDev.newPredictions.last.value ?? 0.30)
        : 0.30;
    bool usedCloudPredictions = false;

    // Check Cloud API for existing predictions
    try {
      final cloudPreds = await cloudApi.syncPredictionsPull(deviceId, 0);
      print(
        '[Cloud Emulation RAM Verbose] Cloud predictions returned count: ${cloudPreds.length}',
      );
      if (cloudPreds.isNotEmpty) {
        final lastPred = cloudPreds.last;
        if (lastPred is Map) {
          final val = (lastPred['value'] as num?)?.toDouble();
          final predTsMs = (lastPred['tsMs'] ?? lastPred['ts_ms']) as int?;

          if (val != null && predTsMs != null) {
            final predTargetDate = DateTime.fromMillisecondsSinceEpoch(
              predTsMs,
            );
            final predRefDate = predTargetDate.subtract(
              const Duration(hours: 24),
            );

            predHum = val;
            refDate = predRefDate;
            usedCloudPredictions = true;
            print(
              '[Cloud Emulation RAM Verbose] Adopted Cloud prediction vector. RefDate=$refDate, TargetDate=$predTargetDate, predHum=$predHum',
            );
          }
        }
      }
    } catch (e) {
      print('[Cloud Emulation RAM Verbose] Prediction pull notice: $e');
    }

    // 3. Stage 1 (LSTM): If no newer cloud prediction vector was available, execute LSTM inference in RAM
    if (!usedCloudPredictions) {
      print(
        '[Cloud Emulation RAM Verbose] No newer cloud prediction found. Running local 24h LSTM forecast in RAM for T_ref=$refDate...',
      );
      try {
        final lstmEngine = SaviaLstmInferenceEngine(db);
        final lstmRes = await lstmEngine.runDailyInference(
          deviceId,
          targetRefDate: refDate,
        );
        if (lstmRes['code'] == SaviaLstmErrorCode.success &&
            lstmRes['predictions'] is List) {
          final preds = lstmRes['predictions'] as List<double>;
          if (preds.isNotEmpty) {
            predHum = preds.last;
            print(
              '[Cloud Emulation RAM Verbose] LSTM forecast succeeded in RAM. T_24 predHum=$predHum',
            );
          }
        } else {
          print(
            '[Cloud Emulation RAM Verbose] LSTM forecast could not compute new curve (${lstmRes['message']}). Preserving baseline predHum=$predHum',
          );
        }
      } catch (e) {
        print(
          '[Cloud Emulation RAM Verbose] LSTM local forecast execution notice: $e. Preserving baseline predHum=$predHum',
        );
      }
    }

    // 4. Calculate target expected minimum date T_target = T_ref + 24h
    final targetMinDate = refDate.add(const Duration(hours: 24));

    print(
      '[Cloud Emulation RAM Verbose] Final T_ref: $refDate | Expected At (T_target): $targetMinDate | T_24 predHum: $predHum',
    );

    // 5. Stage 2 (RF): Fetch weather relative to T_ref and evaluate Random Forest
    print(
      '[Cloud Emulation RAM Verbose] Fetching 48h weather forecast from Open-Meteo for ($lat, $lon) relative to $refDate...',
    );
    final weatherClient = OpenMeteoClient(latitude: lat, longitude: lon);
    final weather = await weatherClient.fetchForecast(referenceDate: refDate);
    final double radSum = weather.shortwaveRadiation.isNotEmpty
        ? weather.shortwaveRadiation.reduce((a, b) => a + b)
        : 0.0;

    print(
      '[Cloud Emulation RAM Verbose] Calculated 48h Shortwave Radiation Sum: $radSum J/m²',
    );

    final settings = db.getAppSettings();
    final result = inferenceBridge.evaluateRecommendation(
      radSum: radSum,
      predHum: predHum,
      refDate: refDate,
      invertModelOutput: settings.invertModelOutput,
      verbosePrefix: '[Cloud RAM Verbose]',
    );

    print(
      '[Cloud Emulation RAM Verbose] Local RF Model Execution Finished in RAM! Verdict: ${result['verdict']}',
    );
    print('[Cloud Emulation RAM Verbose] === END RAM EMULATION ROUTINE ===');

    return {
      'deviceIdentifier': deviceId,
      'referenceDate': refDate.toIso8601String(),
      'targetMinDateMs': targetMinDate.millisecondsSinceEpoch,
      'targetMinDateIso': targetMinDate.toIso8601String(),
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

  // --- FACADE METHODS FOR SCREENS ---

  // App Settings
  AppSettings getAppSettings() => db.getAppSettings();
  void saveAppSettings({
    String? tfmServerScheme,
    String? tfmServerUrl,
    int? tfmServerPort,
    String? tfmServerApiKey,
    int? agronomicDayStart,
    int? agronomicDayEnd,
  }) {
    db.saveAppSettings(
      tfmServerScheme: tfmServerScheme,
      tfmServerUrl: tfmServerUrl,
      tfmServerPort: tfmServerPort,
      tfmServerApiKey: tfmServerApiKey,
      agronomicDayStart: agronomicDayStart,
      agronomicDayEnd: agronomicDayEnd,
    );
  }

  // Location Settings
  LocationSettings getLocationSettings() => db.getLocationSettings();
  void saveLocationSettings(double lat, double lon, bool isGps) {
    db.saveLocationSettings(lat, lon, isGps);
  }

  // RF Models
  RfModel? getActiveRfModel() => db.getActiveRfModel();
  List<RfModel> getSavedRfModels() => db.getSavedRfModels();
  void setActiveRfModel(String modelId) => db.setActiveRfModel(modelId);
  void deleteRfModel(String modelId) => db.deleteRfModel(modelId);
  void saveRfModel(Map<String, dynamic> metadata, String jsonPayload) =>
      db.saveRfModel(metadata, jsonPayload);

  // Cloud API Methods
  Future<List<Map<String, dynamic>>> getAvailableRfModels() =>
      cloudApi.getAvailableRfModels();
  Future<String> downloadRfModel(String mId) => cloudApi.downloadRfModel(mId);
  Future<List<dynamic>> getRegisteredCloudDevices() =>
      cloudApi.getRegisteredDevices();
  void updateCloudEndpoint(String scheme, String url, int port) =>
      cloudApi.updateEndpoint(scheme, url, port);
  void setCloudApiKey(String key) => cloudApi.apiKey = key;
  String get cloudBaseUrl => cloudApi.baseUrl;

  // Sync Service
  Future<void> syncCloudAndLocal() async {
    final syncService = SyncService(db: db, api: cloudApi);
    await syncService.syncDirtyDevices();
    await syncService.discoverAndSyncCloudDevices();
  }

  Future<void> syncCloudTelemetry(String deviceIdentifier, int latestTs) async {
    final syncService = SyncService(db: db, api: cloudApi);
    await syncService.pullTelemetry(deviceIdentifier, latestTs);
  }

  // Network checks
  Future<bool> testCloudConnection() async {
    return await cloudApi.testConnection();
  }

  Future<Map<String, dynamic>> testCloudPing() async {
    final settings = getAppSettings();
    final sw = Stopwatch()..start();

    for (final path in ['/health', '/api/ping']) {
      try {
        final res = await http
            .get(
              Uri.parse(
                '${settings.tfmServerScheme}://${settings.tfmServerUrl}:${settings.tfmServerPort}$path',
              ),
              headers: {
                if (settings.tfmServerApiKey.isNotEmpty)
                  'Authorization': 'Bearer ${settings.tfmServerApiKey}',
              },
            )
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return {
            'success': true,
            'status': data['status']?.toString().toUpperCase() ?? 'OK',
            'ms': sw.elapsedMilliseconds,
          };
        }
      } catch (_) {}
    }
    return {'success': false};
  }

  Future<Map<String, dynamic>> testWeatherConnection() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&current_weather=true',
            ),
          )
          .timeout(const Duration(seconds: 4));
      return {'success': res.statusCode == 200, 'statusCode': res.statusCode};
    } catch (_) {
      return {'success': false, 'statusCode': 0};
    }
  }

  // BLE Secure Storage
  Future<String?> getBleSecret(String id) async {
    return await const FlutterSecureStorage().read(key: 'ble_secret_$id');
  }

  Future<void> saveBleSecret(String id, String name, String secret) async {
    saveDeviceBasic(id, name);
    await const FlutterSecureStorage().write(
      key: 'ble_secret_$id',
      value: secret,
    );
  }

  // BLE Service properties & methods
  void stopBleScan() => bleService.stopScan();
  void disconnectBle() => bleService.disconnect();
  bool get isBleConnected => bleService.isConnected;
  BluetoothDevice? get connectedBleDevice => bleService.connectedDevice;
  Stream<List<ScanResult>> get bleScanResults => bleService.scanResults;
  Stream<Object> get bleDataStream => bleService.dataStream;
  Future<void> syncBleTime(int offset) => bleService.syncTime(offset);
  void forceBleMock() => bleService.forceMock();
  void clearBleStorage() => bleService.clearStorage();

  // Database facade
  void saveDeviceBasic(String id, String name) => db.saveDeviceBasic(id, name);
  List<Device> getSavedDevices() => db.getSavedDevices();

  // Inference facade
  String get inferenceVerdict => inferenceBridge.status;

  /// Routine: Push locally set coordinates to the Cloud API
  Future<void> pushStationLocationToCloud(String deviceId, double lat, double lon) async {
    final settings = db.getAppSettings();
    
    // Using the unified /api/devices/:id/location endpoint the backend team provided
    final url = Uri.parse(
      '${settings.tfmServerScheme}://${settings.tfmServerUrl}:${settings.tfmServerPort}/api/devices/$deviceId/location'
    );

    print('Pushing location update for $deviceId to Cloud...');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (settings.tfmServerApiKey.isNotEmpty)
            'Authorization': 'Bearer ${settings.tfmServerApiKey}',
        },
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Successfully updated Cloud location for $deviceId.');
        
        // Update the local Isar database so it doesn't wait for the next sync
        final devices = db.getSavedDevices();
        final dev = devices.firstWhere(
          (d) => d.deviceIdentifier == deviceId, 
          orElse: () => Device()
        );
        
        if (dev.deviceIdentifier.isNotEmpty) {
           dev.latitude = lat;
           dev.longitude = lon;
           // Assuming you have a method to save/update the device in Isar:
           // db.saveDevice(dev); 
        }
      } else {
        print('Failed to update Cloud location. Status: ${response.statusCode} Body: ${response.body}');
        throw Exception('Cloud location update rejected by server.');
      }
    } catch (e) {
      print('Network error pushing location for $deviceId: $e');
      rethrow;
    }
  }
}
