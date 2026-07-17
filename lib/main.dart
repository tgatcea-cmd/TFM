import "dart:async";
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/processed/daily_weather.dart';
import 'data/models/weather_data.dart';
import 'data/models/models.dart';

import 'core/api/open_meteo_client.dart';
import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';

import 'logic/inference/inference_bridge.dart';

//import 'logic/ble_data_processor.dart';
import 'logic/location_service.dart';
import 'logic/weather_processor.dart';

import 'ui/views/config_view.dart';
import 'ui/views/sync_progress_dialog.dart';
import 'ui/views/telemetry_view.dart';
import 'ui/styles.dart';

/// ################### Providers ###################

// Desfase de tiempo en horas para depurar las etapas visuales del gráfico
final timeOffsetProvider = StateProvider<int>((ref) => 0); 

final databaseTriggerProvider = StateProvider<int>((ref) => 0);

final dbProvider = Provider<DatabaseService>((ref) {
  final db = DatabaseService();
  ref.onDispose(() => db.close());
  return db;
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationSettings>((ref) {
      return LocationNotifier(
        ref.watch(dbProvider),
        ref.watch(locationServiceProvider),
      );
    });

class LocationNotifier extends StateNotifier<LocationSettings> {
  final DatabaseService _db;
  final LocationService _service;

  LocationNotifier(this._db, this._service) : super(_db.getLocationSettings());

  Future<void> updateFromGps() async {
    final pos = await _service.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      _db.saveLocationSettings(pos.latitude, pos.longitude, true);
      _db.saveGpsConfig(pos.latitude, pos.longitude);
      state = _db.getLocationSettings();
    }
  }

  void updateManual(double lat, double lon) {
    _db.saveLocationSettings(lat, lon, false);
    state = _db.getLocationSettings();
  }
}

// ponytail: Reactive provider for configurable minimum humidity measurement
final minHumidityProvider = StateNotifierProvider<MinHumidityNotifier, double>((ref) {
  return MinHumidityNotifier(ref.watch(dbProvider));
});

class MinHumidityNotifier extends StateNotifier<double> {
  final DatabaseService _db;
  MinHumidityNotifier(this._db) : super(_db.getMinHumidity());

  void setMinHumidity(double value) {
    _db.saveMinHumidity(value);
    state = value;
  }
}

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService(handshakeModule: PicoHandshakeModule());
  ref.onDispose(() => service.dispose());
  return service;
});

final bleConnectedProvider = StateProvider<bool>((ref) {
  final ble = ref.watch(bleServiceProvider);
  final sub = ble.connectionStateStream.listen((connected) {
    ref.controller.state = connected;
  });
  ref.onDispose(() => sub.cancel());
  return ble.isConnected;
});

final scanResultsProvider = StreamProvider<List<ScanResult>>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.scanResults;
});

final savedDevicesTriggerProvider = StateProvider<int>((ref) => 0);

final mergedDevicesProvider = Provider<List<DisplayDevice>>((ref) {
  final scanResultsAsync = ref.watch(scanResultsProvider);
  final scanResults = scanResultsAsync.value ?? const [];

  ref.watch(savedDevicesTriggerProvider);

  final db = ref.watch(dbProvider);
  final savedList = db.getSavedDevices();
  final Map<String, DisplayDevice> map = {};

  for (final d in savedList) {
    map[d.id] = DisplayDevice(id: d.id, name: d.name, isSaved: true);
  }

  for (final r in scanResults) {
    // Filter to keep only devices advertising target service
    final hasService = r.advertisementData.serviceUuids.any((uuid) {
      final uuidStr = uuid.toString().toLowerCase();
      return uuidStr.contains('5a71a000');
    });
    if (!hasService) continue;

    final mac = r.device.remoteId.toString();
    final name = r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : r.device.platformName;
    final cleanName = name.isEmpty ? "Unknown Station" : name;

    if (map.containsKey(mac)) {
      final saved = map[mac]!;
      map[mac] = DisplayDevice(
        id: mac,
        name: saved.name.isNotEmpty ? saved.name : cleanName,
        isSaved: true,
        scanResult: r,
        rssi: r.rssi,
      );
    } else {
      map[mac] = DisplayDevice(
        id: mac,
        name: cleanName,
        isSaved: false,
        scanResult: r,
        rssi: r.rssi,
      );
    }
  }

  return map.values.toList();
});

