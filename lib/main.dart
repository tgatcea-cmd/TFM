import "dart:async";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';
import 'logic/ble_data_processor.dart';
import 'core/api/open_meteo_client.dart';
import 'logic/weather_processor.dart';
import 'data/models/processed/daily_weather.dart';
import 'logic/inference/tflite_service.dart';
import 'logic/inference/rf_service.dart';
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
  return BleService(handshakeModule: PicoHandshakeModule());
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
  WeatherState({this.daily, this.hourlyForecast = const []});
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
    state = WeatherState(); // Phase 2: Show loading indicator
    try {
      final data = await _client.fetchForecast();
      final processed = WeatherProcessor.process(data);
      
      // Extract next 24h of temperature forecast
      final now = DateTime.now();
      final List<double> hourly = [];
      for (int i = 0; i < data.time.length; i++) {
        if (data.time[i].isAfter(now) || data.time[i].isAtSameMomentAs(now)) {
          hourly.add(data.temperature2m[i]);
          if (hourly.length == 24) break;
        }
      }

      if (processed.isNotEmpty) {
        state = WeatherState(daily: processed.first, hourlyForecast: hourly);
      }
    } catch (e) {
      print('Weather fetch error: $e');
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

final rfServiceProvider = Provider<RfService>((ref) {
  return RfService();
});

final bridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(
    ref.watch(dbProvider),
    ref.watch(tfliteServiceProvider),
    ref.watch(rfServiceProvider),
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
    // Phase 4: Auto-inference on new data
    _dataSub = _ref.read(bleProcessorProvider).onDataProcessed.listen((_) {
      runRealInference();
    });
  }

  Future<void> init() async {
    // Phase 4: Load both models
    // Note: GRU TFLite still used for local trend prediction if needed, 
    // but the main PoC verdict now comes from CESAR (FPGA) + App RF.
    await _ref.read(rfServiceProvider).loadModel('assets/models/irrigation_rf.json');
  }

  Future<void> runRealInference() async {
    await _bridge.runIrrigationRecommendation();
    state = 1.0; // Trigger refresh
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }
}

void main() {
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
  }

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final db = ref.watch(dbProvider);
    final weather = ref.watch(weatherProvider);
    final prediction = ref.watch(predictionProvider);
    final rf = ref.watch(rfServiceProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TFM PoC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(weatherProvider.notifier).refresh();
              setState(() {});
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
              _buildBleCard(bleService, weather),
              const SizedBox(height: 16),
              _buildLocationCard(location),
              const SizedBox(height: 16),
              _buildWeatherCard(bleService, db, weather),
              const SizedBox(height: 16),
              _buildPredictionCard(rf, prediction, db),
              const SizedBox(height: 16),
              _buildDataCard(db),
            ],
          ),
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
    DatabaseService db,
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
            if (weather.daily == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('Date: ${weather.daily!.date.toString().split(' ')[0]}'),
              Text(
                'Avg Temp: ${weather.daily!.temperature.mean.toStringAsFixed(1)}°C',
              ),
              Text('Avg Hum: ${weather.daily!.humidity.mean.toStringAsFixed(1)}%'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: bleService.isConnected && weather.hourlyForecast.isNotEmpty
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
    RfService rf,
    double prediction,
    DatabaseService db,
  ) {
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
            const Text(
              'Inference Layer (Phase 4)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text('RF Model Loaded: ${rf.isLoaded ? 'YES' : 'NO'}'),
            if (prediction != -1.0)
              const Text('Inference Status: Active'),
            Text('Recommendation: $lastRec'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: rf.isLoaded
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

  Widget _buildBleCard(BleService bleService, WeatherState weather) {
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
            if (!bleService.isConnected) ...[
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
              const Text(
                'Status: Connected to Pico',
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await bleService.requestSync();
                      // Phase 3: Auto-send 0x02 after Sync
                      if (weather.hourlyForecast.isNotEmpty) {
                        await bleService.sendHourlyForecast(weather.hourlyForecast);
                      }
                    },
                    child: const Text('Sync Data'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => bleService.disconnect(),
                    child: const Text('Disconnect'),
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
                      unawaited(bleService.stopScan());
                      final bool success = await bleService.connect(r.device);
                      if (success) {
                        // Phase 2: Refresh weather on connection
                        unawaited(ref.read(weatherProvider.notifier).refresh());
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Connection failed')),
                        );
                      }
                      setState(() {});
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
              unawaited(bleService.stopScan());
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
