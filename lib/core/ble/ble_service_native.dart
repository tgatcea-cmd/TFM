import "dart:async";
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:crypto/crypto.dart';
import 'ble_constants.dart';
import 'cbor_helper.dart';
import 'ble_chunk_assembler.dart';

export 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothDevice, ScanResult, BluetoothConnectionState;

class PicoHandshakeModule {
  final String sharedSecret;
  PicoHandshakeModule({this.sharedSecret = "TFM_CESAR_PICO_SECRET_KEY_2026"});

  Future<List<int>> _readCharacteristicRobust(
    BluetoothCharacteristic char,
  ) async {
    for (int i = 0; i < 3; i++) {
      try {
        print(
          'ble_service_native: Attempting read on ${char.uuid.toString()} (attempt ${i + 1})...',
        );
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
    BluetoothCharacteristic? authChar, {
    void Function(double progress, String message)? onProgress,
  }) async {
    if (authChar == null) {
      print(
        'Handshake Error: ¡Falta la característica dedicada de autenticación (0x14)!',
      );
      return false;
    }

    try {
      print('PicoHandshakeModule: Leyendo estado y nonce desde Auth (0x14)...');
      onProgress?.call(0.1, 'Solicitando nonce de desafío...');

      final authBytes = await _readCharacteristicRobust(authChar);
      final decoded = CborHelper.decode(authBytes);
      final authMap = CborHelper.asMap(decoded);

      // 1. C firmware uses "nonce" instead of "challenge"
      if (authMap == null || !authMap.containsKey('nonce')) {
        print(
          'Handshake Error: El payload de Auth no contiene un nonce. Map: $authMap',
        );
        return false;
      }

      final List<int> nonce = List<int>.from(authMap['nonce'] as List);
      final bool isProvisioned = authMap['prov'] == true;
      print('PicoHandshakeModule: Nonce recibido: $nonce');

      // 2. The 32-byte authKey stored on the device is the SHA-256 of the plain text password
      final passwordBytes = utf8.encode(sharedSecret);
      final authKey = sha256.convert(passwordBytes).bytes;

      // 3. Handle the "all zeros" unprovisioned state by sending setpw
      if (!isProvisioned) {
        print(
          'PicoHandshakeModule: ¡Estación no provisionada! Configurando password inicial...',
        );
        onProgress?.call(0.3, 'Configurando credenciales iniciales...');

        final setpwPayload = {
          'v': 1,
          'op': 'setpw',
          'key': Uint8List.fromList(authKey),
        };
        await authChar.write(CborHelper.encode(setpwPayload));
        await Future.delayed(const Duration(milliseconds: 400));
        // The device is now provisioned and we can proceed to authenticate using the same nonce.
      }

      onProgress?.call(0.5, 'Calculando firma criptográfica (SHA-256)...');

      // 4. Compute proof: SHA256( authKey || nonce ), NOT an HMAC!
      final proofInput = <int>[...authKey, ...nonce];
      final proof = sha256.convert(proofInput).bytes;

      // 5. C firmware expects the proof in the "mac" field
      final authPayload = {
        'v': 1,
        'op': 'auth',
        'mac': Uint8List.fromList(proof),
      };
      final encodedPayload = CborHelper.encode(authPayload);

      print(
        'PicoHandshakeModule: Enviando prueba de verificación a Auth (0x14)...',
      );
      onProgress?.call(0.7, 'Enviando prueba de verificación...');
      await authChar.write(encodedPayload);
      onProgress?.call(0.8, 'Verificando credenciales de acceso...');
      await Future.delayed(const Duration(milliseconds: 400));

      final confirmBytes = await _readCharacteristicRobust(authChar);
      final confirmMap = CborHelper.asMap(CborHelper.decode(confirmBytes));

      // 6. C firmware returns "authed" instead of "authenticated"
      if (confirmMap != null && confirmMap['authed'] == true) {
        print(
          'PicoHandshakeModule: ¡Estación desbloqueada y autenticada con éxito!',
        );
        onProgress?.call(1.0, 'Autenticación completada.');
        return true;
      } else {
        print(
          'PicoHandshakeModule: ¡Fallo de autenticación en la estación real! Status: $confirmMap',
        );
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
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _authChar;

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
      print(
        'BleService: Scan results updated. Discovered devices count: ${results.length}',
      );
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        print(
          '  - Found: "$name" [ID: ${r.device.remoteId}], RSSI: ${r.rssi}, Connectable: ${r.advertisementData.connectable}',
        );
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
        _authChar,
        onProgress: onPairingProgress,
      );

      if (authenticated) {
        print('Handshake successful!');
        _connectedDevice = device;
        _setupStateListener(device);
        await _setupDataNotifications();
        _connectionStateController.add(true);

        // Auto-sync RTC clock with Pico
        await syncTime(0);

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

      if (sUuid == BleConstants.serviceUuid.toLowerCase() ||
          sUuid.contains('5a71a000')) {
        for (var char in service.characteristics) {
          final String cUuid = char.uuid.toString().toLowerCase();

          if (cUuid.contains('0010')) {
            _statusChar = char; // Estado
          } else if (cUuid.contains('0011')) {
            _timeSyncChar = char; // Hora
          } else if (cUuid.contains('0012')) {
            _weatherChar = char; // Clima / Ingestas legado
          } else if (cUuid.contains('0013')) {
            _configChar = char; // Configuración
          } else if (cUuid.contains('0014')) {
            _authChar = char; // Seguridad/Desbloqueo
          } else if (cUuid.contains('0020')) {
            _dataRequestChar = char; // Peticiones
          } else if (cUuid.contains('0021')) {
            _dataResponseChar = char; // Respuestas troceadas
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
  Future<void> syncTime(int timeOffsetHours) async {
    if (_timeSyncChar == null) return;
    
    final debugTime = DateTime.now().add(Duration(hours: timeOffsetHours));
    final payload = {
      'v': 1,
      'op': 'set',
      'ms': debugTime.millisecondsSinceEpoch,
    };
    await _timeSyncChar!.write(CborHelper.encode(payload));
    print('BleService: Time synchronized with station to debug time: $debugTime');
  }

  /// Send hourly temperature forecast to station
  Future<void> sendHourlyForecast(List<double> temperatures) async {
    if (_weatherChar == null) return;
    final payload = {'v': 1, 'temps': temperatures};
    await _weatherChar!.write(CborHelper.encode(payload));
    print('BleService: Sent weather forecast bridge to characteristic (0x12)');
  }

  /// Request database data from station (raw, agg, or pred)
  Future<void> requestData(String kind, {int? from, int? to}) async {
    if (_dataRequestChar == null) return;
    _chunkAssembler.reset();

    final Map<String, dynamic> payload = {'v': 1, 'op': 'get', 'kind': kind};
    if (from != null) payload['from'] = from;
    if (to != null) payload['to'] = to;

    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Requested $kind data from station');
  }

  /// Request station to trigger real-time LSTM inference
  Future<void> triggerInference() async {
    if (_dataRequestChar == null) return;
    _chunkAssembler.reset();
    final payload = {'v': 1, 'op': 'infer'};
    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Sent infer trigger command');
  }

  /// Toggle Pico debug cycle (0x09 equivalent for debug command in request char)
  Future<void> toggleDebugMode() async {
    if (_dataRequestChar == null) return;
    final payload = {'v': 1, 'op': 'debug_toggle'};
    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Toggled debug mode on station');
  }

  /// Send average fill instruction to station
  Future<void> sendFillAverageInstruction() async {
    if (_dataRequestChar == null) return;
    final payload = {'v': 1, 'op': 'fill_avg'};
    await _dataRequestChar!.write(CborHelper.encode(payload));
    print('BleService: Sent fill average instruction');
  }

  Future<void> forceMock72Hours() async => _dataRequestChar?.write(
    CborHelper.encode({'v': 1, 'op': 'mock', 'kind': '48h'}),
  );
}