final bleProcessorProvider = Provider<BleDataProcessor>((ref) {
  final ble = ref.watch(bleServiceProvider);
  final db = ref.watch(dbProvider);
  
  // 2. PASS THE TRIGGER CALLBACK HERE
  final processor = BleDataProcessor(ble, db, onDbUpdated: () {
    ref.read(databaseTriggerProvider.notifier).state++;
  });

  processor.startListening();
  return processor;
});

final weatherClientProvider = Provider<OpenMeteoClient>((ref) {
  final db = ref.watch(dbProvider);
  final gpsLoc = db.getGpsConfig();
  return OpenMeteoClient(
    latitude: gpsLoc.latitude,
    longitude: gpsLoc.longitude,
  );
});

class WeatherState {
  final ProcessedWeatherDay? daily;
  final List<double> hourlyForecast;
  final List<double> hourlyRadiationForecast;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  WeatherState({
    this.daily,
    this.hourlyForecast = const [],
    this.hourlyRadiationForecast = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((
  ref,
) {
  return WeatherNotifier();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(weatherClientProvider), ref);
});

enum SyncStage {
  idle,
  connecting,
  pairing,
  refreshing,
  waitingBypass,
  completed,
  failed,
}

class SyncProgressState {
  final SyncStage stage;
  final double connectingProgress;
  final double pairingProgress;
  final double refreshingProgress;
  final String statusMessage;
  final String? errorMessage;
  final int hoursToWait;

  SyncProgressState({
    required this.stage,
    required this.connectingProgress,
    required this.pairingProgress,
    required this.refreshingProgress,
    required this.statusMessage,
    this.errorMessage,
    this.hoursToWait = 0,
  });

  SyncProgressState copyWith({
    SyncStage? stage,
    double? connectingProgress,
    double? pairingProgress,
    double? refreshingProgress,
    String? statusMessage,
    String? errorMessage,
    int? hoursToWait,
  }) {
    return SyncProgressState(
      stage: stage ?? this.stage,
      connectingProgress: connectingProgress ?? this.connectingProgress,
      pairingProgress: pairingProgress ?? this.pairingProgress,
      refreshingProgress: refreshingProgress ?? this.refreshingProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      hoursToWait: hoursToWait ?? this.hoursToWait,
    );
  }
}

class ConnectionSyncProgressNotifier extends StateNotifier<SyncProgressState> {
  final Ref _ref;
  final Map<String, DateTime> _lockouts = {};
  Completer<bool>? _bypassCompleter;

  ConnectionSyncProgressNotifier(this._ref)
    : super(
        SyncProgressState(
          stage: SyncStage.idle,
          connectingProgress: 0.0,
          pairingProgress: 0.0,
          refreshingProgress: 0.0,
          statusMessage: '',
        ),
      );

  void reset() {
    state = SyncProgressState(
      stage: SyncStage.idle,
      connectingProgress: 0.0,
      pairingProgress: 0.0,
      refreshingProgress: 0.0,
      statusMessage: '',
    );
    _bypassCompleter = null;
  }

  Future<bool> requestBypass(int hours, String deviceId) async {
    _bypassCompleter = Completer<bool>();
    state = state.copyWith(
      stage: SyncStage.waitingBypass,
      hoursToWait: hours,
      statusMessage: 'Station has insufficient data ($hours hrs missing).',
    );
    final proceed = await _bypassCompleter!.future;
    _bypassCompleter = null;
    if (!proceed) {
      _lockouts[deviceId] = DateTime.now().add(Duration(hours: hours));
    }
    return proceed;
  }

  void submitBypassDecision(bool proceed) {
    if (_bypassCompleter != null && !_bypassCompleter!.isCompleted) {
      _bypassCompleter!.complete(proceed);
    }
  }

  Future<bool> startSequence(BluetoothDevice device) async {
    final bleService = _ref.read(bleServiceProvider);
    final deviceId = device.remoteId.toString();

    // Check lockout first
    final lockoutUntil = _lockouts[deviceId];
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now());
      final hoursRemaining = (remaining.inSeconds / 3600.0).ceil();

      _bypassCompleter = Completer<bool>();
      state = SyncProgressState(
        stage: SyncStage.waitingBypass,
        connectingProgress: 0.0,
        pairingProgress: 0.0,
        refreshingProgress: 0.0,
        hoursToWait: hoursRemaining,
        statusMessage:
            'Device has a pending wait time ($hoursRemaining hrs remaining).',
      );

      final proceed = await _bypassCompleter!.future;
      _bypassCompleter = null;
      if (!proceed) {
        state = state.copyWith(stage: SyncStage.idle);
        return false;
      }
    }

    state = SyncProgressState(
      stage: SyncStage.connecting,
      connectingProgress: 0.0,
      pairingProgress: 0.0,
      refreshingProgress: 0.0,
      statusMessage: 'Connecting to station...',
    );

    if (bleService.isConnected) {
      await bleService.disconnect();
    }

    bool connectionSuccess = false;
    try {
      connectionSuccess = await bleService.connect(
        device,
        onConnectingProgress: (progress, message) {
          state = state.copyWith(
            stage: SyncStage.connecting,
            connectingProgress: progress,
            statusMessage: message,
          );
        },
        onPairingProgress: (progress, message) {
          state = state.copyWith(
            stage: SyncStage.pairing,
            pairingProgress: progress,
            statusMessage: message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Connection failed',
        errorMessage: e.toString(),
      );
      return false;
    }

    if (!connectionSuccess) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Handshake verification failed.',
        errorMessage: 'Check credentials or distance.',
      );
      return false;
    }

    state = SyncProgressState(
      stage: SyncStage.refreshing,
      connectingProgress: 1.0,
      pairingProgress: 1.0,
      refreshingProgress: 0.0,
      statusMessage: 'Starting data synchronization...',
    );

    try {
      // 1. Refresh local weather state (downloads weather to DB if permitted)
      await _ref
          .read(weatherServiceProvider)
          .refreshWeather(
            onProgress: (progress, message) {
              state = state.copyWith(
                stage: SyncStage.refreshing,
                refreshingProgress:
                    progress * 0.4, // map 0.0-0.4 to weather phase
                statusMessage: message,
              );
            },
          );

      // 2. Extract updated hourly list
      final weatherState = _ref.read(weatherProvider);
      final hourly = weatherState.hourlyForecast;

      // 3. Run BLE operational sequence
      final db = _ref.read(dbProvider);
      final appSettings = db.getAppSettings();
      await _runBleSyncSequence(db, appSettings, bleService, hourly);
    } catch (e) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Data sync failed',
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }

