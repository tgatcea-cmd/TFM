import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ble/ble_service.dart';
import 'core/db/database_service.dart';
import 'core/api/api_client.dart';
import 'core/db/sync_service.dart';
import 'core/api/open_meteo_client.dart';
import 'data/models/models.dart';
import 'data/models/device.dart';
import 'ui/separate_charts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.init();
  
  runApp(
    ProviderScope(
      child: TestingApp(db: db),
    ),
  );
}

class TestingApp extends StatelessWidget {
  final DatabaseService db;
  const TestingApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Workflow',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: TestingMainPage(db: db),
    );
  }
}

class TestingMainPage extends StatefulWidget {
  final DatabaseService db;
  const TestingMainPage({super.key, required this.db});

  @override
  State<TestingMainPage> createState() => _TestingMainPageState();
}

class _TestingMainPageState extends State<TestingMainPage> {
  late final BleService _bleService;
  late ApiClient _apiClient;
  late SyncService _syncService;
  
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = 'Idle';
  List<dynamic> _discoveredDevices = [];
  StreamSubscription? _scanSub;
  
  List<WeatherRecord> _weatherHistory = [];
  List<double> _radiationForecast = [];
  List<SoilHumidityRecord> _humidityHistory = [];
  List<PredictionRecord> _predictions = [];

  int _hourOffset = 0;

  @override
  void initState() {
    super.initState();
    _bleService = BleService(handshakeModule: PicoHandshakeModule());
    
    final settings = widget.db.getAppSettings();
    _apiClient = ApiClient(
      baseUrl: "http://localhost:3000/api",
      serverUrl: settings.tfmServerUrl.isNotEmpty ? settings.tfmServerUrl : null,
      port: settings.tfmServerPort != 0 ? settings.tfmServerPort : null,
      apiKey: settings.tfmServerApiKey.isNotEmpty ? settings.tfmServerApiKey : "secret_tfm_token",
    );
    
    _syncService = SyncService(db: widget.db, api: _apiClient);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bleService.disconnect();
    super.dispose();
  }

