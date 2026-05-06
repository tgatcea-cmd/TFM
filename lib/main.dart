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
import 'logic/inference/inference_bridge.dart';

// Providers
final dbProvider = Provider<DatabaseService>((ref) {
  final db = DatabaseService();
  ref.onDispose(() => db.close());
  return db;
});

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
  return OpenMeteoClient(latitude: 40.4168, longitude: -3.7038);
});

final weatherProvider = StateNotifierProvider<WeatherNotifier, ProcessedWeatherDay?>((ref) {
  return WeatherNotifier(ref.watch(weatherClientProvider));
});

class WeatherNotifier extends StateNotifier<ProcessedWeatherDay?> {
  final OpenMeteoClient _client;
  WeatherNotifier(this._client) : super(null);

  Future<void> refresh() async {
    try {
      final data = await _client.fetchForecast();
      final processed = WeatherProcessor.process(data);
      if (processed.isNotEmpty) {
        state = processed.first;
      }
    } catch (e) {
      print('Weather fetch error: $e');
    }
  }
}

final tfliteServiceProvider = Provider<TfliteService>((ref) {
  final service = TfliteService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(ref.watch(dbProvider), ref.watch(tfliteServiceProvider));
});

final predictionProvider = StateNotifierProvider<PredictionNotifier, double>((ref) {
  return PredictionNotifier(ref.watch(bridgeProvider), ref);
});

class PredictionNotifier extends StateNotifier<double> {
  final InferenceBridge _bridge;
  final Ref _ref;
  PredictionNotifier(this._bridge, this._ref) : super(-1.0);

  Future<void> init() async {
    await _ref.read(tfliteServiceProvider).loadModel('assets/models/gru_food_inflation.tflite');
  }

  Future<void> runRealInference() async {
    final weather = _ref.read(weatherProvider);
    state = await _bridge.predictNextHumidity(weather);
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
  }

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final db = ref.watch(dbProvider);
    final weather = ref.watch(weatherProvider);
    final prediction = ref.watch(predictionProvider);
    final tflite = ref.watch(tfliteServiceProvider);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBleCard(bleService),
            const SizedBox(height: 16),
            _buildWeatherCard(bleService, db, weather),
            const SizedBox(height: 16),
            _buildPredictionCard(tflite, prediction, db),
            const SizedBox(height: 16),
            _buildDataCard(db),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BleService bleService, DatabaseService db, ProcessedWeatherDay? weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weather Data Bridge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (weather == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('Date: ${weather.date.toString().split(' ')[0]}'),
              Text('Avg Temp: ${weather.temperature.mean.toStringAsFixed(1)}°C'),
              Text('Avg Hum: ${weather.humidity.mean.toStringAsFixed(1)}%'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: bleService.isConnected 
                  ? () => bleService.sendProcessedWeatherData(weather) 
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

  Widget _buildPredictionCard(TfliteService tflite, double prediction, DatabaseService db) {
    final predictions = db.getPredictionHistory();
    final lastRec = predictions.isNotEmpty ? predictions.last.recommendation : 'None';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inference Layer (Phase 4)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Model Loaded: ${tflite.isLoaded ? 'YES' : 'NO'}'),
            if (prediction != -1.0)
              Text('Last Prediction: ${prediction.toStringAsFixed(4)}'),
            Text('Recommendation: $lastRec'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: tflite.isLoaded 
                ? () => ref.read(predictionProvider.notifier).runRealInference() 
                : null,
              icon: const Icon(Icons.analytics),
              label: const Text('Run Inference (Fusion)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBleCard(BleService bleService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BLE Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (!bleService.isConnected) ...[
              const Text('Status: Disconnected', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showScanDialog(bleService),
                icon: const Icon(Icons.search),
                label: const Text('Scan & Connect'),
              ),
            ] else ...[
              const Text('Status: Connected to Pico', style: TextStyle(color: Colors.green)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => bleService.requestSync(),
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
            const Text('Real-time Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (lastVal == null)
              const Text('No data received yet.')
            else
              ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: Text('Soil Humidity: ${lastVal.value.toStringAsFixed(2)}%'),
                subtitle: Text('Time: ${DateTime.fromMillisecondsSinceEpoch(lastVal.timestamp).toLocal()}'),
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
                  final name = r.advertisementData.localName.isNotEmpty 
                      ? r.advertisementData.localName 
                      : r.device.platformName;
                  return ListTile(
                    title: Text(name.isEmpty ? 'Unknown Device' : name),
                    subtitle: Text(r.device.remoteId.toString()),
                    onTap: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      bleService.stopScan();
                      bool success = await bleService.connect(r.device);
                      if (!success) {
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
              bleService.stopScan();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