    state = state.copyWith(
      stage: SyncStage.completed,
      refreshingProgress: 1.0,
      statusMessage: 'Successfully connected and updated!',
    );

    await Future.delayed(const Duration(seconds: 2));
    reset();
    return true;
  }

  Future<bool> startRefreshOnly() async {
    final bleService = _ref.read(bleServiceProvider);
    final db = _ref.read(dbProvider);
    final appSettings = db.getAppSettings();

    if (!bleService.isConnected) {
      try {
        await _ref.read(weatherServiceProvider).refreshWeather();
        return true;
      } catch (e) {
        return false;
      }
    }

    state = SyncProgressState(
      stage: SyncStage.refreshing,
      connectingProgress: 1.0,
      pairingProgress: 1.0,
      refreshingProgress: 0.0,
      statusMessage: 'Starting data refresh...',
    );

    try {
      // 1. Refresh weather state
      await _ref
          .read(weatherServiceProvider)
          .refreshWeather(
            onProgress: (progress, message) {
              state = state.copyWith(
                stage: SyncStage.refreshing,
                refreshingProgress: progress * 0.4,
                statusMessage: message,
              );
            },
          );

      // 2. Run BLE operational sync
      final hourly = _ref.read(weatherProvider).hourlyForecast;
      await _runBleSyncSequence(db, appSettings, bleService, hourly);
    } catch (e) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Refresh sequence failed',
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }

    state = state.copyWith(
      stage: SyncStage.completed,
      refreshingProgress: 1.0,
      statusMessage: 'Telemetry updated successfully!',
    );

    await Future.delayed(const Duration(seconds: 2));
    reset();
    return true;
  }

  Future<void> _runBleSyncSequence(
    DatabaseService db,
    AppSettings appSettings,
    BleService ble,
    List<double> hourly,
  ) async {
    print('SyncOrchestrator: Starting BLE refresh sequence...');

    state = state.copyWith(
      refreshingProgress: 0.1,
      statusMessage: 'Synchronizing time...',
    );
    final timeOffset = _ref.read(timeOffsetProvider);
    await ble.syncTime(timeOffset);
    await Future.delayed(const Duration(milliseconds: 100));

    // Request raw history telemetry first to see if station has memory
    state = state.copyWith(
      refreshingProgress: 0.2,
      statusMessage: 'Requesting raw history telemetry...',
    );
    final rawCompleter1 = Completer<void>();
    final rawSub1 = ble.dataStream.listen((data) {
      if (data is List && data.any((item) => item is Map && item['kind'] == 'soil_moisture')) {
        rawCompleter1.complete();
      }
    });
    await ble.requestData('raw');
    await rawCompleter1.future.timeout(const Duration(seconds: 3)).catchError((_) {});
    await rawSub1.cancel();
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if we got any data. If not, station has no registry, so inject mock data.
    final sinceMs = DateTime.now().add(Duration(hours: timeOffset)).subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
    final initialCount = db.getSoilHumidityCount(sinceMs);
    if (initialCount == 0) {
      state = state.copyWith(
        refreshingProgress: 0.4,
        statusMessage: 'Station has no registry. Injecting automatic mock data...',
      );
      await ble.forceMock72Hours();
      await Future.delayed(const Duration(milliseconds: 500));

      // Request raw data again after mocking
      state = state.copyWith(
        refreshingProgress: 0.6,
        statusMessage: 'Requesting mocked raw history telemetry...',
      );
      final rawCompleter2 = Completer<void>();
      final rawSub2 = ble.dataStream.listen((data) {
        if (data is List && data.any((item) => item is Map && item['kind'] == 'soil_moisture')) {
          rawCompleter2.complete();
        }
      });
      await ble.requestData('raw');
      await rawCompleter2.future.timeout(const Duration(seconds: 5)).catchError((_) {});
      await rawSub2.cancel();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    state = state.copyWith(
      refreshingProgress: 0.7,
      statusMessage: 'Sending weather forecast to station...',
    );
    if (appSettings.permitOpenMeteoFill && hourly.isNotEmpty) {
      await ble.sendHourlyForecast(hourly);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Data is already requested, we don't need to do it again here.

    state = state.copyWith(
      refreshingProgress: 0.9,
      statusMessage: 'Checking data completeness...',
    );
    final debugTime = DateTime.now().add(Duration(hours: timeOffset));
    final sinceMsForCheck = debugTime
        .subtract(const Duration(hours: 48))
        .millisecondsSinceEpoch;
    final count = db.getSoilHumidityCount(sinceMsForCheck);
    final allHistory = db.getSoilHumidityHistory();
    print('SyncOrchestrator: sinceMs = $sinceMs (${DateTime.fromMillisecondsSinceEpoch(sinceMs)})');
    print('SyncOrchestrator: Total SoilHumidityRecord count in DB = ${allHistory.length}');
    if (allHistory.isNotEmpty) {
      print('SyncOrchestrator: First record timestamp = ${allHistory.first.timestamp} (${DateTime.fromMillisecondsSinceEpoch(allHistory.first.timestamp)})');
      print('SyncOrchestrator: Last record timestamp = ${allHistory.last.timestamp} (${DateTime.fromMillisecondsSinceEpoch(allHistory.last.timestamp)})');
    }
    print(
      'SyncOrchestrator: Local SoilHumidityRecord count in last 48h = $count',
    );

    if (count < 48 && !appSettings.alwaysForceInference) {
      final hoursToWait = 48 - count;
      final proceed = await requestBypass(
        hoursToWait,
        ble.connectedDevice!.remoteId.toString(),
      );
      if (!proceed) {
        throw Exception(
          'Sync cancelled: Insufficient telemetry data ($hoursToWait hours missing).',
        );
      }
    }

    if (count < 48 && !appSettings.permitOpenMeteoFill) {
      state = state.copyWith(
        refreshingProgress: 0.9,
        statusMessage: 'Sending fill average instruction...',
      );
      await ble.sendFillAverageInstruction();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    state = state.copyWith(
      refreshingProgress: 0.95,
      statusMessage: 'Requesting prediction telemetry...',
    );
    // Condition for inference: hour >= 19 or hour < 10 of debug time
    final debugTimeForInfer = DateTime.now().add(Duration(hours: timeOffset));
    final hour = debugTimeForInfer.hour;
    final isWithinInferenceWindow = hour >= 19 || hour < 10;
    
    if (isWithinInferenceWindow) {
      state = state.copyWith(
        refreshingProgress: 0.9,
        statusMessage: 'Triggering station machine learning inference...',
      );
      await ble.triggerInference();
      // Wait briefly for inference to finish on the IoT station (takes ~270ms on Pico 2 W)
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      print('SyncOrchestrator: Skipping ML inference trigger outside 19:00-10:00 window (current debug hour: $hour)');
    }

    // Fetch the new predictions
    final predCompleter = Completer<void>();
    final predSub = ble.dataStream.listen((data) {
      if (data is List && data.any((item) => item is Map && item['kind'] == 'hs30_forecast')) {
        predCompleter.complete();
      }
    });
    await ble.requestData('pred');
    await predCompleter.future.timeout(const Duration(seconds: 5)).catchError((_) {});
    await predSub.cancel();
    await Future.delayed(const Duration(milliseconds: 100));
    
    state = state.copyWith(
      refreshingProgress: 1.0,
      statusMessage: 'Synchronized.',
    );
  }
}

final connectionSyncProgressProvider =
    StateNotifierProvider<ConnectionSyncProgressNotifier, SyncProgressState>((
      ref,
    ) {
      return ConnectionSyncProgressNotifier(ref);
    });

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(WeatherState());

  void updateState(WeatherState newState) {
    if (mounted) {
      state = newState;
    }
  }
}

class WeatherService {
  final OpenMeteoClient _client;
  final Ref _ref;

  WeatherService(this._client, this._ref);

  Future<void> refreshWeather({
    void Function(double progress, String message)? onProgress,
  }) async {
    final db = _ref.read(dbProvider);
    final settings = db.getAppSettings();

    _ref
        .read(weatherProvider.notifier)
        .updateState(WeatherState(isLoading: true, errorMessage: null));

    try {
      WeatherData? apiData;
      if (settings.permitOpenMeteoFill) {
        onProgress?.call(0.1, 'Fetching weather forecast...');
        apiData = await _client.fetchForecast();

        onProgress?.call(0.3, 'Saving weather to local database...');
        // Save all hourly weather records to database
        for (int i = 0; i < apiData.time.length; i++) {
          db.saveWeather(
            apiData.time[i].millisecondsSinceEpoch,
            apiData.temperature2m[i],
            apiData.relativeHumidity2m[i],
            apiData.shortwaveRadiation[i],
            apiData.precipitation[i],
          );
        }
        
        _ref.read(databaseTriggerProvider.notifier).state++;
      } else {
        print('WeatherService: OpenMeteo filling is disabled by settings.');
        _saveFallbackWeather(db);
      }

      // Process hourly forecasts for recommendation scaling
      final forecastData = _getHourlyForecast(db, apiData);
      final hourly = forecastData['hourly'] ?? [];
      final hourlyRad = forecastData['hourlyRad'] ?? [];

      // Process daily weather statistics (for charts and summary UI)
      final List<ProcessedWeatherDay> apiProcessed = apiData != null
          ? WeatherProcessor.process(apiData)
          : const [];
      final todayWeather = _buildTodayWeather(db, apiProcessed);

      // Update WeatherState
      _ref
          .read(weatherProvider.notifier)
          .updateState(
            WeatherState(
              daily: todayWeather,
              hourlyForecast: hourly,
              hourlyRadiationForecast: hourlyRad,
              isLoading: false,
            ),
          );

      // If BLE is not connected, run fallback local inference
      final ble = _ref.read(bleServiceProvider);
      if (!ble.isConnected) {
        await runFallbackLocalInference();
      }
    } catch (e) {
      print('Weather fetch error: $e');
      _saveFallbackWeather(db);
      _ref
          .read(weatherProvider.notifier)
          .updateState(
            WeatherState(
              isLoading: false,
              errorMessage: e.toString().replaceFirst('Exception: ', ''),
            ),
          );
      rethrow;
    }
  }

  // ponytail: Fallback generator to ensure local database weather records are always in valid range
  void _saveFallbackWeather(DatabaseService db) {
    final now = DateTime.now();
    for (int i = -48; i <= 24; i++) {
      final ts = now.add(Duration(hours: i)).millisecondsSinceEpoch;
      final hour = now.add(Duration(hours: i)).hour;
      final temp = 18.0 + (i.abs() % 6) * 1.2;
      final hum = 50.0 + (i.abs() % 4) * 5.0;
      final rad = (hour >= 8 && hour <= 20)
          ? (12 - (hour - 14).abs()) * 70.0
          : 0.0;
      db.saveWeather(ts, temp, hum, rad, 0.0);
    }
    _ref.read(databaseTriggerProvider.notifier).state++;
  }

  Map<String, List<double>> _getHourlyForecast(
    DatabaseService db,
    WeatherData? apiData,
  ) {
    final now = DateTime.now();
    final List<double> hourly = [];
    final List<double> hourlyRad = [];

    if (apiData != null) {
      for (int i = 0; i < apiData.time.length; i++) {
        if (apiData.time[i].isAfter(now) ||
            apiData.time[i].isAtSameMomentAs(now)) {
          hourly.add(apiData.temperature2m[i]);
          hourlyRad.add(apiData.shortwaveRadiation[i]);
          if (hourly.length == 24) break;
        }
      }
    } else {
      // Fallback: Populate from local database weather history
      final localWeather = db.getWeatherHistory();
      localWeather.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final nowMs = now.millisecondsSinceEpoch;
      for (final record in localWeather) {
        if (record.timestamp >= nowMs) {
          hourly.add(record.temperature);
          hourlyRad.add(record.radiation);
          if (hourly.length == 24) break;
        }
      }
    }

    return {'hourly': hourly, 'hourlyRad': hourlyRad};
  }

  ProcessedWeatherDay? _buildTodayWeather(
    DatabaseService db,
    List<ProcessedWeatherDay> apiProcessed,
  ) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    if (apiProcessed.isNotEmpty) {
      return apiProcessed.firstWhere(
        (day) => DateTime(
          day.date.year,
          day.date.month,
          day.date.day,
        ).isAtSameMomentAs(todayDate),
        orElse: () => apiProcessed.first,
      );
    }

    // Recreate ProcessedWeatherDay from localWeather database for today
    final localWeather = db.getWeatherHistory();
    final todayMsStart = todayDate.millisecondsSinceEpoch;
    final todayMsEnd = todayDate
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;
    final todayRecords = localWeather
        .where((r) => r.timestamp >= todayMsStart && r.timestamp < todayMsEnd)
        .toList();

    if (todayRecords.isNotEmpty) {
      final temps = todayRecords.map((r) => r.temperature).toList();
      final hums = todayRecords.map((r) => r.humidity).toList();
      final rads = todayRecords.map((r) => r.radiation).toList();
      final precs = todayRecords.map((r) => r.precipitation).toList();

      DailyStats calcStats(List<double> values, {bool isSum = false}) {
        if (values.isEmpty) {
          return DailyStats(
            min: 0.0,
            max: 0.0,
            mean: 0.0,
            stdDev: 0.0,
            sum: 0.0,
          );
        }
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final sum = values.reduce((a, b) => a + b);
        final mean = sum / values.length;
        return DailyStats(
          min: min,
          max: max,
          mean: mean,
          stdDev: 0.0,
          sum: isSum ? sum : 0.0,
        );
      }

      return ProcessedWeatherDay(
        date: todayDate,
        temperature: calcStats(temps),
        humidity: calcStats(hums),
        radiation: calcStats(rads, isSum: true),
        precipitation: calcStats(precs, isSum: true),
      );
    }
    return null;
  }

  Future<void> runFallbackLocalInference() async {
    print('WeatherService: Not paired. Running local RF inference fallback...');
    final bridge = _ref.read(bridgeProvider);
    await bridge.runIrrigationRecommendation();
  }
}

final bridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(
    ref.watch(dbProvider),
    onDbUpdated: () {
      ref.read(databaseTriggerProvider.notifier).state++;
    },
  );
});

final predictionProvider = StateNotifierProvider<PredictionNotifier, double>((
  ref,
) {
  return PredictionNotifier(ref.watch(bridgeProvider), ref);
});

class PredictionNotifier extends StateNotifier<double> {
  final InferenceBridge _bridge;
  final Ref _ref;
  StreamSubscription? _dataSub;

  PredictionNotifier(this._bridge, this._ref) : super(-1.0) {
    // Phase 7: Isolate RF trigger to run only on 0x12 predicted humidity event
    _dataSub = _ref
        .read(bleProcessorProvider)
        .onPredictedHumidityProcessed
        .listen((_) {
          runRealInference();
        });
  }

  Future<void> init() async {
    // No initialization needed for static dart models
  }

  Future<void> runRealInference() async {
    await _bridge.runIrrigationRecommendation();
    if (!mounted) return;
    state = 1.0;
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }
}

/// ################### Providers ###################

/// ################### Main ###################
void main() {
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      BleService.instance?.disconnect();
    } catch (_) {}
    return false;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TFM PoC Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

/// ################### Main ###################

/// ################### Navigation Views ###################
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
    bool _showSettings = false;
    late final AppLifecycleListener _lifecycleListener;

    @override
    void initState() {
          super.initState();
          ref.read(bleProcessorProvider);

          Future.microtask(() {
            ref.read(predictionProvider.notifier).init();
          });
          ref.listenManual(locationProvider, (previous, next) {
            ref.read(weatherServiceProvider).refreshWeather();
          });

          _lifecycleListener = AppLifecycleListener(
                
                onDetach: () {
                  unawaited(ref.read(bleServiceProvider).disconnect());
                },


                

                onResume: () async {
                  final pos = await ref
                      .read(locationServiceProvider)
                      .getCurrentPosition();
                  if (pos != null && mounted) {
                    await ref.read(locationProvider.notifier).updateFromGps();
                  }

                  final ble = ref.read(bleServiceProvider);
                  if (!ble.isConnected) {
                    unawaited(ble.startScan());
                  }
            },
      );

      unawaited(ref.read(bleServiceProvider).startScan());
    }

    @override
    void dispose() {
      _lifecycleListener.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      ref.watch(databaseTriggerProvider);
      final syncState = ref.watch(connectionSyncProgressProvider);

      ref.listen<bool>(bleConnectedProvider, (previous, next) {
        if (!next && _showSettings) {
          setState(() {
            _showSettings = false;
          });
        }
      });

      final db = ref.watch(dbProvider);
      final hasDevice = ref.watch(bleConnectedProvider);
      final showSettings = _showSettings && hasDevice;

      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          appBar: AppBar(
            title: Builder(
              builder: (context) {
                if (showSettings) {
                  return Text('Settings', style: AppStyles.appBarTitleStyle(context));
                }

                final predictions = db.getPredictionHistory();
                final isSyncing = syncState.stage != SyncStage.idle &&
                    syncState.stage != SyncStage.failed;
                
                final isInferring = predictions.isNotEmpty &&
                    predictions.last.recommendation == "Calculating recommendation...";

                if (isSyncing || isInferring) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Syncing & Analysing ', style: AppStyles.appBarTitleStyle(context)),
                      LoadingDots(color: AppStyles.primaryTeal(context)),
                    ],
                  );
                }

                final hasFinishedInference = predictions.isNotEmpty &&
                    predictions.last.recommendation != "Calculating recommendation..." &&
                    predictions.last.recommendation.isNotEmpty;

                if (hasFinishedInference && ref.read(bleServiceProvider).isConnected) {
                  final isSaturation = predictions.last.recommendation.contains('SATURATION');
                  final recText = isSaturation ? 'Do not Irrigate' : 'Irrigate';
                  final badgeColor = isSaturation
                      ? AppStyles.dangerRed(context)
                      : AppStyles.primaryTeal(context);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Irrigation: ', style: AppStyles.appBarTitleStyle(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: badgeColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        ),
                        child: Text(
                          recText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Text('', style: AppStyles.appBarTitleStyle(context));
              },
            ),
            actions: [
              if (hasDevice && !showSettings)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    if (ref.read(bleServiceProvider).isConnected) {
                      SyncProgressDialog.show(context);
                      await ref
                          .read(connectionSyncProgressProvider.notifier)
                          .startRefreshOnly();
                    } else {
                      unawaited(
                        ref.read(weatherServiceProvider).refreshWeather(),
                      );
                    }
                  },
                ),
              if (hasDevice)
                IconButton(
                  icon: Icon(showSettings ? Icons.close : Icons.settings),
                  onPressed: () {
                    setState(() {
                      _showSettings = !_showSettings;
                    });
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: showSettings ? ConfigView(db: db) : const TelemetryView(),
          ),
        ),
      );
    }
}

class DisplayDevice {
  final String id;
  final String name;
  final bool isSaved;
  final ScanResult? scanResult;
  final int rssi;

  DisplayDevice({
    required this.id,
    required this.name,
    required this.isSaved,
    this.scanResult,
    this.rssi = -100,
  });
}

class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingDots({
    super.key,
    required this.color,
    this.size = 6.0,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    unawaited(_startAnimations());
  }

  Future<void> _startAnimations() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      unawaited(_controllers[i].repeat(reverse: true));
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: _animations[index],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
