import "dart:async";
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';
import 'logic/ble_data_processor.dart';
import 'core/api/open_meteo_client.dart';
import 'logic/weather_processor.dart';
import 'data/models/processed/daily_weather.dart';
import 'logic/inference/tflite_service.dart';
import 'logic/inference/inference_bridge.dart';
import 'logic/location_service.dart';
import 'data/models/models.dart';
import 'ui/views/telemetry_view.dart';
import 'ui/views/config_view.dart';





















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

final bleConnectionStreamProvider = StreamProvider<bool>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.connectionStateStream;
});

final bleConnectedProvider = Provider<bool>((ref) {
  final asyncVal = ref.watch(bleConnectionStreamProvider);
  final ble = ref.watch(bleServiceProvider);
  return asyncVal.value ?? ble.isConnected;
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

class WeatherNotifier extends StateNotifier<WeatherState> {
  final OpenMeteoClient _client;
  final Ref _ref;

  WeatherNotifier(this._client, this._ref) : super(WeatherState());

  Future<void> refresh() async {
    state = WeatherState(isLoading: true); // Show loading indicator
    try {
      final data = await _client.fetchForecast();
      if (!mounted) return;
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

        // 1. Sync time
        await ble.syncTime();
        await Future.delayed(const Duration(milliseconds: 300));

        // 2. Send weather
        if (hourly.isNotEmpty) {
          await ble.sendHourlyForecast(hourly);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // 3. Get previous 48 hours raw data
        await ble.requestData('raw');
        await Future.delayed(const Duration(milliseconds: 400));

        // 4. Get previous prediction data
        await ble.requestData('pred');
        await Future.delayed(const Duration(milliseconds: 400));

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
    state = 1.0; // Trigger refresh
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
        final pos = await ref.read(locationServiceProvider).getCurrentPosition();
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
    final db = ref.watch(dbProvider);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showSettings ? 'Settings' : 'TFM PoC Dashboard'),
          actions: [
            IconButton(
              icon: Icon(_showSettings ? Icons.close : Icons.settings),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _showSettings 
              ? ConfigView(db: db)
              : const TelemetryView(),
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
