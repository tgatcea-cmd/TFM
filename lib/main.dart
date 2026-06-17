import "dart:async";
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tfm_app/ui/unified_chart.dart';
import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';
import 'logic/ble_data_processor.dart';
import 'core/api/open_meteo_client.dart';
import 'logic/weather_processor.dart';
import 'data/models/processed/daily_weather.dart';
import 'logic/inference/tflite_service.dart';
import 'logic/inference/inference_bridge.dart';

// ... (other imports)
import 'logic/location_service.dart';
import 'data/schemas/location_schema.dart';
import 'ui/location_picker_map.dart';
import 'package:latlong2/latlong.dart' as ll;

// Providers
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
  // ponytail: disconnect BLE when provider is disposed
  ref.onDispose(() => service.disconnect());
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

final bleProcessorProvider = Provider<BleDataProcessor>((ref) {
  final ble = ref.watch(bleServiceProvider);
  final db = ref.watch(dbProvider);
  final processor = BleDataProcessor(ble, db);
  processor.startListening();
  return processor;
});

final weatherClientProvider = Provider<OpenMeteoClient>((ref) {
  final loc = ref.watch(locationProvider);
  return OpenMeteoClient(latitude: loc.latitude, longitude: loc.longitude);
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

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
      return WeatherNotifier(ref.watch(weatherClientProvider));
    });

class WeatherNotifier extends StateNotifier<WeatherState> {
  final OpenMeteoClient _client;
  Timer? _refreshTimer;

  WeatherNotifier(this._client) : super(WeatherState()) {
    // Phase 2: Periodic background refresh (every 6 hours)
    _refreshTimer = Timer.periodic(const Duration(hours: 6), (_) => refresh());
  }

