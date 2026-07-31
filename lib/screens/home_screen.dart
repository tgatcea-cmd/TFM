import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';

class HomeScreen extends StatefulWidget {
  final CliRoutines routines;
  final Function(String) onStatusChange;

  const HomeScreen({
    super.key,
    required this.routines,
    required this.onStatusChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _consoleOutput = 'Console initialized. Awaiting commands...';
  StreamSubscription<Object>? _dataSub;
  int? _clockOffsetMs;
  Timer? _clockTickTimer;
  bool _isFetchingStatus = false;

  @override
  void initState() {
    super.initState();
    // Listening to async BLE chunks[cite: 1]
    _dataSub = widget.routines.bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _consoleOutput = 'Received Async BLE Data:\n${_prettyFormatData(data)}');
      }
    });

    // 1-second ticker to advance the estimated live device clock smoothly
    _clockTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _clockOffsetMs != null) {
        setState(() {});
      }
    });

    if (widget.routines.bleService.isConnected) {
      _fetchDeviceStatus();
    }
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _clockTickTimer?.cancel();
    super.dispose();
  }

  int? get _estimatedDeviceMs {
    if (_clockOffsetMs == null) return null;
    return DateTime.now().millisecondsSinceEpoch - _clockOffsetMs!;
  }

  String _getPrettifiedGap(int offsetMs) {
    final diff = Duration(milliseconds: offsetMs.abs());

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${diff.inSeconds} sec';
    }
  }

  String _formatDate(int ms) {
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchDeviceStatus() async {
    setState(() => _isFetchingStatus = true);
    try {
      final status = await widget.routines.readStationStatus();
      if (mounted && status != null && status['now_ms'] != null) {
        final fetchTimeMs = DateTime.now().millisecondsSinceEpoch;
        final deviceNowMs = status['now_ms'] as int;
        setState(() {
          _clockOffsetMs = fetchTimeMs - deviceNowMs;
        });
      }
    } catch (_) {
      // Handled silently or logged to console
    } finally {
      if (mounted) setState(() => _isFetchingStatus = false);
    }
  }

  Future<void> _handleSyncTime() async {
    widget.onStatusChange('Executing Sync Time...');
    try {
      // 1. Send the sync command
      await widget.routines.bleService.syncTime(0);

      // 2. Wait a brief moment for the station to process the new RTC value
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Re-read the status to visually update the gap
      final status = await widget.routines.readStationStatus();
      if (status != null && status['now_ms'] != null) {
        final fetchTimeMs = DateTime.now().millisecondsSinceEpoch;
        final deviceNowMs = status['now_ms'] as int;
        setState(() {
          _clockOffsetMs = fetchTimeMs - deviceNowMs;
          _consoleOutput =
              'Time Synced. New internal clock: ${_formatDate(_estimatedDeviceMs!)}';
        });
      }
      widget.onStatusChange('Sync Time Completed.');
    } catch (e) {
      setState(() => _consoleOutput = 'Error during Sync Time:\n$e');
      widget.onStatusChange('Sync Time Failed.');
    }
  }

  String _prettyFormatData(dynamic data) {
    if (data == null) return "Success (Void/No Output)";
    if (data is Map || data is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      } catch (_) {
        return data.toString();
      }
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (_) {
        return data;
      }
    }
    return data.toString();
  }

  Future<void> _executeAction(
    String name,
    Future<dynamic> Function() action,
  ) async {
    widget.onStatusChange('Executing $name...');
    try {
      final res = await action();
      setState(() => _consoleOutput = 'Result for $name:\n${_prettyFormatData(res)}');
      widget.onStatusChange('$name Completed.');
    } catch (e) {
      setState(() => _consoleOutput = 'Error during $name:\n$e');
      widget.onStatusChange('$name Failed.');
    }
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.05,
        ), // Faint red warning background
        border: Border.all(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'DANGER ZONE: DEBUG ONLY (REMOVE BEFORE PROD)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily:
                      AppStyles.consoleFontFamily, // Using your style token
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Mock Data Button - High Contrast Yellow
              ElevatedButton.icon(
                icon: const Icon(Icons.science),
                label: const Text('Force Mock 72h'),
                style: ElevatedButton.styleFrom(
                  foregroundColor:
                      Colors.black, // Dark text on bright background
                  backgroundColor: Colors.yellowAccent,
                  side: const BorderSide(color: Colors.orange, width: 2),
                ),
                onPressed: () => _executeAction(
                  'forceMock',
                  () => widget.routines.bleService.forceMock(),
                ),
              ),
              // Clear Storage Button - Destructive Red
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear Station Storage'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade900,
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                onPressed: () => _executeAction(
                  'clearStorage',
                  () => widget.routines.bleService.clearStorage(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.routines.bleService.isConnected;
    final dev = widget.routines.bleService.connectedDevice;

    if (!isConnected) {
      return const Center(
        child: Text(
          "No BLE station connected.\nUse the 'Nearby' tab to pair a Pico device.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Device Title
          Text(
            'Connected: ${dev?.platformName ?? "Pico Device"}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          // 2. Grayed-out Date and Interactive Sync Time Gap Badge
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                _estimatedDeviceMs != null
                    ? _formatDate(_estimatedDeviceMs!)
                    : 'Clock status unknown',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: AppStyles.consoleFontFamily,
                  fontSize: 14,
                ),
              ),
              if (_clockOffsetMs != null) ...[
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Sync Time',
                  child: InkWell(
                    onTap: _handleSyncTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync, size: 13, color: Colors.cyanAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${_getPrettifiedGap(_clockOffsetMs!)} gap',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontFamily: AppStyles.consoleFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (_isFetchingStatus) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Read Status'),
                onPressed: () async => {
                  await _executeAction(
                    'readStationStatus',
                    () => widget.routines.readStationStatus(),
                  ),
                  _fetchDeviceStatus(),
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Request Data'),
                onPressed: () => _executeAction(
                  'requestStationData',
                  () => widget.routines.requestStationData('raw', limit: 150),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('Trigger Inference'),
                onPressed: () => _executeAction(
                  'triggerStationInference',
                  () => widget.routines.triggerStationInference(),
                ),
              ),
            ],
          ),

          _buildDebugPanel(),

          const SizedBox(height: 16),
          const Text(
            'Console Output:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _consoleOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
