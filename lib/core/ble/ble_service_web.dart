import "dart:async";

enum BluetoothConnectionState { disconnected, connecting, connected, disconnecting }

class BluetoothDevice {
  final String remoteId;
  final String platformName;
  
  BluetoothDevice({required this.remoteId, required this.platformName});

  Future<void> connect({bool autoConnect = false, dynamic license}) async {}
  Future<void> disconnect() async {}
  Future<void> requestMtu(int mtu) async {}
  Future<List<dynamic>> discoverServices() async => [];
  
  Stream<BluetoothConnectionState> get connectionState => 
      Stream.value(BluetoothConnectionState.connected);
}

class AdvertisementData {
  final String advName;
  final bool connectable;
  
  AdvertisementData({required this.advName, this.connectable = true});
}

class ScanResult {
  final BluetoothDevice device;
  final int rssi;
  final AdvertisementData advertisementData;
  
  ScanResult({
    required this.device, 
    required this.rssi, 
    required this.advertisementData,
  });
}

class PicoHandshakeModule {
  final String sharedSecret;
  PicoHandshakeModule({this.sharedSecret = "TFM_CESAR_PICO_SECRET_KEY_2026"});

  Future<bool> performHandshake(
    BluetoothDevice device,
    dynamic statusChar,
    dynamic requestChar,
  ) async {
    return true;
  }
}

class BleService {
  static BleService? instance;
  final PicoHandshakeModule handshakeModule;
  bool _isConnected = false;
  
  final _dataController = StreamController<Object>.broadcast();
  Stream<Object> get dataStream => _dataController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  final List<ScanResult> _cachedDevices = [];
  List<ScanResult> get cachedDevices => _cachedDevices;
  Timer? _bgScanTimer;
  StreamSubscription<List<ScanResult>>? _bgScanResultsSubscription;

  BleService({required this.handshakeModule}) {
    instance = this;

    // Cache the discovered list dynamically
    _bgScanResultsSubscription = scanResults.listen((results) {
      _cachedDevices.clear();
      _cachedDevices.addAll(results);
    });

    // Start background scan loop on startup
    _startBackgroundScanLoop();
  }

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _isConnected
      ? BluetoothDevice(
          remoteId: '00:11:22:33:44:55',
          platformName: 'Cesar IoT Station (Mock)',
        )
      : null;

  Future<void> startScan() async {
    print('BleServiceWeb: Starting mock BLE scan...');
    // Emit mock device after a tiny delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _scanResultsController.add([
        ScanResult(
          device: BluetoothDevice(
            remoteId: '00:11:22:33:44:55', 
            platformName: 'Cesar IoT Station (Mock)',
          ),
          rssi: -55,
          advertisementData: AdvertisementData(
            advName: 'Cesar IoT Station (Mock)',
          ),
        )
      ]);
    });
  }

  Future<void> stopScan() async {
    print('BleServiceWeb: Stopping mock BLE scan...');
  }

  Future<bool> connect(BluetoothDevice device) async {
    print('BleServiceWeb: Connecting to mock device: ${device.platformName}...');
    _isConnected = true;
    _connectionStateController.add(true);
    return true;
  }

  Future<void> disconnect() async {
    print('BleServiceWeb: Disconnecting from mock device...');
    _isConnected = false;
    _connectionStateController.add(false);
    unawaited(_runBackgroundScan());
  }

  void _startBackgroundScanLoop() {
    _bgScanTimer?.cancel();
    unawaited(_runBackgroundScan());
    _bgScanTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isConnected) {
        unawaited(_runBackgroundScan());
      }
    });
  }

  Future<void> _runBackgroundScan() async {
    if (isConnected) return;
    print('BleServiceWeb: Running background mock scan...');
    try {
      await startScan();
    } catch (e) {
      print('BleServiceWeb: Background scan error: $e');
    }
  }

  Future<void> dispose() async {
    _bgScanTimer?.cancel();
    await _bgScanResultsSubscription?.cancel();
    await disconnect();
  }

  Future<void> syncTime() async {
    print('BleServiceWeb: Syncing time (mock)...');
  }

  Future<void> sendHourlyForecast(List<double> temperatures) async {
    print('BleServiceWeb: Sending hourly forecast (mock): $temperatures');
  }

  Future<void> requestData(String kind, {int? from, int? to}) async {
    print('BleServiceWeb: Requesting $kind data (mock)...');
    
    // Simulate receiving data response from station after a brief delay
    if (kind == 'raw') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final now = DateTime.now().millisecondsSinceEpoch;
        _dataController.add([
          {'kind': 'soil_moisture', 'ts_ms': now - 3600000 * 2, 'value': 0.42},
          {'kind': 'soil_moisture', 'ts_ms': now - 3600000 * 1, 'value': 0.43},
          {'kind': 'soil_moisture', 'ts_ms': now, 'value': 0.45},
        ]);
      });
    } else if (kind == 'pred') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final now = DateTime.now().millisecondsSinceEpoch;
        _dataController.add([
          {'kind': 'hs30_forecast', 'ts_ms': now + 3600000, 'value': 0.44},
          {'kind': 'hs30_forecast', 'ts_ms': now + 3600000 * 2, 'value': 0.46},
        ]);
      });
    }
  }

  Future<void> triggerInference() async {
    print('BleServiceWeb: Triggering inference (mock)...');
    // Simulate real-time inference completion event
    Future.delayed(const Duration(milliseconds: 800), () {
      _dataController.add({
        'op': 'infer_done',
        'ok': true,
        'hs30_min': 0.48, // 48% prediction
      });
    });
  }

  Future<void> toggleDebugMode() async {
    print('BleServiceWeb: Toggling station debug mode (mock)...');
  }
}
