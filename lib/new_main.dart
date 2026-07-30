import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ponytail: minimum necessary imports.
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'core/api/api_client.dart';
import 'core/ble/ble_service.dart';
import 'core/ble/connection_routine.dart';
import 'core/ml/inference_routine.dart';
import 'core/db/database_service.dart';
import 'core/db/sync_service.dart';
import 'data/models/app_settings.dart';
import 'ui/views/config_view.dart';
import 'ui/views/telemetry_view.dart';
import 'logic/inference/inference_bridge.dart';
import 'main.dart' as old_main;

// ponytail: single instances via Riverpod
final dbProvider = Provider<DatabaseService>((ref) => throw UnimplementedError());
final appSettingsProvider = Provider<AppSettings>((ref) => ref.watch(dbProvider).getAppSettings());
final bleServiceProvider = Provider<BleService>((ref) => BleService(handshakeModule: PicoHandshakeModule()));
final scanResultsProvider = StreamProvider<List<ScanResult>>((ref) => ref.watch(bleServiceProvider).scanResults);


final syncServiceProvider = Provider<SyncService>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final api = ApiClient(
    serverUrl: '${settings.tfmServerScheme}://${settings.tfmServerUrl}',
    port: settings.tfmServerPort,
    apiKey: settings.tfmServerApiKey,
  );
  return SyncService(db: ref.watch(dbProvider), api: api);
});

final telemetryUpdateProvider = StateProvider<int>((ref) => 0);

final bridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(
    ref.watch(dbProvider),
    onDbUpdated: () {
      ref.read(telemetryUpdateProvider.notifier).state++;
    },
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  // ponytail: Initialize Isar right here before app starts.
  final dbService = DatabaseService();
  await dbService.init();
  
  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(dbService),
        old_main.dbProvider.overrideWithValue(dbService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    
    ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'light': themeMode = ThemeMode.light; break;
      case 'dark': themeMode = ThemeMode.dark; break;
      default: themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'TFM App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode, 
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool isConnected = false;
  bool isScanning = false;
  bool isConnecting = false;
  bool isInferenceRunning = false;
  String? connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _startupCheck();
  }

  Future<void> _startupCheck() async {
    // ponytail: read synchronously since Isar is fully loaded.
    final settings = ref.read(appSettingsProvider);
    
    if (settings.isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfigView(db: ref.read(dbProvider))));
      });
    }
  }

  Future<void> _runInference() async {
    if (connectedDeviceId == null || isInferenceRunning) return;
    
    setState(() => isInferenceRunning = true);
    
    // Fetch latest open-meteo weather so the radiation charts populate
    await ref.read(old_main.weatherServiceProvider).refreshWeather();
    
    await executeInferenceRoutine(
      connectedDeviceId!,
      ref.read(bleServiceProvider),
      ref.read(dbProvider),
      ref.read(appSettingsProvider),
    );
    // Trigger chart redraw
    ref.read(telemetryUpdateProvider.notifier).state++;
    setState(() => isInferenceRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final scanResultsAsync = ref.watch(scanResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TFM App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isConnected && !isInferenceRunning ? _runInference : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfigView(db: ref.read(dbProvider))));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ponytail: Build the minimum that works based on state
            if (!isConnected && !isScanning && !isConnecting) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() => isScanning = true);
                  ref.read(bleServiceProvider).startScan();
                },
                child: const Text('Scan for Devices'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(const SnackBar(content: Text('Syncing with Cloud...')));
                  try {
                    final syncService = ref.read(syncServiceProvider);
                    await syncService.syncDirtyDevices();
                    // ponytail: simple full sync approach.
                    final devices = ref.read(dbProvider).getSavedDevices();
                    for (var d in devices) {
                      await syncService.pullTelemetry(d.deviceIdentifier, 0);
                    }
                    if (context.mounted) {
                      messenger.showSnackBar(const SnackBar(content: Text('Cloud Sync Complete!'), backgroundColor: Colors.teal));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      messenger.showSnackBar(SnackBar(content: Text('Cloud Sync Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Cloud Sync'),
              ),
            ] else if (isScanning) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Scanning for BLE devices...'),
              Expanded(
                child: scanResultsAsync.when(
                  data: (results) {
                    if (results.isEmpty) return const Center(child: Text('No devices found yet.'));
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        final name = r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : r.device.platformName;
                        return ListTile(
                          title: Text(name.isNotEmpty ? name : 'Unknown Device'),
                          subtitle: Text(r.device.remoteId.str),
                          onTap: () async {
                            setState(() {
                              isScanning = false;
                              isConnecting = true;
                            });
                            
                            final success = await executeConnectionRoutine(
                              r.device,
                              ref.read(bleServiceProvider),
                              ref.read(dbProvider),
                            );

                            setState(() {
                              isConnecting = false;
                              isConnected = success;
                              if (success) connectedDeviceId = r.device.remoteId.str;
                            });
                            
                            if (success) await _runInference();
                          },
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (err, stack) => Text('Error scanning: $err'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(bleServiceProvider).stopScan();
                  setState(() => isScanning = false);
                },
                child: const Text('Cancel Scan'),
              )
            ] else if (isConnecting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Connecting and syncing device data...'),
            ] else if (isConnected) ...[
              if (isInferenceRunning) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Running Inference Routine...'),
              ] else ...[
                const Text('Connected! Data synced.'),
              ],
              
              // ponytail: display charts
              const Expanded(child: TelemetryView()),
              
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final bridge = ref.read(bridgeProvider);
                  await bridge.runIrrigationRecommendation(connectedDeviceId);

                  if (context.mounted) {
                    final statusText = bridge.status.value;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(statusText),
                        backgroundColor: statusText.contains('Perjudicial') || statusText.contains('Error') || statusText.contains('SATURATION')
                            ? Colors.red
                            : Colors.teal,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: const Text('Get Irrigation Prediction'),
              ),
            ]
          ],
        ),
      ),
      floatingActionButton: isConnected ? FloatingActionButton(
        onPressed: () {
          ref.read(bleServiceProvider).disconnect();
          setState(() {
            isConnected = false;
            connectedDeviceId = null;
          });
        },
        child: const Icon(Icons.bluetooth_connected),
      ) : null,
    );
  }
}
