import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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
  Map<String, dynamic>? _predictionStats;

  void _copyConsoleToClipboard() {
    Clipboard.setData(ClipboardData(text: _consoleOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Console output copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    widget.onStatusChange('Console output copied to clipboard.');
  }

  Future<void> _downloadConsoleJson() async {
    try {
      final now = DateTime.now();
      final devName = widget.routines.bleService.connectedDevice?.platformName ?? 'unknown_device';
      final jsonPayload = {
        'timestamp': now.toIso8601String(),
        'device': devName,
        'consoleOutput': _consoleOutput,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonPayload);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'console_log_${now.millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported JSON: $fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      widget.onStatusChange('Console output saved to JSON: ${file.path}');
    } catch (e) {
      widget.onStatusChange('Failed to export JSON: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Listening to async BLE chunks[cite: 1]
    _dataSub = widget.routines.bleService.dataStream.listen((data) {
      if (mounted) {
        setState(
          () => _consoleOutput =
              'Received Async BLE Data:\n${_prettyFormatData(data)}',
        );
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
      setState(() {
        if (name == 'triggerStationInference' && res is Map) {
          _predictionStats = res as Map<String, dynamic>;
          _consoleOutput =
              'Result for $name:\n${_prettyFormatData(res['raw'] ?? res)}';
        } else {
          _consoleOutput = 'Result for $name:\n${_prettyFormatData(res)}';
        }
      });
      widget.onStatusChange('$name Completed.');
    } catch (e) {
      setState(() => _consoleOutput = 'Error during $name:\n$e');
      widget.onStatusChange('$name Failed.');
    }
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.only(top: AppStyles.spaceLG, bottom: AppStyles.spaceMD),
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      decoration: BoxDecoration(
        color: AppStyles.errorAccent.withValues(alpha: 0.05),
        border: Border.all(color: AppStyles.errorAccent, width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppStyles.errorAccent),
              const SizedBox(width: AppStyles.spaceSM),
              Text(
                'DANGER ZONE: DEBUG ONLY (REMOVE BEFORE PROD)',
                style: AppStyles.consoleBody.copyWith(
                  color: AppStyles.errorAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          Wrap(
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              // Mock Data Button - High Contrast Amber
              ElevatedButton.icon(
                icon: const Icon(Icons.science),
                label: const Text('Force Mock 72h'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppStyles.surfaceColor,
                  backgroundColor: AppStyles.warningAccent,
                ),
                onPressed: () => _executeAction(
                  'forceMock',
                  () => widget.routines.bleService.forceMock(),
                ),
              ),
              // Clear Storage Button - Destructive Red
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear Station Storage'),
                style: AppStyles.destructiveButtonStyle,
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

  Widget _buildPredictionCard() {
    if (_predictionStats == null) return const SizedBox.shrink();

    final verdict = _predictionStats!['verdict'] as String? ?? 'UNKNOWN';
    final minHum = _predictionStats!['minHumidity'] as double?;
    final minTs = _predictionStats!['minDateMs'] as int?;

    final settings = widget.routines.db.getAppSettings();
    final now = DateTime.now();
    final h = now.hour;
    final startH = settings.agronomicDayStart;
    final endH = settings.agronomicDayEnd;
    final bool isYellowZone = (endH < startH) 
        ? (h >= endH && h < startH)
        : (h >= endH || h < startH);

    final bool isIrrigate =
        verdict.toUpperCase().contains('IRRIGATE') &&
        !verdict.toUpperCase().contains('DO NOT');

    final color = isYellowZone
        ? AppStyles.warningAccent
        : (isIrrigate ? AppStyles.waterActionAccent : AppStyles.successAccent);

    final icon = isYellowZone
        ? Icons.warning_amber_rounded
        : (isIrrigate ? Icons.water_drop : Icons.eco);

    int? effectiveMinTs = minTs;
    if (effectiveMinTs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(effectiveMinTs);
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        effectiveMinTs += 86400000; // Target following day
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: AppStyles.spaceMD),
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      decoration: AppStyles.aiRecommendationCard(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: AppStyles.spaceSM),
              Text(
                isYellowZone ? 'AI RECOMMENDATION (YELLOW ZONE)' : 'AI RECOMMENDATION',
                style: AppStyles.sectionTitle.copyWith(color: color),
              ),
            ],
          ),
          if (isYellowZone) ...[
            const SizedBox(height: AppStyles.spaceXS),
            Text(
              '[DATA GATHERING PHASE] System gathering telemetry ($endH:00 - $startH:00). Prediction is not in optimal 19:00+ window.',
              style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent),
            ),
          ],
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            verdict,
            style: AppStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppStyles.spaceSM),
          const Divider(color: AppStyles.dividerColor),
          const SizedBox(height: AppStyles.spaceSM),
          if (minHum != null && effectiveMinTs != null)
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppStyles.textSecondary, size: 16),
                const SizedBox(width: AppStyles.spaceSM),
                Text(
                  'Minimum predicted humidity: ${(minHum * 100).toStringAsFixed(1)}%\nExpected at: ${_formatDate(effectiveMinTs)}',
                  style: AppStyles.consoleBody,
                ),
              ],
            )
          else
            const Text(
              'No valid prediction time-series found in database.',
              style: AppStyles.bodyText,
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
          style: AppStyles.bodyText,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Device Title
          Text(
            'Connected: ${dev?.platformName ?? "Pico Device"}',
            style: AppStyles.displayHeader,
          ),
          const SizedBox(height: AppStyles.spaceXS),

          // 2. Date and Interactive Sync Time Gap Badge
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppStyles.textMuted),
              const SizedBox(width: AppStyles.spaceSM),
              Text(
                _estimatedDeviceMs != null
                    ? _formatDate(_estimatedDeviceMs!)
                    : 'Clock status unknown',
                style: AppStyles.captionStatus,
              ),
              if (_clockOffsetMs != null) ...[
                const SizedBox(width: AppStyles.spaceSM),
                Tooltip(
                  message: 'Sync Time',
                  child: InkWell(
                    onTap: _handleSyncTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceSM,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.techSecondaryAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppStyles.techSecondaryAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync,
                            size: 13,
                            color: AppStyles.techSecondaryAccent,
                          ),
                          const SizedBox(width: AppStyles.spaceXS),
                          Text(
                            '${_getPrettifiedGap(_clockOffsetMs!)} gap',
                            style: AppStyles.captionStatus.copyWith(
                              color: AppStyles.techSecondaryAccent,
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
                const SizedBox(width: AppStyles.spaceSM),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppStyles.spaceLG),
          // Action Buttons
          Wrap(
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
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

          _buildPredictionCard(),
          _buildDebugPanel(),

          const SizedBox(height: AppStyles.spaceMD),
          const Text(
            'Console Output:',
            style: AppStyles.sectionTitle,
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: AppStyles.cardShell(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(AppStyles.spaceMD),
                      child: SingleChildScrollView(
                        child: Text(
                          _consoleOutput,
                          style: AppStyles.consoleBody.copyWith(color: AppStyles.successAccent),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppStyles.surfaceColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: AppStyles.textMuted),
                            onPressed: _copyConsoleToClipboard,
                            tooltip: 'Copy to Clipboard',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.download, size: 16, color: AppStyles.textMuted),
                            onPressed: _downloadConsoleJson,
                            tooltip: 'Download JSON',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