  Future<void> refresh() async {
    state = WeatherState(isLoading: true); // Show loading indicator
    try {
      final data = await _client.fetchForecast();
      if (!mounted) return;
      final processed = WeatherProcessor.process(data);
      
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

      if (processed.isNotEmpty) {
        state = WeatherState(
          daily: processed.first,
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
    } catch (e) {
      print('Weather fetch error: $e');
      if (!mounted) return;
      state = WeatherState(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
    _dataSub = _ref.read(bleProcessorProvider).onPredictedHumidityProcessed.listen((_) {
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

void main() {
  // ponytail: disconnect BLE on sudden uncaught crashes
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

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    ref.read(bleProcessorProvider);
    Future.microtask(() {
      ref.read(weatherProvider.notifier).refresh();
      ref.read(predictionProvider.notifier).init();
    });

    // Refresh weather when location changes
    ref.listenManual(locationProvider, (previous, next) {
      ref.read(weatherProvider.notifier).refresh();
    });

    // ponytail: disconnect BLE when the app is detached (terminated)
    _lifecycleListener = AppLifecycleListener(
      onDetach: () {
        ref.read(bleServiceProvider).disconnect();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final isConnected = ref.watch(bleConnectedProvider);
    final db = ref.watch(dbProvider);
    final weather = ref.watch(weatherProvider);
    final prediction = ref.watch(predictionProvider);
    final tflite = ref.watch(tfliteServiceProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TFM PoC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(weatherProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBleCard(bleService, isConnected, weather),
              const SizedBox(height: 16),
              _buildLocationCard(location),
              const SizedBox(height: 16),
              _buildUnifiedChart(db, weather),
              const SizedBox(height: 16),
              _buildWeatherCard(bleService, isConnected, weather),
              const SizedBox(height: 16),
              _buildPredictionCard(tflite, prediction, db),
              const SizedBox(height: 16),
              _buildDataCard(db),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedChart(
    DatabaseService db,
    WeatherState weather,
  ) {
    final history = db.getSoilHumidityHistory();
    final predictions = db.getPredictionHistory();
    final radiationForecast = weather.hourlyRadiationForecast;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unified Data Chart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            UnifiedChart(
              history: history,
              predictions: predictions,
              radiationForecast: radiationForecast,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(LocationSettings location) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              'Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            ),
            Text(
              'Mode: ${location.isGpsBased ? 'GPS (Auto)' : 'Manual (Map)'}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(locationProvider.notifier).updateFromGps(),
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Use GPS'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ll.LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerMap(
                          initialLat: location.latitude,
                          initialLon: location.longitude,
                        ),
                      ),
                    );
                    if (result != null) {
                      ref
                          .read(locationProvider.notifier)
                          .updateManual(result.latitude, result.longitude);
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Pick on Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(
    BleService bleService,
    bool isConnected,
    WeatherState weather,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Data Bridge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (weather.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (weather.hasError) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.errorMessage ?? 'Error loading weather data',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => ref.read(weatherProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Fetch'),
              ),
            ] else if (weather.daily == null)
              const Center(child: Text('No weather data available'))
            else ...[
              Text('Date: ${weather.daily!.date.toString().split(' ')[0]}'),
              Text(
                'Avg Temp: ${weather.daily!.temperature.mean.toStringAsFixed(1)}°C',
              ),
              Text('Avg Hum: ${weather.daily!.humidity.mean.toStringAsFixed(1)}%'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: isConnected && weather.hourlyForecast.isNotEmpty
                    ? () => bleService.sendHourlyForecast(weather.hourlyForecast)
                    : null,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Send Env Data (0x02)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(
    TfliteService tflite,
    double prediction,
    DatabaseService db,
  ) {
    final bridge = ref.watch(bridgeProvider);
    final predictions = db.getPredictionHistory();
    final lastRec = predictions.isNotEmpty
        ? predictions.last.recommendation
        : 'None';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inference Layer (Phase 4)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (bridge.isRunning.watch(context))
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Divider(),
            
            // Status & Timing
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Status: ${bridge.status.watch(context)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (bridge.lastInferenceTime.watch(context) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last Run: ${bridge.lastInferenceTime.watch(context)!.toLocal().toString().split('.')[0]}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            if (bridge.isRunning.watch(context) || (bridge.progress.watch(context) > 0 && bridge.progress.watch(context) < 1.0))
              Column(
                children: [
                  LinearProgressIndicator(
                    value: bridge.progress.watch(context),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            Text('RF Model Loaded: ${tflite.isRfLoaded ? 'YES' : 'NO'}'),
            Text('Recommendation: $lastRec', 
              style: TextStyle(
                color: lastRec.contains('SATURATION') ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold
              ),
            ),
            
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: tflite.isRfLoaded && !bridge.isRunning.watch(context)
                  ? () =>
                        ref.read(predictionProvider.notifier).runRealInference()
                  : null,
              icon: const Icon(Icons.analytics),
              label: const Text('Run RF Inference (Fusion)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBleCard(BleService bleService, bool isConnected, WeatherState weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BLE Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (!isConnected) ...[
              const Text(
                'Status: Disconnected',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showScanDialog(bleService),
                icon: const Icon(Icons.search),
                label: const Text('Scan & Connect'),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status: Connected to Pico',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => bleService.disconnect(),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'GATT API Debug Console',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await bleService.syncTime();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Time Sync Command Sent (0x11)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text('Sync Time'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final forecast = weather.hourlyForecast.isNotEmpty
                          ? weather.hourlyForecast
                          : List<double>.generate(24, (i) => 15.0 + i % 5);
                      await bleService.sendHourlyForecast(forecast);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              weather.hourlyForecast.isNotEmpty
                                  ? 'Real Weather Forecast Sent (0x12)'
                                  : 'Mock Weather Forecast Sent (0x12)',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_queue),
                    label: const Text('Send Weather'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await bleService.requestData('raw');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request Raw History Sent (0x20)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Get Raw History'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await bleService.requestData('pred');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request Predictions Sent (0x20)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.online_prediction),
                    label: const Text('Get Pred History'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await bleService.triggerInference();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trigger FPGA LSTM Inference (0x20)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.bolt),
                    label: const Text('Trigger LSTM'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await bleService.toggleDebugMode();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Toggle Station Debug Mode (0x20)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Toggle Station Debug'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(DatabaseService db) {
    final history = db.getSoilHumidityHistory();
    final lastVal = history.isNotEmpty ? history.last : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (lastVal == null)
              const Text('No data received yet.')
            else
              ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: Text(
                  'Soil Humidity: ${lastVal.value.toStringAsFixed(2)}%',
                ),
                subtitle: Text(
                  'Time: ${DateTime.fromMillisecondsSinceEpoch(lastVal.timestamp).toLocal()}',
                ),
              ),
            const SizedBox(height: 10),
            Text('History Count: ${history.length}'),
          ],
        ),
      ),
    );
  }

  void _showScanDialog(BleService bleService) {
    bleService.startScan();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan for Station'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<ScanResult>>(
            stream: bleService.scanResults,
            builder: (context, snapshot) {
              final results = snapshot.data ?? [];
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final r = results[index];
                  final name = r.advertisementData.advName.isNotEmpty
                      ? r.advertisementData.advName
                      : r.device.platformName;
                  return ListTile(
                    title: Text(name.isEmpty ? 'Unknown Device' : name),
                    subtitle: Text(r.device.remoteId.toString()),
                    onTap: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final bool success = await bleService.connect(r.device);
                      if (success) {
                        // Phase 2: Refresh weather on connection
                        unawaited(ref.read(weatherProvider.notifier).refresh());
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Connection failed')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      unawaited(bleService.stopScan());
    });
  }
}
