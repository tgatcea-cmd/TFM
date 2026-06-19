import "dart:async";
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/processed/daily_weather.dart';
import 'data/models/models.dart';

import 'core/api/open_meteo_client.dart';
import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';

import 'logic/inference/inference_bridge.dart';
import 'logic/inference/tflite_service.dart';
import 'logic/ble_data_processor.dart';
import 'logic/location_service.dart';
import 'logic/weather_processor.dart';

import 'ui/views/config_view.dart';
import 'ui/views/sync_progress_dialog.dart';
import 'ui/views/telemetry_view.dart';







/// ################### Providers ###################
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
  final processor = BleDataProcessor(ble, db);
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
  return WeatherNotifier(ref.watch(weatherClientProvider), ref);
});

enum SyncStage {
  idle,
  connecting,
  pairing,
  refreshing,
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

  SyncProgressState({
    required this.stage,
    required this.connectingProgress,
    required this.pairingProgress,
    required this.refreshingProgress,
    required this.statusMessage,
    this.errorMessage,
  });

  SyncProgressState copyWith({
    SyncStage? stage,
    double? connectingProgress,
    double? pairingProgress,
    double? refreshingProgress,
    String? statusMessage,
    String? errorMessage,
  }) {
    return SyncProgressState(
      stage: stage ?? this.stage,
      connectingProgress: connectingProgress ?? this.connectingProgress,
      pairingProgress: pairingProgress ?? this.pairingProgress,
      refreshingProgress: refreshingProgress ?? this.refreshingProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectionSyncProgressNotifier extends StateNotifier<SyncProgressState> {
  final Ref _ref;

  ConnectionSyncProgressNotifier(this._ref)
      : super(SyncProgressState(
          stage: SyncStage.idle,
          connectingProgress: 0.0,
          pairingProgress: 0.0,
          refreshingProgress: 0.0,
          statusMessage: '',
        ));

  void reset() {
    state = SyncProgressState(
      stage: SyncStage.idle,
      connectingProgress: 0.0,
      pairingProgress: 0.0,
      refreshingProgress: 0.0,
      statusMessage: '',
    );
  }

  Future<bool> startSequence(BluetoothDevice device) async {
    final bleService = _ref.read(bleServiceProvider);
    
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

    state = state.copyWith(
      stage: SyncStage.refreshing,
      connectingProgress: 1.0,
      pairingProgress: 1.0,
      refreshingProgress: 0.0,
      statusMessage: 'Starting data synchronization...',
    );

    try {
      await _ref.read(weatherProvider.notifier).refresh(
        onProgress: (progress, message) {
          state = state.copyWith(
            stage: SyncStage.refreshing,
            refreshingProgress: progress,
            statusMessage: message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Data sync failed',
        errorMessage: e.toString(),
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
    if (!bleService.isConnected) {
      try {
        await _ref.read(weatherProvider.notifier).refresh();
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
      await _ref.read(weatherProvider.notifier).refresh(
        onProgress: (progress, message) {
          state = state.copyWith(
            stage: SyncStage.refreshing,
            refreshingProgress: progress,
            statusMessage: message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        stage: SyncStage.failed,
        statusMessage: 'Refresh sequence failed',
        errorMessage: e.toString(),
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
}

final connectionSyncProgressProvider =
    StateNotifierProvider<ConnectionSyncProgressNotifier, SyncProgressState>((ref) {
  return ConnectionSyncProgressNotifier(ref);
});

class WeatherNotifier extends StateNotifier<WeatherState> {
  final OpenMeteoClient _client;
  final Ref _ref;

  WeatherNotifier(this._client, this._ref) : super(WeatherState());

  Future<void> refresh({void Function(double progress, String message)? onProgress}) async {
    state = WeatherState(isLoading: true); // Show loading indicator
    try {
      onProgress?.call(0.1, 'Fetching weather forecast...');
      final data = await _client.fetchForecast();
      if (!mounted) return;
      
      onProgress?.call(0.3, 'Saving weather to local database...');
      final processed = WeatherProcessor.process(data);

      // Save all hourly weather records to database
      final db = _ref.read(dbProvider);
      for (int i = 0; i < data.time.length; i++) {
        db.saveWeather(
          data.time[i].millisecondsSinceEpoch,
          data.temperature2m[i],
          data.relativeHumidity2m[i],
          data.shortwaveRadiation[i],
          data.precipitation[i],
        );
      }

      // Extract next 24h of temperature and radiation forecast
      final now = DateTime.now();
      final List<double> hourly = [];
      final List<double> hourlyRad = [];
      for (int i = 0; i < data.time.length; i++) {
        if (data.time[i].isAfter(now) || data.time[i].isAtSameMomentAs(now)) {
          hourly.add(data.temperature2m[i]);
          hourlyRad.add(data.shortwaveRadiation[i]);
          if (hourly.length == 24) break;
        }
      }

      final todayDate = DateTime(now.year, now.month, now.day);
      final todayWeather = processed.firstWhere(
        (day) => DateTime(
          day.date.year,
          day.date.month,
          day.date.day,
        ).isAtSameMomentAs(todayDate),
        orElse: () => processed.first,
      );

      if (processed.isNotEmpty) {
        state = WeatherState(
          daily: todayWeather,
          hourlyForecast: hourly,
          hourlyRadiationForecast: hourlyRad,
          isLoading: false,
        );
      } else {
        state = WeatherState(
          isLoading: false,
          errorMessage: 'No forecast data available from API',
        );
      }

      // --- FULL REFRESH SEQUENCE ---
      final ble = _ref.read(bleServiceProvider);
      if (ble.isConnected) {
        print('WeatherNotifier: Starting BLE refresh sequence...');

        onProgress?.call(0.5, 'Synchronizing clock with station...');
        // 1. Sync time
        await ble.syncTime();
        await Future.delayed(const Duration(milliseconds: 300));

        onProgress?.call(0.7, 'Sending weather forecast to station...');
        // 2. Send weather
        if (hourly.isNotEmpty) {
          await ble.sendHourlyForecast(hourly);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        onProgress?.call(0.8, 'Requesting raw history telemetry...');
        // 3. Get previous 48 hours raw data
        await ble.requestData('raw');
        await Future.delayed(const Duration(milliseconds: 400));

        onProgress?.call(0.9, 'Requesting prediction telemetry...');
        // 4. Get previous prediction data
        await ble.requestData('pred');
        await Future.delayed(const Duration(milliseconds: 400));

        onProgress?.call(1.0, 'Triggering station machine learning inference...');
        // 5. Trigger LSTM inference on station
        await ble.triggerInference();

        // Note: Running RF is handled reactively by PredictionNotifier
        // when the LSTM result is returned via onPredictedHumidityProcessed!
      } else {
        print(
          'WeatherNotifier: Not paired. Running local RF inference fallback...',
        );
        // Not paired: run RF inference locally using latest cached prediction
        final bridge = _ref.read(bridgeProvider);
        if (_ref.read(tfliteServiceProvider).isRfLoaded) {
          await bridge.runIrrigationRecommendation();
        }
      }
    } catch (e) {
      print('Weather fetch error: $e');
      if (!mounted) return;
      state = WeatherState(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final tfliteServiceProvider = Provider<TfliteService>((ref) {
  final service = TfliteService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(
    ref.watch(dbProvider),
    ref.watch(tfliteServiceProvider),
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
    final tflite = _ref.read(tfliteServiceProvider);
    // await tflite.loadLstmModel('assets/models/irrigation_gru.tflite');
    await tflite.loadRfModel('assets/models/rf_irrigation.tflite');
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
  final double _fontScale = 1.0;

  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    ref.read(bleProcessorProvider);

    Future.microtask(() {
      ref.read(predictionProvider.notifier).init();
    });

    ref.listenManual(locationProvider, (previous, next) {
      ref.read(weatherProvider.notifier).refresh();
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
      ).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(showSettings ? 'Settings' : ''),
          actions: [
            if (hasDevice && !showSettings)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  if (ref.read(bleServiceProvider).isConnected) {
                    SyncProgressDialog.show(context);
                    await ref.read(connectionSyncProgressProvider.notifier).startRefreshOnly();
                  } else {
                    unawaited(ref.read(weatherProvider.notifier).refresh());
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
