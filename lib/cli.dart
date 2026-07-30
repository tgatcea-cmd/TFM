// ponytail: Clean CLI Main Interface with permanent Keystrokes Sidebar & BLE Console Router
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/screens/nearby_screen.dart';
import 'package:tfm_app/screens/config_screen.dart';
import 'package:tfm_app/screens/local_db_screen.dart';
import 'package:tfm_app/screens/cloud_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final routines = CliRoutines();
  await routines.init();
  
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CliScreen(routines: routines),
  ));
}

enum ScreenMode { entry, nearby, cloud, localDb, config }

class CliScreen extends StatefulWidget {
  final CliRoutines routines;
  const CliScreen({super.key, required this.routines});

  @override
  State<CliScreen> createState() => _CliScreenState();
}

class _CliScreenState extends State<CliScreen> {
  final FocusNode _focusNode = FocusNode();
  ScreenMode _mode = ScreenMode.entry;
  String _statusMsg = '';
  String _bleConsoleOutput = 'Console initialized. Select a command shortcut.';

  StreamSubscription<bool>? _connSub;
  StreamSubscription<Object>? _dataSub;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    // Listen to BLE connection state changes to refresh UI
    _connSub = widget.routines.bleService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _statusMsg = isConnected ? 'BLE Device Connected.' : 'BLE Device Disconnected.';
        });
      }
    });

    // Listen to chunked data response stream from BLE
    _dataSub = widget.routines.bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _bleConsoleOutput = 'Received Async BLE Data:\n$data';
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _dataSub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _setStatus(String msg) {
    if (mounted) {
      setState(() => _statusMsg = msg);
    }
  }

  void _setConsoleOutput(String output) {
    if (mounted) {
      setState(() => _bleConsoleOutput = output);
    }
  }

  Future<void> _executeBleApiCall(String name, Future<dynamic> Function() call) async {
    _setStatus('Executing BLE API: $name...');
    _setConsoleOutput('Executing $name...');
    try {
      final res = await call();
      _setConsoleOutput('API Call "$name" Result:\n${res ?? "Success (Void/No Output)"}');
      _setStatus('BLE API $name Completed.');
    } catch (e) {
      _setConsoleOutput('API Call "$name" Failed:\n$e');
      _setStatus('BLE API $name Failed: $e');
    }
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isConnected = widget.routines.bleService.isConnected;

    // --- 1. GLOBAL KEYSTROKES ---

    // Alt+D -> Disconnect BLE
    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyD) {
      widget.routines.bleService.disconnect();
      _setStatus('BLE Device Disconnected.');
      return true;
    }

    // Alt+C -> Config Screen
    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyC) {
      setState(() {
        _mode = ScreenMode.config;
        _statusMsg = '';
      });
      return true;
    }

    // Alt+N -> Nearby Screen
    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyN) {
      setState(() {
        _mode = ScreenMode.nearby;
        _statusMsg = '';
      });
      return true;
    }

    // Alt+L -> Local DB Screen
    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyL) {
      setState(() {
        _mode = ScreenMode.localDb;
        _statusMsg = '';
      });
      return true;
    }

    // Alt+K -> Cloud Services Screen
    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyK) {
      setState(() {
        _mode = ScreenMode.cloud;
        _statusMsg = '';
      });
      return true;
    }

    // ESC -> Return to Main Entry Screen
    if (event.logicalKey == LogicalKeyboardKey.escape && _mode != ScreenMode.entry) {
      setState(() {
        _mode = ScreenMode.entry;
        _statusMsg = '';
      });
      return true;
    }

    // --- 2. ENTRY SCREEN SPECIFIC KEYSTROKES ---
    if (_mode == ScreenMode.entry) {
      if (!isConnected) {
        // Disconnected Entry Shortcuts
        if (event.character == 'n') {
          setState(() => _mode = ScreenMode.nearby);
          return true;
        }
        if (event.character == 'c') {
          setState(() => _mode = ScreenMode.cloud);
          return true;
        }
        if (event.character == 'l') {
          setState(() => _mode = ScreenMode.localDb);
          return true;
        }
      } else {
        // Connected Entry Shortcuts (Direct BLE Service API Calls)
        final ble = widget.routines.bleService;
        if (event.character == 't') {
          _executeBleApiCall('syncTime', () => ble.syncTime(0));
          return true;
        }
        if (event.character == 's') {
          _executeBleApiCall('readStationStatus', () => widget.routines.readStationStatus());
          return true;
        }
        if (event.character == 'c') {
          _executeBleApiCall('readStationConfig', () => widget.routines.readStationConfig());
          return true;
        }
        if (event.character == 'm') {
          _executeBleApiCall('readPinmap', () => ble.readPinmap());
          return true;
        }
        if (event.character == 'd') {
          _executeBleApiCall('requestStationData', () => widget.routines.requestStationData('raw', limit: 150));
          return true;
        }
        // ponytail: Migrated 'p' keystroke to entry screen when connected
        if (event.character == 'p') {
          _executeBleApiCall('fetchLatestPredictionFromConnectedDevice', () => widget.routines.fetchLatestPredictionFromConnectedDevice());
          return true;
        }
        if (event.character == 'f') {
          _executeBleApiCall('triggerStationInference', () => widget.routines.triggerStationInference());
          return true;
        }
        if (event.character == 'w') {
          _executeBleApiCall('sendHourlyForecast', () => widget.routines.sendHourlyForecast());
          return true;
        }
        if (event.character == 'x') {
          _executeBleApiCall('clearStorage', () => ble.clearStorage());
          return true;
        }
        if (event.character == 'b') {
          _executeBleApiCall('toggleDebugMode', () => ble.toggleDebugMode());
          return true;
        }
        if (event.character == 'k') {
          _executeBleApiCall('forceMock', () => ble.forceMock());
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildMainArea() {
    switch (_mode) {
      case ScreenMode.nearby:
        return NearbyScreen(
          routines: widget.routines,
          onBack: () => setState(() => _mode = ScreenMode.entry),
        );
      case ScreenMode.config:
        return ConfigScreen(
          routines: widget.routines,
          onBack: () => setState(() => _mode = ScreenMode.entry),
        );
      case ScreenMode.localDb:
        return LocalDbScreen(
          routines: widget.routines,
          onBack: () => setState(() => _mode = ScreenMode.entry),
          onStatusChange: _setStatus,
        );
      case ScreenMode.cloud:
        return CloudScreen(
          routines: widget.routines,
          onBack: () => setState(() => _mode = ScreenMode.entry),
          onStatusChange: _setStatus,
        );
      case ScreenMode.entry:
        final isConnected = widget.routines.bleService.isConnected;
        final dev = widget.routines.bleService.connectedDevice;

        if (!isConnected) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '=== SAVIA IOT STATION CLI ===',
                  style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Text(
                  '[ Waiting for BLE Device Connection... ]',
                  style: TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'No BLE station connected currently.\nUse [n] or [Alt+N] to open the Nearby Scanner and pair a Pico device.',
                  style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.greenAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '=== CONNECTED STATION: ${dev?.platformName ?? "Pico Device"} (${dev?.remoteId.str ?? ""}) ===',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '[ BLE API CONSOLE OUTPUT ]',
                style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.white10,
                  child: SingleChildScrollView(
                    child: Text(
                      _bleConsoleOutput,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Available Station API Commands: [t] Sync Time | [s] Read Status | [c] Read Config | [m] Read Pinmap\n[d] Request Data | [p] Read Prediction | [f] Trigger Infer | [w] Send Weather | [x] Clear Storage | [b] Debug Mode | [k] Force Mock 72h',
                style: TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        );
    }
  }

  List<Map<String, String>> _getSpecificKeystrokes() {
    final isConnected = widget.routines.bleService.isConnected;

    switch (_mode) {
      case ScreenMode.entry:
        if (!isConnected) {
          return [
            {'key': 'n', 'desc': 'Nearby Scanner'},
            {'key': 'c', 'desc': 'Cloud Status'},
            {'key': 'l', 'desc': 'Local DB Explorer'},
          ];
        }
        return [
          {'key': 't', 'desc': 'Sync Time'},
          {'key': 's', 'desc': 'Read Status'},
          {'key': 'c', 'desc': 'Read Config'},
          {'key': 'm', 'desc': 'Read Pinmap'},
          {'key': 'd', 'desc': 'Request Data'},
          {'key': 'p', 'desc': 'Read Prediction'},
          {'key': 'f', 'desc': 'Trigger Infer'},
          {'key': 'w', 'desc': 'Send Weather'},
          {'key': 'x', 'desc': 'Clear Storage'},
          {'key': 'b', 'desc': 'Toggle Debug'},
          {'key': 'k', 'desc': 'Force Mock'},
        ];
      case ScreenMode.nearby:
        return [
          {'key': 'n', 'desc': 'Re-scan BLE'},
          {'key': 's', 'desc': 'Select Device'},
        ];
      case ScreenMode.localDb:
        return [
          {'key': '1-9', 'desc': 'Select Device'},
          {'key': 's', 'desc': 'Sync with Cloud'},
          {'key': 'r', 'desc': 'RF ML Inference'},
          {'key': 'x', 'desc': 'Clear Local DB'},
        ];
      case ScreenMode.cloud:
        return [
          {'key': '1-9', 'desc': 'Select Station'},
          {'key': 'e', 'desc': 'Emulate Station'},
          {'key': 't', 'desc': 'Test API Health'},
          {'key': 's', 'desc': 'Sync Telemetry'},
        ];
      case ScreenMode.config:
        return [
          {'key': 'c', 'desc': 'Edit Endpoint'},
          {'key': 'i/u', 'desc': 'Irrigation +1h/-1h'},
          {'key': 'p/o', 'desc': 'Prediction +1h/-1h'},
          {'key': 'a', 'desc': 'Save & Apply'},
        ];
    }
  }

  Widget _buildKeystrokesSidebar() {
    final specific = _getSpecificKeystrokes();

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.greenAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ KEYSTROKES ]',
            style: TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '--- GLOBAL ---',
            style: TextStyle(
              color: Colors.yellowAccent,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text('ESC   : Main Menu', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const Text('Alt+D : Disconnect BLE', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const Text('Alt+C : Config Menu', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const Text('Alt+N : Nearby Scanner', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const Text('Alt+L : Local DB', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const Text('Alt+K : Cloud Services', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 16),
          Text(
            '--- SPECIFIC (${_mode.name.toUpperCase()}) ---',
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...specific.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Text(
                      '${item['key']!.padRight(5)} : ',
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        item['desc']!,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.white10,
            child: Text(
              'Active Mode: ${_mode.name.toUpperCase()}',
              style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildMainArea()),
                    const SizedBox(width: 12),
                    _buildKeystrokesSidebar(),
                  ],
                ),
              ),
              if (_statusMsg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent),
                      color: Colors.cyanAccent.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      'STATUS: $_statusMsg',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