  void _updateStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
    print(msg);
  }

  Future<void> _searchDevices() async {
    _updateStatus('Starting scan...');
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    await _bleService.startScan();
    
    _scanSub = _bleService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _discoveredDevices = results.map((r) => r.device).toList();
        });
      }
    });

    // Scan for 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    await _bleService.stopScan();
    _scanSub?.cancel();
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan complete. Found ${_discoveredDevices.length} devices.';
      });
    }
  }

  Future<void> _showConfigDialog() async {
    final settings = widget.db.getAppSettings();
    final locSettings = widget.db.getLocationSettings();

    final urlCtrl = TextEditingController(text: settings.tfmServerUrl);
    final portCtrl = TextEditingController(text: settings.tfmServerPort.toString());
    final keyCtrl = TextEditingController(text: settings.tfmServerApiKey);
    final latCtrl = TextEditingController(text: locSettings.latitude.toString());
    final lonCtrl = TextEditingController(text: locSettings.longitude.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Server URL (e.g. 192.168.1.10)')),
              TextField(controller: portCtrl, decoration: const InputDecoration(labelText: 'Server Port'), keyboardType: TextInputType.number),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key')),
              const Divider(),
              TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'OpenMeteo Latitude'), keyboardType: TextInputType.number),
              TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'OpenMeteo Longitude'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.db.saveAppSettings(
                tfmServerUrl: urlCtrl.text,
                tfmServerPort: int.tryParse(portCtrl.text) ?? 3000,
                tfmServerApiKey: keyCtrl.text,
                selectedTfliteModel: settings.selectedTfliteModel,
                invertModelOutput: settings.invertModelOutput,
                permitOpenMeteoFill: settings.permitOpenMeteoFill,
                alwaysForceInference: settings.alwaysForceInference,
              );
              widget.db.saveLocationSettings(
                double.tryParse(latCtrl.text) ?? 40.4168, 
                double.tryParse(lonCtrl.text) ?? -3.7038, 
                locSettings.isGps
              );
              
              setState(() {
                _apiClient = ApiClient(
                  baseUrl: "http://localhost:3000/api",
                  serverUrl: urlCtrl.text.isNotEmpty ? urlCtrl.text : null,
                  port: int.tryParse(portCtrl.text),
                  apiKey: keyCtrl.text.isNotEmpty ? keyCtrl.text : "DUMMY_API_KEY",
                );
                _syncService = SyncService(db: widget.db, api: _apiClient);
              });

              Navigator.pop(ctx);
              _updateStatus('Configuration saved.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(dynamic device) async {
    _updateStatus('Connecting to ${device.platformName}...');
    await _bleService.connect(device);
    
    if (mounted) setState(() => _isConnected = true);
    await _sync();
  }

  Future<void> _sync() async {
    _updateStatus('Connected! Syncing time...');
    
    await _bleService.syncTime(0);
    
    _updateStatus('Fetching weather & sending forecast...');
    final loc = widget.db.getLocationSettings();
    final meteoClient = OpenMeteoClient(latitude: loc.latitude, longitude: loc.longitude);
    final weatherData = await meteoClient.fetchForecast();
    
    final now = DateTime.now();
    int currentIndex = weatherData.time.indexWhere((t) => t.isAfter(now) || t.isAtSameMomentAs(now));
    if (currentIndex == -1) currentIndex = 0;
    
    final List<double> futureTemps = [];
    for (int i = 0; i < 24; i++) {
      futureTemps.add(currentIndex + i < weatherData.temperature2m.length 
          ? weatherData.temperature2m[currentIndex + i] : 20.0);
    }

    final List<double> pastTemps = [];
    for (int i = 48; i > 0; i--) {
      pastTemps.add(currentIndex - i >= 0 
          ? weatherData.temperature2m[currentIndex - i] : 20.0);
    }
    
    await _bleService.sendHourlyForecast(pastTemps, futureTemps);
    
    _updateStatus('Requesting raw data...');
    final rawDataFuture = _bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 10), onTimeout: () => []);
    await _bleService.requestData('raw');
    final rawData = await rawDataFuture;
    
    _updateStatus('Requesting predictions...');
    final predDataFuture = _bleService.dataStream.firstWhere((data) => data is List).timeout(const Duration(seconds: 10), onTimeout: () => []);
    await _bleService.requestData('pred');
    final predData = await predDataFuture;

    _updateStatus('Parsing data for charts...');
    _parseDataForCharts(rawData, predData, weatherData, currentIndex);

    _updateStatus('BLE Sync Complete.');
  }

  void _parseDataForCharts(dynamic rawData, dynamic predData, dynamic weatherData, int currentIndex) {
    final List<SoilHumidityRecord> humHistory = [];
    if (rawData is List) {
      final now = DateTime.now().millisecondsSinceEpoch;
      int i = 0;
      for (var item in rawData) {
        if (item is Map && item['kind'] == 'soil_moisture' && item['depth_cm'] == 30) {
          double val = (item['value'] as num).toDouble();
          if (val <= 1.0) val *= 100.0; // scale up to percentage if it's a fraction
          humHistory.add(SoilHumidityRecord(now - (i * 3600000), val));
          i++;
        }
      }
    }
    
    final List<PredictionRecord> preds = [];
    if (predData is List) {
       final now = DateTime.now().millisecondsSinceEpoch;
       int i = 0;
       for (var item in predData) {
         if (item is num && item != -1) {
           double val = item.toDouble();
           if (val <= 1.0 && val > 0) val *= 100.0;
           preds.add(PredictionRecord(now + (i * 3600000), val, '0'));
           i++;
         }
       }
    }
    
    final List<WeatherRecord> wHistory = [];
    final List<double> radForecast = [];
    
    // Fill dummy weather for charts based on openmeteo
    for (int i = 48; i > 0; i--) {
       if (currentIndex - i >= 0) {
          final ts = weatherData.time[currentIndex - i].millisecondsSinceEpoch;
          final temp = weatherData.temperature2m[currentIndex - i];
          final rad = weatherData.shortwaveRadiation[currentIndex - i];
          wHistory.add(WeatherRecord(ts, temp, 0.0, rad, 0.0));
       }
    }
    
    for (int i = 0; i < 24; i++) {
       if (currentIndex + i < weatherData.shortwaveRadiation.length) {
          radForecast.add(weatherData.shortwaveRadiation[currentIndex + i]);
       }
    }

    if (mounted) {
      setState(() {
        _humidityHistory = humHistory;
        _predictions = preds;
        _weatherHistory = wHistory;
        _radiationForecast = radForecast;
      });
    }
  }

  Future<void> _syncToCloudAndLocal() async {
    _updateStatus('Saving to local database...');
    
    final device = Device()
      ..deviceIdentifier = _bleService.connectedDevice?.remoteId.str ?? 'MAC:UNKNOWN'
      ..handshakePassword = 'secret_handshake'
      ..localInferenceCapabilities = true;
      
    // Convert humidity history to HistoricValues
    device.historicValues = _humidityHistory.map((h) => HistoricValue()
      ..tsMs = h.timestamp
      ..depthCm = 30.0
      ..value = h.value).toList();

    await widget.db.saveDevice(device);
    
    _updateStatus('Syncing to cloud...');
    try {
      await _syncService.syncDirtyDevices();
      _updateStatus('Sync to cloud and local storage complete!');
    } catch (e) {
      _updateStatus('Local save OK. Cloud sync failed: $e');
    }
  }

  Future<void> _disconnect() async {
    _updateStatus('Disconnecting...');
    await _bleService.disconnect();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Disconnected';
      });
    }
  }

  Future<void> _refreshMockData() async {
    if (!mounted) return;
    _updateStatus('Refreshing mock...');
    await _bleService.clearStorage();
    await _bleService.forceMock72Hours();
    await _sync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing Workflow'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offset: ${_hourOffset >= 0 ? "+$_hourOffset" : _hourOffset}h',
                style: const TextStyle(fontSize: 12),
              ),
              SizedBox(
                width: 130,
                child: Slider(
                  value: _hourOffset.toDouble(),
                  min: -5,
                  max: 5,
                  divisions: 10,
                  label: '${_hourOffset}h',
                  onChanged: (val) {
                    setState(() {
                      _hourOffset = val.round();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshMockData,
                tooltip: 'Refresh Mock Data',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showConfigDialog,
                tooltip: 'Configuration',
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_statusMessage', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isScanning || _isConnected ? null : _searchDevices,
              child: Text(_isScanning ? 'Scanning...' : '1. Search for IoT Stations Nearby'),
            ),
            
            if (_discoveredDevices.isNotEmpty && !_isConnected) ...[
              const SizedBox(height: 16),
              const Text('Discovered Devices:'),
              ..._discoveredDevices.map((d) => ListTile(
                title: Text(d.platformName.isEmpty ? 'Unknown Device' : d.platformName),
                subtitle: Text(d.remoteId.str),
                trailing: ElevatedButton(
                  onPressed: () => _connect(d),
                  child: const Text('Connect & Sync'),
                ),
              )).toList(),
            ],
            
            const SizedBox(height: 24),
            
            if (_isConnected) ...[
              const Text('3. Render Separate Charts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: RadiationChart(
                  weatherHistory: _weatherHistory,
                  radiationForecast: _radiationForecast,
                  timeOffsetHours: _hourOffset,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: HumidityChart(
                  history: _humidityHistory,
                  predictions: _predictions,
                  timeOffsetHours: _hourOffset,
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _syncToCloudAndLocal,
                child: const Text('4. Synchronize Everything (Cloud & Local)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: _disconnect,
                child: const Text('5. Disconnect'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
