// ponytail: Minimal CLI Cloud Service Explorer with device selection
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/database/db_sync.dart';

class CloudScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;
  final Function(String) onStatusChange;

  const CloudScreen({
    super.key,
    required this.routines,
    required this.onBack,
    required this.onStatusChange,
  });

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _cloudDevices = [];
  int? _selectedIndex;
  bool _isLoadingDevices = false;
  bool _isTesting = false;
  bool _isSyncing = false;
  bool _isEmulating = false;
  String _connStatus = 'UNKNOWN';
  // ignore: unused_field
  int _unsyncedDevicesCount = 0;
  String _emulationResult = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _checkStatus();
    _loadCloudDevices();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _checkStatus() {
    final devices = widget.routines.db.getSavedDevices();
    setState(() {
      _unsyncedDevicesCount = devices.where((d) => !d.isSynced).length;
    });
  }

  Future<void> _loadCloudDevices() async {
    if (_isLoadingDevices) return;
    setState(() {
      _isLoadingDevices = true;
    });
    try {
      final devices = await widget.routines.cloudApi.getRegisteredDevices();
      if (mounted) {
        setState(() {
          _cloudDevices = devices;
          if (_selectedIndex != null && _selectedIndex! >= _cloudDevices.length) {
            _selectedIndex = _cloudDevices.isNotEmpty ? 0 : null;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (_isTesting) return;
    setState(() {
      _isTesting = true;
    });
    widget.onStatusChange('Testing connection to Cloud Server...');

    try {
      final success = await widget.routines.cloudApi.testConnection();
      if (mounted) {
        setState(() {
          _connStatus = success ? 'CONNECTED' : 'UNREACHABLE';
        });
      }
      widget.onStatusChange(success
          ? 'Cloud API server is online and responding.'
          : 'Cloud API server returned no response or error.');
      await _loadCloudDevices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _connStatus = 'ERROR';
        });
      }
      widget.onStatusChange('Cloud API test failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    widget.onStatusChange('Initiating Cloud Synchronization...');

    try {
      final syncService = SyncService(
        db: widget.routines.db,
        api: widget.routines.cloudApi,
      );
      await syncService.syncDirtyDevices();
      await syncService.discoverAndSyncCloudDevices();
      _checkStatus();
      await _loadCloudDevices();
      widget.onStatusChange('Cloud sync finished.');
    } catch (e) {
      widget.onStatusChange('Cloud sync error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _handleCloudEmulation() async {
    if (_isEmulating) return;
    if (_cloudDevices.isEmpty) {
      await _loadCloudDevices();
    }

    if (_cloudDevices.isEmpty) {
      widget.onStatusChange('Emulation Aborted: No registered station found on Cloud server.');
      return;
    }

    if (_selectedIndex == null || _selectedIndex! >= _cloudDevices.length) {
      widget.onStatusChange('No station selected! Press [1-9] to select a cloud station first.');
      return;
    }

    final devMap = _cloudDevices[_selectedIndex!];
    final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? devMap['deviceId'] ?? 'pico_01').toString();
    final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString();

    setState(() {
      _isEmulating = true;
      _emulationResult = '';
    });
    widget.onStatusChange('Executing Local RF Recommendation in RAM for [$name] ($devId)...');

    try {
      final result = await widget.routines.emulateCloudRecommendationInMemory(devId);
      
      if (mounted) {
        setState(() {
          _emulationResult = 'STATION       : $name ($devId)\n'
              'VERDICT       : ${result['verdict']}\n'
              'RECOMMENDATION: ${result['recommendation']}\n'
              'REF TIMESTAMP : ${result['referenceDate']}\n'
              '48h RAD SUM   : ${(result['shortwaveRadiationSum48h'] as double).toStringAsFixed(1)} J/m²\n'
              'PRED HUMIDITY : ${result['predictedHumidity']}%';
        });
      }
      widget.onStatusChange('In-Memory Cloud Emulation Finished: ${result['verdict']}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _emulationResult = 'Emulation Error: $e';
        });
      }
      widget.onStatusChange('In-Memory Cloud Emulation Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isEmulating = false;
        });
      }
    }
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Number keys 1-9 for selecting cloud device
    final char = event.character;
    if (char != null && RegExp(r'^[1-9]$').hasMatch(char)) {
      final idx = int.parse(char) - 1;
      if (idx < _cloudDevices.length) {
        setState(() {
          _selectedIndex = idx;
          _emulationResult = '';
        });
        final devMap = _cloudDevices[idx];
        final name = (devMap['name'] ?? devMap['deviceName'] ?? devMap['deviceIdentifier'] ?? 'Station').toString();
        widget.onStatusChange('Selected Cloud Station #${idx + 1}: $name');
        return true;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.keyT) {
      _testConnection();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      _handleSync();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyE) {
      _handleCloudEmulation();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.routines.db.getAppSettings();
    final serverUrl = widget.routines.cloudApi.baseUrl;
    final hasApiKey = settings.tfmServerApiKey.isNotEmpty;

    final statusColor = _connStatus == 'CONNECTED'
        ? Colors.greenAccent
        : (_connStatus == 'UNREACHABLE' || _connStatus == 'ERROR'
            ? Colors.redAccent
            : Colors.yellowAccent);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      autofocus: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '=== CLOUD SERVICE INTEGRATION & EMULATION ===',
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isTesting || _isSyncing || _isEmulating || _isLoadingDevices)
              const LinearProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Colors.black26,
              ),
            const SizedBox(height: 8),
            Text(
              'Target Endpoint : $serverUrl',
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            ),
            Text(
              'API Authorization: ${hasApiKey ? "Configured [OK]" : "Missing/Empty"}',
              style: TextStyle(
                color: hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                const Text('Connection State : ', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
                Text(
                  _connStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.greenAccent),
            const SizedBox(height: 4),
            const Text(
              'Registered Cloud Stations (Press [1-9] to select):',
              style: TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (_cloudDevices.isEmpty)
              const Text(
                'No registered stations found on Cloud Server.\nPress [t] to test connection or [s] to sync.',
                style: TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 12),
              )
            else
              Container(
                height: 110,
                child: ListView.builder(
                  itemCount: _cloudDevices.length,
                  itemBuilder: (context, index) {
                    final devMap = _cloudDevices[index];
                    final isSelected = _selectedIndex == index;
                    final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? 'pico_$index').toString();
                    final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString();
                    final lat = devMap['lat'] ?? devMap['latitude'] ?? 'N/A';
                    final lon = devMap['lon'] ?? devMap['longitude'] ?? 'N/A';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.transparent,
                        border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '[${index + 1}] ',
                            style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$name ($devId)',
                            style: TextStyle(
                              color: isSelected ? Colors.greenAccent : Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Lat: $lat, Lon: $lon',
                            style: const TextStyle(color: Colors.white60, fontFamily: 'monospace', fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (_emulationResult.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  child: SingleChildScrollView(
                    child: Text(
                      '[ IN-MEMORY CLOUD EMULATION RESULT ]\n\n$_emulationResult',
                      style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Quick Actions:\n  [1-9] Select Station | [e] Emulate Selected Station | [t] Test API | [s] Sync',
              style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
