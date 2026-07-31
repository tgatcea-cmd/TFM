import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    // Listening to async BLE chunks[cite: 1]
    _dataSub = widget.routines.bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() => _consoleOutput = 'Received Async BLE Data:\n$data');
      }
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }

  Future<void> _executeAction(
    String name,
    Future<dynamic> Function() action,
  ) async {
    widget.onStatusChange('Executing $name...');
    try {
      final res = await action();
      setState(() => _consoleOutput = 'Result for $name:\n${res ?? "Success"}');
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
          Text(
            'Connected: ${dev?.platformName ?? "Pico Device"}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Visual Buttons replacing specific keystrokes[cite: 1]
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sync Time'),
                onPressed: () => _executeAction(
                  'syncTime',
                  () => widget.routines.bleService.syncTime(0),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Read Status'),
                onPressed: () => _executeAction(
                  'readStationStatus',
                  () => widget.routines.readStationStatus(),
                ),
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
