import "dart:async";
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:crypto/crypto.dart';
import 'ble_constants.dart';
import 'cbor_helper.dart';
import 'ble_chunk_assembler.dart';

export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice, ScanResult, BluetoothConnectionState;

/// HMAC-SHA256 Challenge-Response Authentication.
class PicoHandshakeModule {
  final String sharedSecret;
  PicoHandshakeModule({this.sharedSecret = "TFM_CESAR_PICO_SECRET_KEY_2026"});

  Future<List<int>> _readCharacteristicRobust(BluetoothCharacteristic char) async {
    for (int i = 0; i < 3; i++) {
      try {
        print('ble_service_native: Attempting read on ${char.uuid.toString()} (attempt ${i + 1})...');
        return await char.read().timeout(const Duration(seconds: 3));
      } catch (e) {
        print('ble_service_native: Read failed or timed out: $e');
        if (i == 2) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('Failed to read characteristic');
  }

  Future<bool> performHandshake(
    BluetoothDevice device,
    BluetoothCharacteristic? statusChar,
    BluetoothCharacteristic? requestChar, {
    void Function(double progress, String message)? onProgress,
  }) async {
    if (statusChar == null || requestChar == null) {
      print('Handshake Error: Missing status or request characteristic!');
      return false;
    }

    try {
      print('PicoHandshakeModule: Reading challenge nonce from Status (0x10)...');
      onProgress?.call(0.1, 'Requesting challenge nonce...');
      final statusBytes = await _readCharacteristicRobust(statusChar);
      onProgress?.call(0.3, 'Reading challenge nonce...');
      final decoded = CborHelper.decode(statusBytes);
      final statusMap = CborHelper.asMap(decoded);
      
      if (statusMap == null || !statusMap.containsKey('challenge')) {
        print('Handshake Error: Status payload does not contain challenge! Status Map: $statusMap');
        return false;
      }

      final challengeRaw = statusMap['challenge'];
      final List<int> challenge;
      if (challengeRaw is List) {
        challenge = List<int>.from(challengeRaw);
      } else {
        print('Handshake Error: Challenge field is not a List!');
        return false;
      }

      print('PicoHandshakeModule: Challenge nonce received: $challenge');
      onProgress?.call(0.5, 'Computing cryptographic HMAC...');

      // Compute HMAC-SHA256
      final keyBytes = utf8.encode(sharedSecret);
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(challenge);
      final responseBytes = digest.bytes;

      print('PicoHandshakeModule: Computed HMAC-SHA256 response: $responseBytes');
      onProgress?.call(0.7, 'Sending challenge response...');

      // Write authentication command to Request (0x20)
      final authPayload = {
        'v': 1,
        'op': 'auth',
        'resp': Uint8List.fromList(responseBytes),
      };
      final authBytes = CborHelper.encode(authPayload);

      print('PicoHandshakeModule: Writing auth payload (size: ${authBytes.length} bytes)...');
      await requestChar.write(authBytes);
      
      onProgress?.call(0.8, 'Verifying authentication credentials...');
      // Wait briefly for authentication to register on Pico
      await Future.delayed(const Duration(milliseconds: 300));

      // Read status again to confirm authentication success
      final confirmBytes = await _readCharacteristicRobust(statusChar);
      final confirmDecoded = CborHelper.decode(confirmBytes);
      final confirmMap = CborHelper.asMap(confirmDecoded);
      if (confirmMap != null && confirmMap['authenticated'] == true) {
        print('PicoHandshakeModule: Handshake successful & authenticated!');
        onProgress?.call(1.0, 'Authentication successful.');
        return true;
      } else {
        print('PicoHandshakeModule: Handshake failed (not marked as authenticated)! Status: $confirmMap');
        return false;
      }
    } catch (e) {
      print('PicoHandshakeModule Handshake Exception: $e');
      return false;
    }
  }
}

class BleService {
  static BleService? instance;
  final PicoHandshakeModule handshakeModule;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _timeSyncChar;
  BluetoothCharacteristic? _weatherChar;
  BluetoothCharacteristic? _dataRequestChar;
  BluetoothCharacteristic? _dataResponseChar;

  final BleChunkAssembler _chunkAssembler = BleChunkAssembler();

  final _dataController = StreamController<Object>.broadcast();
  Stream<Object> get dataStream => _dataController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  final List<ScanResult> _cachedDevices = [];
  List<ScanResult> get cachedDevices => _cachedDevices;
  Timer? _bgScanTimer;
  StreamSubscription<List<ScanResult>>? _bgScanResultsSubscription;

  BleService({required this.handshakeModule}) {
    instance = this;
    // Enable verbose BLE logs for debugging Linux BlueZ D-Bus transactions
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

    // Listen to assembled completed payloads from the chunk assembler
    _chunkAssembler.completedStream.listen((fullPayloadBytes) {
      try {
        final decoded = CborHelper.decode(fullPayloadBytes);
        if (decoded != null) {
          _dataController.add(decoded);
        }
      } catch (e) {
        print('BleService: Error decoding assembled payload: $e');
      }
    });

    // Continuous debug logging for BLE adapter state and scanning state
    FlutterBluePlus.adapterState.listen((state) {
      print('BleService: Continuous Monitor - BluetoothAdapterState: $state');
    });

    FlutterBluePlus.isScanning.listen((isScanning) {
      print('BleService: Continuous Monitor - isScanning: $isScanning');
    });

    // Cache the discovered list dynamically
    _bgScanResultsSubscription = scanResults.listen((results) {
      _cachedDevices.clear();
      _cachedDevices.addAll(results);
    });

    // Start background scan loop on startup
    _startBackgroundScanLoop();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      print('BLE not supported on this platform');
      return;
    }
    
    // Check adapter state
    final state = await FlutterBluePlus.adapterState.first;
    print('BleService: startScan check - adapterState: $state');
    if (state != BluetoothAdapterState.on) {
      print('BleService: Bluetooth adapter is not ON. Cannot start scan.');
      return;
    }

    print('BleService: Starting BLE scan (timeout: 15s)...');
    
    // Cancel existing scan results subscription if any
    await _scanSubscription?.cancel();
    
    // Subscribe to scan results and print debug logs
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      print('BleService: Scan results updated. Discovered devices count: ${results.length}');
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        print('  - Found: "$name" [ID: ${r.device.remoteId}], RSSI: ${r.rssi}, Connectable: ${r.advertisementData.connectable}');
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    print('BleService: Stopping BLE scan...');
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<bool> connect(
    BluetoothDevice device, {
    void Function(double progress, String message)? onConnectingProgress,
    void Function(double progress, String message)? onPairingProgress,
  }) async {
    try {
      print('Connecting to ${device.platformName}...');
      onConnectingProgress?.call(0.1, 'Connecting to device...');
      await device.connect(autoConnect: false, license: License.nonprofit);

      // Protocol Robustness: Negotiate MTU of 256 bytes
      try {
        print('Negotiating MTU of 256 bytes...');
        onConnectingProgress?.call(0.4, 'Negotiating MTU...');
        await device.requestMtu(256);
        print('MTU negotiation successful');
      } catch (e) {
        print('MTU negotiation failed or not supported: $e');
      }

      print('Discovering services...');
      onConnectingProgress?.call(0.7, 'Discovering services...');
      final List<BluetoothService> services = await device.discoverServices();

      print('Caching characteristics...');
      onConnectingProgress?.call(0.9, 'Caching characteristics...');
      _cacheCharacteristics(services);

      if (_statusChar == null || _dataRequestChar == null) {
        print('Error: Status or Data Request characteristics not found!');
        await device.disconnect();
        return false;
      }

      onConnectingProgress?.call(1.0, 'Connection established.');

      print('Initiating cryptographic handshake...');
      final bool authenticated = await handshakeModule.performHandshake(
        device,
        _statusChar,
        _dataRequestChar,
        onProgress: onPairingProgress,
      );

      if (authenticated) {
        print('Handshake successful!');
        _connectedDevice = device;
        _setupStateListener(device);
        await _setupDataNotifications();
        _connectionStateController.add(true);
        
        // Auto-sync RTC clock with Pico
        await syncTime();

        return true;
      } else {
        print('Handshake failed!');
        await device.disconnect();
        return false;
      }
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  Future<void> _setupDataNotifications() async {
    if (_dataResponseChar == null) return;
    await _dataResponseChar!.setNotifyValue(true);
    _dataResponseChar!.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _chunkAssembler.processChunkBytes(value);
      }
    });
  }

  void _cacheCharacteristics(List<BluetoothService> services) {
    for (var service in services) {
      final String sUuid = service.uuid.toString().toLowerCase();
      print('Found Service: $sUuid');
      
      if (sUuid == BleConstants.serviceUuid.toLowerCase() || sUuid.contains('5a71a000')) {
        print('Target Service Matches!');
        for (var char in service.characteristics) {
          final String cUuid = char.uuid.toString().toLowerCase();
          print('Found Char: $cUuid');
          
          if (cUuid == BleConstants.statusUuid.toLowerCase() || cUuid.contains('0010')) {
            print('Status Char Found');
            _statusChar = char;
          } else if (cUuid == BleConstants.timeSyncUuid.toLowerCase() || cUuid.contains('0011')) {
            print('Time Sync Char Found');
            _timeSyncChar = char;
          } else if (cUuid == BleConstants.weatherUuid.toLowerCase() || cUuid.contains('0012')) {
            print('Weather Char Found');
            _weatherChar = char;
          } else if (cUuid == BleConstants.dataRequestUuid.toLowerCase() || cUuid.contains('0020')) {
            print('Data Request Char Found');
            _dataRequestChar = char;
          } else if (cUuid == BleConstants.dataResponseUuid.toLowerCase() || cUuid.contains('0021')) {
            print('Data Response Char Found');
            _dataResponseChar = char;
          }
        }
      }
    }
  }

  void _setupStateListener(BluetoothDevice device) {
    _stateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _statusChar = null;
        _timeSyncChar = null;
        _weatherChar = null;
        _dataRequestChar = null;
        _dataResponseChar = null;
        _connectionStateController.add(false);
        _stateSubscription?.cancel();
        unawaited(_runBackgroundScan());
      }
    });
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
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
    if (FlutterBluePlus.isScanningNow) return;

    try {
      await startScan();
    } catch (e) {
      print('BleService: Background scan error: $e');
    }
  }

  Future<void> dispose() async {
    _bgScanTimer?.cancel();
    await _bgScanResultsSubscription?.cancel();
    await disconnect();
  }

  /// Synchronize RTC clock with Pico
  Future<void> syncTime() async {
    if (_timeSyncChar == null) return;
    final payload = {
      'v': 1,
      'op': 'set',
      'ms': DateTime.now().millisecondsSinceEpoch,
    };
    await _timeSyncChar!.write(CborHelper.encode(payload));
    print('BleService: Time synchronized with station');
  }

  /// Send hourly temperature forecast to station
  Future<void> sendHourlyForecast(List<double> temperatures) async {
    if (_weatherChar == null) return;
    final payload = {
      'v': 1,
      'temps': temperatures,
    };
    await _weatherChar!.write(CborHelper.encode(payload));
    print('BleService: Sent weather forecast bridge to characteristic (0x12)');
  }

  /// Request database data from station (raw, agg, or pred)
  Future<void> requestData(String kind, {int? from, int? to}) async {
    if (_dataRequestChar == null) return;
    _chunkAssembler.reset();
    
    final Map<String, dynamic> payload = {
      'v': 1,
      'op': 'get',
      'kind': kind,
    };
    if (from != null) payload['from'] = from;
    if (to != null) payload['to'] = to;

    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Requested $kind data from station');
  }

  /// Request station to trigger real-time LSTM inference
  Future<void> triggerInference() async {
    if (_dataRequestChar == null) return;
    _chunkAssembler.reset();
    final payload = {
      'v': 1,
      'op': 'infer',
    };
    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Sent infer trigger command');
  }

  /// Toggle Pico debug cycle (0x09 equivalent for debug command in request char)
  Future<void> toggleDebugMode() async {
    if (_dataRequestChar == null) return;
    final payload = {
      'v': 1,
      'op': 'debug_toggle',
    };
    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Toggled debug mode on station');
  }
}
