import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/theme/app_styles.dart';

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
  List<Device> _devices = [];
  int? _selectedIndex;
  bool _isSyncing = false;
  bool _isInferring = false;

  // Stats for the active prediction recommendation card
  Map<String, dynamic>? _predictionStats;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    setState(() {
      _devices = widget.routines.db.getSavedDevices();
      if (_selectedIndex != null && _selectedIndex! >= _devices.length) {
        _selectedIndex = _devices.isNotEmpty ? 0 : null;
      }
    });

    if (_selectedIndex != null && _selectedIndex! < _devices.length) {
      _extractPredictionStats(_devices[_selectedIndex!]);
    }
  }

  String _formatDate(int ms) {
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _extractPredictionStats(Device dev, {String? overrideVerdict}) {
    double? minHum;
    int? minTs;

    for (var p in dev.newPredictions) {
      if (minHum == null || (p.value != null && p.value! < minHum)) {
        minHum = p.value;
        minTs = p.tsMs;
      }
    }

    setState(() {
      _predictionStats = {
        'verdict':
            overrideVerdict ?? widget.routines.inferenceBridge.status.value,
        'minHumidity': minHum,
        'minDateMs': minTs,
        'predictionCount': dev.newPredictions.length,
      };
    });
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    widget.onStatusChange('Syncing with Cloud API...');

    try {
      final syncService = SyncService(
        db: widget.routines.db,
        api: widget.routines.cloudApi,
      );

      // Push dirty devices first
      await syncService.syncDirtyDevices();

      // Discover registered devices from cloud
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
      widget.onStatusChange(
        'Cloud sync completed. Loaded ${_devices.length} devices from cloud/local DB.',
      );
    } catch (e) {
      widget.onStatusChange(
        'Cloud Sync Error: Connection unavailable or failed ($e)',
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleInference() async {
    if (_selectedIndex == null || _selectedIndex! >= _devices.length) {
      widget.onStatusChange('No device selected! Select a device first.');
      return;
    }
    if (_isInferring) return;

    final dev = _devices[_selectedIndex!];
    setState(() => _isInferring = true);
    widget.onStatusChange(
      'Running Random Forest Inference for ${dev.name} (${dev.deviceIdentifier})...',
    );

    try {
      await widget.routines.runLocalInference(dev.deviceIdentifier);
      final verdict = widget.routines.inferenceBridge.status.value;

      if (mounted) {
        _extractPredictionStats(dev, overrideVerdict: verdict);
      }
      widget.onStatusChange('RF Inference Finished: $verdict');
    } catch (e) {
      widget.onStatusChange('Inference Failed: $e');
    } finally {
      if (mounted) setState(() => _isInferring = false);
    }
  }

  void _handleClearDb() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Database?'),
        content: const Text(
          'This will delete all saved station telemetry and prediction records stored locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.routines.clearLocalDatabase();
              _loadDevices();
              setState(() {
                _selectedIndex = null;
                _predictionStats = null;
              });
              widget.onStatusChange('Local DB records cleared successfully.');
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  // Visual Prediction Recommendation Card mirroring HomeScreen
  Widget _buildPredictionCard() {
    if (_predictionStats == null) return const SizedBox.shrink();

    final verdict = _predictionStats!['verdict'] as String? ?? 'NOT CALCULATED';
    final minHum = _predictionStats!['minHumidity'] as double?;
    final minTs = _predictionStats!['minDateMs'] as int?;

    final bool isIrrigate =
        verdict.toUpperCase().contains('IRRIGATE') &&
        !verdict.toUpperCase().contains('DO NOT');
    final color = isIrrigate ? Colors.blueAccent : Colors.greenAccent;
    final icon = isIrrigate ? Icons.water_drop : Icons.eco;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Text(
                'RANDOM FOREST RECOMMENDATION',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: AppStyles.consoleFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verdict,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          if (minHum != null && minTs != null)
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Minimum predicted humidity: ${(minHum * 100).toStringAsFixed(1)}%\nExpected at: ${_formatDate(minTs)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: AppStyles.consoleFontFamily,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else
            const Text(
              'No predictions stored for this device yet.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: AppStyles.consoleFontFamily,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Top Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local DB Devices',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Sync Cloud'),
                    onPressed: _isSyncing || _isInferring ? null : _handleSync,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear DB'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: _isSyncing || _isInferring
                        ? null
                        : _handleClearDb,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isSyncing || _isInferring)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: LinearProgressIndicator(),
            ),

          // Device List / Details View
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      'No saved devices found in Local DB.\nPair a BLE station or run sync with Cloud to populate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final dev = _devices[index];
                      final isSelected = _selectedIndex == index;
                      final syncColor = dev.isSynced
                          ? Colors.greenAccent
                          : Colors.orangeAccent;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected
                                ? Colors.greenAccent
                                : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            _extractPredictionStats(dev);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.memory,
                                      color: isSelected
                                          ? Colors.greenAccent
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      dev.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.greenAccent
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${dev.deviceIdentifier})',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontFamily: AppStyles.consoleFontFamily,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: syncColor.withValues(alpha: 0.1),
                                        border: Border.all(color: syncColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        dev.isSynced ? 'SYNCED' : 'UNSYNCED',
                                        style: TextStyle(
                                          color: syncColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily:
                                              AppStyles.consoleFontFamily,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Telemetry Records: ${dev.historicValues.length}  |  Predictions: ${dev.newPredictions.length}'
                                  '${dev.latitude != null ? "  |  Lat: ${dev.latitude?.toStringAsFixed(3)}, Lon: ${dev.longitude?.toStringAsFixed(3)}" : ""}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: AppStyles.consoleFontFamily,
                                    fontSize: 12,
                                  ),
                                ),

                                // Expand details and prediction card if selected
                                if (isSelected) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.psychology),
                                    label: const Text('Run RF Inference'),
                                    onPressed: _isInferring
                                        ? null
                                        : _handleInference,
                                  ),
                                  _buildPredictionCard(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
