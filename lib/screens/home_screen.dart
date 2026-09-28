import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/core/utils/date_formatter.dart';
import 'package:tfm_app/core/utils/l10n/app_localizations.dart';
import 'package:tfm_app/screens/widgets/inference_card.dart';

/// A stateful widget that displays the main dashboard and device connection status.
///
/// Provides an interface for interacting with a connected BLE device,
/// reviewing the synchronized real-time clock, executing commands,
/// reviewing inference metrics, and viewing a simulated console output.
class HomeScreen extends StatefulWidget {
  /// The collection of CLI routines utilized for handling BLE and inference interactions.
  final CliRoutines routines;
  
  /// Callback invoked to report system state changes or operation status back to the parent.
  /// 
  /// Takes a [String] parameter representing the status message.
  final Function(String) onStatusChange;

  /// Creates a [HomeScreen] with the required dependencies.
  const HomeScreen({
    super.key,
    required this.routines,
    required this.onStatusChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The state associated with [HomeScreen].
///
/// Manages asynchronous BLE streams, real-time clock synchronization, UI states
/// for data fetching, and holds the current prediction statistics.
class _HomeScreenState extends State<HomeScreen> {
  /// The text content presented in the virtual console output area.
  String? _consoleOutput;
  
  /// Subscription to the BLE device's incoming data stream.
  StreamSubscription<Object>? _dataSub;
  
  /// The calculated offset in milliseconds between the local device time and the connected hardware's RTC.
  int? _clockOffsetMs;
  
  /// A periodic timer used to update the estimated device clock UI smoothly.
  Timer? _clockTickTimer;
  
  /// A value notifier used to trigger UI refreshes for the estimated clock without rebuilding the entire screen.
  final ValueNotifier<int> _clockNotifier = ValueNotifier<int>(0);
  
  /// Indicates whether the system is currently retrieving the status from the connected device.
  bool _isFetchingStatus = false;
  
  /// Holds statistics and results from the most recent agronomic prediction/inference run.
  Map<String, dynamic>? _predictionStats;

  /// Copies the virtual console's output to the system clipboard.
  /// 
  /// Displays a SnackBar upon successful copy and updates the parent status.
  void _copyConsoleToClipboard() {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: _consoleOutput ?? l10n.homeConsoleInit));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.homeConsoleCopiedSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    widget.onStatusChange(l10n.homeConsoleCopiedStatus);
  }

  /// Exports the current virtual console output to a JSON file.
  /// 
  /// Saves the file in the application's document directory with a timestamped filename,
  /// capturing the device name and raw output. Notifies the user on success or failure.
  Future<void> _downloadConsoleJson() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final now = DateTime.now();
      final devName = widget.routines.bleService.connectedDevice?.platformName ?? 'unknown_device';
      
      final jsonPayload = {
        'timestamp': now.toIso8601String(),
        'device': devName,
        'consoleOutput': _consoleOutput ?? l10n.homeConsoleInit,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonPayload);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'console_log_${now.millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      
      await file.writeAsString(jsonString);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.homeExportJsonSnack(fileName)),
              duration: const Duration(seconds: 4),
            ),
          );
      }
      widget.onStatusChange(l10n.homeExportJsonStatus(file.path));
    } catch (e) {
      widget.onStatusChange(l10n.homeExportJsonFailed(e.toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    // Listening to async BLE chunks
    _dataSub = widget.routines.bleService.dataStream.listen((data) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(
          () => _consoleOutput = l10n.homeBleAsyncData(_prettyFormatData(data, l10n)),
        );
      }
    });

    // 1-second ticker to advance the estimated live device clock smoothly without full screen rebuilds
    _clockTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _clockOffsetMs != null) {
        _clockNotifier.value++;
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
    _clockNotifier.dispose();
    super.dispose();
  }

  /// Gets the estimated current time of the connected hardware device in milliseconds.
  int? get _estimatedDeviceMs {
    if (_clockOffsetMs == null) return null;
    return DateTime.now().millisecondsSinceEpoch - _clockOffsetMs!;
  }

  /// Returns a localized, human-readable string representing the time gap between local and device clocks.
  String _getPrettifiedGap(int offsetMs, AppLocalizations l10n) {
    final diff = Duration(milliseconds: offsetMs.abs());
    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return l10n.homeGapYears(years.toString());
    } else if (diff.inDays > 0) {
      return l10n.homeGapDays(diff.inDays.toString());
    } else if (diff.inHours > 0) {
      return l10n.homeGapHours(diff.inHours.toString());
    } else if (diff.inMinutes > 0) {
      return l10n.homeGapMins(diff.inMinutes.toString());
    } else {
      return l10n.homeGapSecs(diff.inSeconds.toString());
    }
  }

  /// Formats a UNIX timestamp in milliseconds to a human-readable date string.
  String _formatDate(int ms) {
    return AppDateFormatter.format(ms, showSeconds: true);
  }

  /// Retrieves the current operational status from the connected BLE device.
  /// 
  /// Upon successful retrieval, recalculates the [_clockOffsetMs] for time synchronization UI.
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

  /// Synchronizes the connected hardware device's Real Time Clock (RTC) with the local system time.
  Future<void> _handleSyncTime() async {
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.homeExecutingSync);
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
          _consoleOutput = l10n.homeSyncSuccess(_formatDate(_estimatedDeviceMs!));
        });
      }
      widget.onStatusChange(l10n.homeSyncCompleted);
    } catch (e) {
      setState(() => _consoleOutput = l10n.homeSyncErrorConsole(e.toString()));
      widget.onStatusChange(l10n.homeSyncFailedStatus);
    }
  }

  String _prettyFormatData(dynamic data, AppLocalizations l10n) {
    if (data == null) return l10n.homeVoidOutput;
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
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.homeExecutingAction(name));
    try {
      final res = await action();
      setState(() {
        if (name == 'triggerStationInference' && res is Map) {
          _predictionStats = res as Map<String, dynamic>;
          _consoleOutput = l10n.homeActionRes(name, _prettyFormatData(res['raw'] ?? res, l10n));
        } else {
          _consoleOutput = l10n.homeActionRes(name, _prettyFormatData(res, l10n));
        }
      });
      widget.onStatusChange(l10n.homeActionCompleted(name));
    } catch (e) {
      setState(() => _consoleOutput = l10n.homeActionError(name, e.toString()));
      widget.onStatusChange(l10n.homeActionFailed(name));
    }
  }

  Widget _buildDebugPanel(AppLocalizations l10n) {
    final isLowMoistureActive = widget.routines.inferenceBridge.injectLowMoisture;

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
              Expanded(
                child: Text(
                  l10n.homeDebugTitle,
                  style: AppStyles.consoleBody.copyWith(
                    color: AppStyles.errorAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          Wrap(
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              // Inject Low Moisture Toggle Button
              ElevatedButton.icon(
                icon: Icon(isLowMoistureActive ? Icons.water_drop : Icons.water_drop_outlined),
                label: Text(isLowMoistureActive ? 'Low Moisture: ON (15%)' : 'Inject Low Moisture'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: isLowMoistureActive ? AppStyles.errorAccent : AppStyles.techSecondaryAccent,
                ),
                onPressed: () async {
                  setState(() {
                    widget.routines.inferenceBridge.injectLowMoisture = !isLowMoistureActive;
                  });
                  final devId = widget.routines.bleService.connectedDevice?.remoteId.str ??
                      (widget.routines.db.getSavedDevices().isNotEmpty
                          ? widget.routines.db.getSavedDevices().first.deviceIdentifier
                          : null);
                  if (devId != null) {
                    await _executeAction(
                      'triggerStationInference',
                      () => widget.routines.runLocalInference(
                        devId,
                        forceAllow: true,
                        persistResults: false,
                      ),
                    );
                  }
                },
              ),
              // Mock Data Button - High Contrast Amber
              ElevatedButton.icon(
                icon: const Icon(Icons.science),
                label: Text(l10n.homeBtnMock),
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
                label: Text(l10n.homeBtnClearStorage),
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

  Widget _buildPredictionCard(AppLocalizations l10n) {
    return InferenceCard(
      data: _predictionStats,
      l10n: l10n,
      formatDate: _formatDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = widget.routines.bleService.isConnected;
    final dev = widget.routines.bleService.connectedDevice;

    if (!isConnected) {
      return Center(
        child: Text(
          l10n.homeNoBleConnected,
          textAlign: TextAlign.center,
          style: AppStyles.bodyText,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      children: [
          // 1. Device Title
          Text(
            l10n.homeConnectedTitle(dev?.platformName ?? "Pico Device"),
            style: AppStyles.displayHeader,
          ),
          const SizedBox(height: AppStyles.spaceXS),
          
          // 2. Date and Interactive Sync Time Gap Badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              const Icon(Icons.access_time, size: 16, color: AppStyles.textMuted),
              ValueListenableBuilder<int>(
                valueListenable: _clockNotifier,
                builder: (context, val, child) => Text(
                  _estimatedDeviceMs != null
                      ? _formatDate(_estimatedDeviceMs!)
                      : l10n.homeClockUnknown,
                  style: AppStyles.captionStatus,
                ),
              ),
              if (_clockOffsetMs != null)
                Tooltip(
                  message: l10n.homeTooltipSync,
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
                            l10n.homeGapLabel(_getPrettifiedGap(_clockOffsetMs!, l10n)),
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
              if (_isFetchingStatus)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
                label: Text(l10n.homeBtnReadStatus),
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
                label: Text(l10n.homeBtnRequestData),
                onPressed: () => _executeAction(
                  'requestStationData',
                  () => widget.routines.requestStationData('raw', limit: 150),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: Text(l10n.homeBtnTriggerInference),
                onPressed: () => _executeAction(
                  'triggerStationInference',
                  () => widget.routines.triggerStationInference(),
                ),
              ),
            ],
          ),
          
          _buildPredictionCard(l10n),
          _buildDebugPanel(l10n),
          
          const SizedBox(height: AppStyles.spaceMD),
          Text(
            l10n.homeConsoleTitle,
            style: AppStyles.sectionTitle,
          ),
          const SizedBox(height: AppStyles.spaceSM),
          SizedBox(
            height: 350,
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
                          _consoleOutput ?? l10n.homeConsoleInit,
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
                            tooltip: l10n.homeTooltipCopy,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.download, size: 16, color: AppStyles.textMuted),
                            onPressed: _downloadConsoleJson,
                            tooltip: l10n.homeTooltipDownload,
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
    );
  }
}