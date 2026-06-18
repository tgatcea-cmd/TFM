import "dart:async";
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'logic/location_service.dart';
import 'data/models/models.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart';
import 'core/localization/languages.dart';
import 'ui/styles.dart';

/// ################### Providers ###################
/// ################### Providers ###################
/// ################### Providers ###################
/// ################### Providers ###################
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
/// ################### Providers ###################
/// ################### Providers ###################
/// ################### Providers ###################
/// ################### Providers ###################

/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################
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

/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################
/// ################### Main ###################

/// ################### Navigation Views ###################
/// ################### Navigation Views ###################
/// ################### Navigation Views ###################
/// ################### Navigation Views ###################
/// ################### Navigation Views ###################
enum NavMode { none, gps, conf }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  NavMode _navMode = NavMode.none;
  bool _showHistoryTable = false;
  bool _isBleSelectorExpanded = false;
  bool _isNavHovered = false;
  double _fontScale = 1.0;
  List<ScanResult> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  int _draggedIndex = -1;
  bool _isDragging = false;
  bool _isBleIconHovered = false;
  final GlobalKey _listKey = GlobalKey();

  // GPS screen state
  double? _tempLat;
  double? _tempLon;
  final double _tempAccuracy = 4.2; // mock accuracy in meters
  bool _gpsLoading = false;
  bool _mapClicked = false;
  final MapController _gpsMapController = MapController();

  // Config screen state
  String _configStationContext = "Cesar's IoT Station (0x01)";

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
        ref.read(bleServiceProvider).disconnect();
      },
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
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

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              // Left persistent navigation pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.center,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isNavHovered = true),
                    onExit: (_) => setState(() => _isNavHovered = false),
                    child: _buildNavigationPill(),
                  ),
                ),
              ),

              // Right content blocks starting from top
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildMainWorkspace(
                    bleService,
                    isConnected,
                    db,
                    weather,
                    prediction,
                    tflite,
                    location,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ################### Navigation Views ###################
  /// ################### Navigation Views ###################
  /// ################### Navigation Views ###################
  /// ################### Navigation Views ###################
  /// ################### Navigation Views ###################

  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  Widget _buildNavigationPill() {
    // ponytail: iOS dynamic island style vertical menu
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isNavHovered ? 80 : 56,
      padding: EdgeInsets.symmetric(
        vertical: 20,
        horizontal: _isNavHovered ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0F172A,
        ).withValues(alpha: _isNavHovered ? 0.95 : 0.7),
        borderRadius: BorderRadius.circular(_isNavHovered ? 36 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isNavHovered ? 0.4 : 0.25),
            blurRadius: _isNavHovered ? 12 : 8,
            offset: Offset(0, _isNavHovered ? 6 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillItem(
            icon: Icons.insights,
            label: 'Sensor',
            isActive: _navMode == NavMode.none,
            onTap: () {
              setState(() {
                _navMode = NavMode.none;
                _mapClicked = false;
                _tempLat = null;
                _tempLon = null;
              });
            },
          ),
          SizedBox(height: _isNavHovered ? 20 : 12),
          _buildPillItem(
            icon: Icons.gps_fixed,
            label: 'GPS',
            isActive: _navMode == NavMode.gps,
            onTap: () {
              setState(() {
                _navMode = NavMode.gps;
                _mapClicked = false;
                _tempLat = null;
                _tempLon = null;
              });
            },
          ),
          SizedBox(height: _isNavHovered ? 20 : 12),
          _buildPillItem(
            icon: Icons.settings,
            label: 'Settings',
            isActive: _navMode == NavMode.conf,
            onTap: () {
              setState(() {
                _navMode = NavMode.conf;
                _mapClicked = false;
                _tempLat = null;
                _tempLon = null;
              });
            },
          ),
          const Divider(color: Colors.white24, height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_fontScale < 1.8) {
                  _fontScale = double.parse(
                    (_fontScale + 0.1).toStringAsFixed(1),
                  );
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: _isNavHovered ? 18 : 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.text_fields,
            color: Colors.white,
            size: _isNavHovered ? 20 : 16,
          ),
          if (_isNavHovered) ...[
            const SizedBox(height: 2),
            Text(
              '${(_fontScale * 100).round()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_fontScale > 0.6) {
                  _fontScale = double.parse(
                    (_fontScale - 0.1).toStringAsFixed(1),
                  );
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: _isNavHovered ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(_isNavHovered ? 12 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppStyles.primaryTeal : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: _isNavHovered ? 24 : 20,
            ),
          ),
          if (_isNavHovered) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################
  /// ################### Dynamic Island ###################

  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################
  Widget _buildMainWorkspace(
    BleService bleService,
    bool isConnected,
    DatabaseService db,
    WeatherState weather,
    double prediction,
    TfliteService tflite,
    LocationSettings location,
  ) {
    switch (_navMode) {
      case NavMode.none:
        return _buildTelemetryView(
          bleService,
          isConnected,
          db,
          weather,
          prediction,
          tflite,
        );
      case NavMode.gps:
        return _buildGpsView(location);
      case NavMode.conf:
        return _buildConfigView(db);
    }
  }

  Widget _buildTelemetryView(
    BleService bleService,
    bool isConnected,
    DatabaseService db,
    WeatherState weather,
    double prediction,
    TfliteService tflite,
  ) {
    final predictions = db.getPredictionHistory();
    final lastRec = predictions.isNotEmpty
        ? predictions.last.recommendation
        : 'None';
    final activeDeviceName = isConnected
        ? (bleService.connectedDevice?.platformName ?? "Cesar IoT Station")
        : "No Device Connected";

    final filtered = isConnected && bleService.connectedDevice != null
        ? _discoveredDevices
              .where(
                (r) =>
                    r.device.remoteId.toString() !=
                    bleService.connectedDevice!.remoteId.toString(),
              )
              .toList()
        : _discoveredDevices;

    return RefreshIndicator(
      onRefresh: () => ref.read(weatherProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ponytail: Placeholder matching collapsed header height so body is positioned correctly
                const SizedBox(height: 56),
                const SizedBox(height: 12),

                // Actionable Recommendation Sub-Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: lastRec.contains('SATURATION')
                              ? AppStyles.dangerRedBg
                              : AppStyles.bgTealLight,
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusSmall,
                          ),
                          border: Border.all(
                            color: lastRec.contains('SATURATION')
                                ? AppStyles.dangerRedBorder
                                : AppStyles.borderTealLight,
                          ),
                        ),
                        child: Text(
                          lastRec.contains('SATURATION')
                              ? 'Overwatering risk | Irrigation not recommended'
                              : 'Follow usual irrigation schedule',
                          textAlign: TextAlign.left,
                          style: lastRec.contains('SATURATION')
                              ? AppStyles.recDangerStyle
                              : AppStyles.recSafeStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(
                        () => _showHistoryTable = !_showHistoryTable,
                      ),
                      icon: Icon(
                        _showHistoryTable ? Icons.show_chart : Icons.history,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Central Content Window (Unified Chart or Tabular History)
                _showHistoryTable
                    ? _buildHistoryTableView(db)
                    : _buildUnifiedChart(db, weather, isConnected),
              ],
            ),

            // ponytail: Floating BLE Selector header overlay positioned above scrollable body content
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? Colors.grey.shade300
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDragging
                            ? Colors.grey.shade500
                            : (_isBleSelectorExpanded
                                  ? Colors.teal.shade300
                                  : Colors.teal.shade200),
                        width: _isDragging ? 2.0 : 1.0,
                      ),
                      boxShadow: _isDragging || _isBleSelectorExpanded
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isBleIconHovered = true),
                          onExit: (_) =>
                              setState(() => _isBleIconHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragStart: (details) {
                              setState(() {
                                _isBleSelectorExpanded = true;
                                _isDragging = true;
                                _draggedIndex = -1;
                                _discoveredDevices = List.from(
                                  bleService.cachedDevices,
                                );
                              });
                              unawaited(bleService.startScan());
                              _scanSub?.cancel();
                              _scanSub = bleService.scanResults.listen((
                                results,
                              ) {
                                if (mounted) {
                                  setState(() {
                                    _discoveredDevices = results;
                                  });
                                }
                              });
                            },
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _isDragging = true;
                              });
                              final currentFiltered =
                                  isConnected &&
                                      bleService.connectedDevice != null
                                  ? _discoveredDevices
                                        .where(
                                          (r) =>
                                              r.device.remoteId.toString() !=
                                              bleService
                                                  .connectedDevice!
                                                  .remoteId
                                                  .toString(),
                                        )
                                        .toList()
                                  : _discoveredDevices;

                              if (currentFiltered.isEmpty) {
                                setState(() {
                                  _draggedIndex = -1;
                                });
                                return;
                              }

                              final RenderBox? renderBox =
                                  _listKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (renderBox != null) {
                                final localPos = renderBox.globalToLocal(
                                  details.globalPosition,
                                );
                                final double relativeY = localPos.dy;
                                if (relativeY >= 0 &&
                                    relativeY <= renderBox.size.height) {
                                  final int index = (relativeY / 56.0).floor();
                                  if (index >= 0 &&
                                      index < currentFiltered.length) {
                                    setState(() {
                                      _draggedIndex = index;
                                    });
                                  } else {
                                    setState(() {
                                      _draggedIndex = -1;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _draggedIndex = -1;
                                  });
                                }
                              }
                            },
                            onVerticalDragEnd: (details) async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              await bleService.stopScan();
                              await _scanSub?.cancel();
                              _scanSub = null;

                              final currentFiltered =
                                  isConnected &&
                                      bleService.connectedDevice != null
                                  ? _discoveredDevices
                                        .where(
                                          (r) =>
                                              r.device.remoteId.toString() !=
                                              bleService
                                                  .connectedDevice!
                                                  .remoteId
                                                  .toString(),
                                        )
                                        .toList()
                                  : _discoveredDevices;

                              final selectedIndex = _draggedIndex;
                              setState(() {
                                _isDragging = false;
                                _isBleSelectorExpanded = false;
                                _draggedIndex = -1;
                              });

                              if (selectedIndex >= 0 &&
                                  selectedIndex < currentFiltered.length) {
                                final targetDevice =
                                    currentFiltered[selectedIndex].device;

                                if (isConnected) {
                                  await bleService.disconnect();
                                }
                                final bool success = await bleService.connect(
                                  targetDevice,
                                );
                                if (success) {
                                  unawaited(
                                    ref
                                        .read(weatherProvider.notifier)
                                        .refresh(),
                                  );
                                } else {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('BLE Connection failed'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isBleIconHovered
                                    ? Colors.teal.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '▲\n▼',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBleSelectorExpanded =
                                    !_isBleSelectorExpanded;
                                if (_isBleSelectorExpanded) {
                                  _discoveredDevices = List.from(
                                    bleService.cachedDevices,
                                  );
                                  _draggedIndex = -1;
                                  _isDragging = false;
                                  unawaited(bleService.startScan());
                                  _scanSub?.cancel();
                                  _scanSub = bleService.scanResults.listen((
                                    results,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _discoveredDevices = results;
                                      });
                                    }
                                  });
                                } else {
                                  unawaited(bleService.stopScan());
                                  _scanSub?.cancel();
                                  _scanSub = null;
                                }
                              });
                            },
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isDragging &&
                                            _draggedIndex >= 0 &&
                                            _draggedIndex < filtered.length
                                        ? 'Pair: ${filtered[_draggedIndex].device.platformName.isNotEmpty ? filtered[_draggedIndex].device.platformName : "Unknown (${filtered[_draggedIndex].device.remoteId.toString()})"}'
                                        : _isDragging
                                        ? 'Drag down to select station...'
                                        : activeDeviceName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isBleSelectorExpanded)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isConnected && !_isDragging) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.bluetooth_connected,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  bleService.connectedDevice?.platformName ??
                                      "Connected Device",
                                ),
                                subtitle: Text(
                                  bleService.connectedDevice?.remoteId
                                          .toString() ??
                                      "",
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade900,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    bleService.disconnect();
                                    setState(() {
                                      _isBleSelectorExpanded = false;
                                    });
                                  },
                                  child: const Text(
                                    'Disconnect',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const Divider(height: 8),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _isDragging
                                  ? 'Drag over a station and release to connect:'
                                  : 'Discovered Stations:',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              key: _listKey,
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: filtered.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.teal,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Scanning...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final r = filtered[index];
                                        final name =
                                            r
                                                .advertisementData
                                                .advName
                                                .isNotEmpty
                                            ? r.advertisementData.advName
                                            : r.device.platformName;
                                        final isHighlighted =
                                            index == _draggedIndex;

                                        return SizedBox(
                                          height: 56,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Container(
                                                width: 24,
                                                alignment: Alignment.center,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: 2,
                                                      color: Colors.black87,
                                                    ),
                                                    if (isHighlighted)
                                                      Container(
                                                        color: _isDragging
                                                            ? Colors
                                                                  .grey
                                                                  .shade300
                                                            : Colors
                                                                  .teal
                                                                  .shade50,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 2,
                                                              vertical: 4,
                                                            ),
                                                        child: const Text(
                                                          '▲\n▼',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            height: 1.1,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isHighlighted
                                                        ? Colors.grey.shade300
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: isHighlighted
                                                        ? Border.all(
                                                            color: Colors
                                                                .grey
                                                                .shade500,
                                                            width: 2.0,
                                                          )
                                                        : null,
                                                  ),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    dense: true,
                                                    title: Text(
                                                      name.isEmpty
                                                          ? 'Unknown Station'
                                                          : name,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            isHighlighted
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      r.device.remoteId
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    trailing: Text(
                                                      '${r.rssi} dBm',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTableView(DatabaseService db) {
    final history = db.getSoilHumidityHistory();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telemetry History Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 10),
        if (history.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No database entries found.'),
            ),
          )
        else
          SizedBox(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                // Reverse order for chronological browsing
                final item = history[history.length - 1 - index];
                final time = DateTime.fromMillisecondsSinceEpoch(
                  item.timestamp,
                );
                final timeStr =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                final dateStr = '${time.year}-${time.month}-${time.day}';
                return ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: Text(
                    'Soil Humidity: ${item.value.toStringAsFixed(2)}%',
                  ),
                  subtitle: Text('$dateStr @ $timeStr'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUnifiedChart(
    DatabaseService db,
    WeatherState weather,
    bool isConnected,
  ) {
    final history = isConnected
        ? db.getSoilHumidityHistory()
        : <SoilHumidityRecord>[];
    final predictions = isConnected
        ? db.getPredictionHistory()
        : <PredictionRecord>[];
    final radiationForecast = isConnected
        ? weather.hourlyRadiationForecast
        : <double>[];
    final weatherHistory = isConnected
        ? db.getWeatherHistory()
        : <WeatherRecord>[];

    return UnifiedChart(
      history: history,
      predictions: predictions,
      radiationForecast: radiationForecast,
      weatherHistory: weatherHistory,
    );
  }

  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################
  /// ################### Data window ###################

  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################
  Widget _buildGpsView(LocationSettings location) {
    if (_tempLat == null || _tempLon == null) {
      _tempLat = location.latitude;
      _tempLon = location.longitude;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Current_Location_label
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Location Controls',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_gpsLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.teal,
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.teal,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                setState(() => _gpsLoading = true);
                                final pos = await ref
                                    .read(locationServiceProvider)
                                    .getCurrentPosition();
                                if (!mounted) return;
                                if (pos != null) {
                                  await ref
                                      .read(locationProvider.notifier)
                                      .updateFromGps();
                                  if (!mounted) return;
                                  final newLoc = ref.read(locationProvider);
                                  setState(() {
                                    _tempLat = newLoc.latitude;
                                    _tempLon = newLoc.longitude;
                                    _gpsLoading = false;
                                    _mapClicked = false;
                                  });
                                  _gpsMapController.move(
                                    ll.LatLng(
                                      newLoc.latitude,
                                      newLoc.longitude,
                                    ),
                                    13.0,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'GPS location pulled and applied automatically!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  setState(() => _gpsLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('GPS Polling failed'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Refresh GPS',
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active Saved Coords: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                  ),
                  Text(
                    'GPS Accuracy: ±${_tempAccuracy}m (Status: Active Fix)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Central content window: INTERACTIVE_MAP
          const SizedBox(height: 8),
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _gpsMapController,
                options: MapOptions(
                  initialCenter: ll.LatLng(_tempLat!, _tempLon!),
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _tempLat = point.latitude;
                      _tempLon = point.longitude;
                      _mapClicked = true;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tfm_app',
                  ),
                  MarkerLayer(
                    markers: [
                      // Current Saved Position marker
                      Marker(
                        point: ll.LatLng(location.latitude, location.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.teal,
                          size: 36,
                        ),
                      ),
                      // Temporary selected marker
                      if (_tempLat != location.latitude ||
                          _tempLon != location.longitude)
                        Marker(
                          point: ll.LatLng(_tempLat!, _tempLon!),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_searching,
                            color: Colors.orange,
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_mapClicked) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(locationProvider.notifier)
                    .updateManual(_tempLat!, _tempLon!);
                setState(() {
                  _mapClicked = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coordinates updated!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################
  /// ################### GPS window ###################

  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################
  Widget _buildConfigView(DatabaseService db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station context switcher
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Setup Device Config Context',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showAllStationsDrawer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_configStationContext ↕',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Admin controls: Clear Database
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Maintenance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Purge Local Database'),
                          content: const Text(
                            'Warning: All historical records, weather information, and predictions will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                db.clearAllData();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Database cleared successfully!',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Clear Database'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear Database'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Minor thresholds configs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Threshold Parameters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('Station Humidity Alert Target (%)'),
                  Slider(
                    value: 45.0,
                    min: 10.0,
                    max: 90.0,
                    divisions: 8,
                    label: '45%',
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 10),
                  const Text('API Weather Update Frequency (Hours)'),
                  Slider(
                    value: 6.0,
                    min: 1.0,
                    max: 24.0,
                    divisions: 23,
                    label: '6h',
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.tr('language_settings'),
                    style: AppStyles.titleStyle,
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ref.watch(localeProvider) == 'en'
                              ? Colors.teal
                              : Colors.grey.shade200,
                          foregroundColor: ref.watch(localeProvider) == 'en'
                              ? Colors.white
                              : Colors.black87,
                        ),
                        onPressed: () =>
                            ref.read(localeProvider.notifier).state = 'en',
                        child: const Text('English (EN)'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ref.watch(localeProvider) == 'es'
                              ? Colors.teal
                              : Colors.grey.shade200,
                          foregroundColor: ref.watch(localeProvider) == 'es'
                              ? Colors.white
                              : Colors.black87,
                        ),
                        onPressed: () =>
                            ref.read(localeProvider.notifier).state = 'es',
                        child: const Text('Español (ES)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################
  /// ################### Settings window ###################

  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  void _showAllStationsDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Stations Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildStationInventoryTile(
                        "Cesar's IoT Station (0x01)",
                        "00:11:22:33:44:01",
                        _configStationContext.contains("Cesar"),
                      ),
                      _buildStationInventoryTile(
                        "Madrid Station Alpha",
                        "00:11:22:33:44:02",
                        _configStationContext.contains("Madrid"),
                      ),
                      _buildStationInventoryTile(
                        "Valencia Station Beta",
                        "00:11:22:33:44:03",
                        _configStationContext.contains("Valencia"),
                      ),
                      _buildStationInventoryTile(
                        "Sevilla Station Gamma",
                        "00:11:22:33:44:04",
                        _configStationContext.contains("Sevilla"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationInventoryTile(String name, String mac, bool isActive) {
    return ListTile(
      leading: Icon(
        Icons.sensors,
        color: isActive ? Colors.green : Colors.grey,
      ),
      title: Text(name),
      subtitle: Text('MAC: $mac'),
      trailing: isActive
          ? const Chip(
              label: Text('ACTIVE CONTEXT'),
              backgroundColor: Colors.tealAccent,
            )
          : null,
      onTap: () {
        setState(() {
          _configStationContext = name;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Switched setup target: $name')));
      },
    );
  }

  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################
  /// ################### IoT Stations ###################

  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
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
              Text(
                'Avg Hum: ${weather.daily!.humidity.mean.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: isConnected && weather.hourlyForecast.isNotEmpty
                    ? () =>
                          bleService.sendHourlyForecast(weather.hourlyForecast)
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
            if (bridge.isRunning.watch(context) ||
                (bridge.progress.watch(context) > 0 &&
                    bridge.progress.watch(context) < 1.0))
              Column(
                children: [
                  LinearProgressIndicator(
                    value: bridge.progress.watch(context),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            Text('RF Model Loaded: ${tflite.isRfLoaded ? 'YES' : 'NO'}'),
            Text(
              'Recommendation: $lastRec',
              style: TextStyle(
                color: lastRec.contains('SATURATION')
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
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

  Widget _buildBleCard(
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
              'BLE Debug Console',
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
                onPressed: () {
                  setState(() {
                    _isBleSelectorExpanded = !_isBleSelectorExpanded;
                    if (_isBleSelectorExpanded) {
                      bleService.startScan();
                    } else {
                      bleService.stopScan();
                    }
                  });
                },
                icon: const Icon(Icons.search),
                label: const Text('Scan & Connect'),
              ),
            ] else ...[
              const Text(
                'Status: Connected (Authenticated)',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
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
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Time Sync Command Sent (0x11)'),
                          ),
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
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Request Raw History Sent (0x20)'),
                          ),
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
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Request Predictions Sent (0x20)'),
                          ),
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
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Trigger FPGA LSTM Inference (0x20)'),
                          ),
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
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Toggle Station Debug Mode (0x20)'),
                          ),
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

  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
  /// ################### DEBUGGING TOOLS ###################
}
