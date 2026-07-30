// ponytail: Minimal CLI Local DB Explorer & Inference runner
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/database/db_sync.dart';

class LocalDbScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;
  final Function(String) onStatusChange;

  const LocalDbScreen({
    super.key,
    required this.routines,
    required this.onBack,
    required this.onStatusChange,
  });

  @override
  State<LocalDbScreen> createState() => _LocalDbScreenState();
}

class _LocalDbScreenState extends State<LocalDbScreen> {
  final FocusNode _focusNode = FocusNode();
  List<Device> _devices = [];
  int? _selectedIndex;
  bool _isSyncing = false;
  bool _isInferring = false;
  String _inferenceResult = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadDevices();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadDevices() {
    setState(() {
      _devices = widget.routines.db.getSavedDevices();
      if (_selectedIndex != null && _selectedIndex! >= _devices.length) {
        _selectedIndex = _devices.isNotEmpty ? 0 : null;
      }
    });
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    widget.onStatusChange('Syncing with Cloud API...');

    try {
      final syncService = SyncService(
        db: widget.routines.db,
        api: widget.routines.cloudApi,
      );
      
      // Push dirty devices first
      await syncService.syncDirtyDevices();

      // Discover registered devices from cloud (populates local DB if empty)
      await syncService.discoverAndSyncCloudDevices();

      // Pull latest telemetry for each existing device
      for (var dev in widget.routines.db.getSavedDevices()) {
        try {
          final latestTs = dev.historicValues.isNotEmpty
              ? (dev.historicValues.last.tsMs ?? 0)
              : 0;
          await syncService.pullTelemetry(dev.deviceIdentifier, latestTs);
        } catch (_) {}
      }

      _loadDevices();
      widget.onStatusChange('Cloud sync completed. Loaded ${_devices.length} devices from cloud/local DB.');
    } catch (e) {
      widget.onStatusChange('Cloud Sync Error: Connection unavailable or failed ($e)');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _handleInference() async {
    if (_selectedIndex == null || _selectedIndex! >= _devices.length) {
      widget.onStatusChange('No device selected! Press [1-9] to select a device first.');
      return;
    }
    if (_isInferring) return;

    final dev = _devices[_selectedIndex!];
    setState(() {
      _isInferring = true;
      _inferenceResult = '';
    });
    widget.onStatusChange('Running Random Forest Inference for ${dev.name} (${dev.deviceIdentifier})...');

    try {
      await widget.routines.runLocalInference(dev.deviceIdentifier);
      final verdict = widget.routines.inferenceBridge.status.value;
      if (mounted) {
        setState(() {
          _inferenceResult = verdict;
        });
      }
      widget.onStatusChange('RF Inference Finished: $verdict');
    } catch (e) {
      widget.onStatusChange('Inference Failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInferring = false;
        });
      }
    }
  }

  void _handleClearDb() {
    widget.routines.clearLocalDatabase();
    _loadDevices();
    setState(() {
      _inferenceResult = '';
    });
    widget.onStatusChange('Local DB records cleared successfully.');
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Number keys 1-9 for selecting device
    final char = event.character;
    if (char != null && RegExp(r'^[1-9]$').hasMatch(char)) {
      final idx = int.parse(char) - 1;
      if (idx < _devices.length) {
        setState(() {
          _selectedIndex = idx;
          _inferenceResult = '';
        });
        widget.onStatusChange('Selected device #${idx + 1}: ${_devices[idx].name}');
        return true;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      _handleSync();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _handleInference();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyX) {
      _handleClearDb();
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
              '=== LOCAL DATABASE DEVICE EXPLORER ===',
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isSyncing || _isInferring)
              const LinearProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Colors.black26,
              ),
            const SizedBox(height: 8),
            if (_devices.isEmpty)
              const Text(
                'No saved devices found in Local DB.\nPair a BLE station or run sync with Cloud to populate.',
                style: TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 14),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final dev = _devices[index];
                    final isSelected = _selectedIndex == index;
                    final syncStatus = dev.isSynced ? '[SYNCED]' : '[UNSYNCED]';
                    final syncColor = dev.isSynced ? Colors.greenAccent : Colors.orangeAccent;
                    final telemetryCount = dev.historicValues.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.greenAccent : Colors.white24,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '[${index + 1}] ',
                                style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${dev.name} (${dev.deviceIdentifier})',
                                style: TextStyle(
                                  color: isSelected ? Colors.greenAccent : Colors.white,
                                  fontFamily: 'monospace',
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                syncStatus,
                                style: TextStyle(
                                  color: syncColor,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '  Telemetry Records: $telemetryCount | Predictions: ${dev.newPredictions.length} | Lat: ${dev.latitude?.toStringAsFixed(3)}, Lon: ${dev.longitude?.toStringAsFixed(3)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          if (isSelected && _inferenceResult.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              child: Text(
                                '>> RF INFERENCE VERDICT: $_inferenceResult',
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
