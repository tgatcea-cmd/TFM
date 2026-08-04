import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.dbSyncingCloud);

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
      widget.onStatusChange(l10n.dbSyncCompleted(_devices.length));
    } catch (e) {
      widget.onStatusChange(l10n.dbSyncError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleInference() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedIndex == null || _selectedIndex! >= _devices.length) {
      widget.onStatusChange(l10n.dbNoSelection);
      return;
    }
    if (_isInferring) return;

    final dev = _devices[_selectedIndex!];
    setState(() => _isInferring = true);
    widget.onStatusChange(l10n.dbRunningInference(dev.name, dev.deviceIdentifier));

    try {
      await widget.routines.runLocalInference(dev.deviceIdentifier);
      final verdict = widget.routines.inferenceBridge.status.value;

      if (mounted) {
        _extractPredictionStats(dev, overrideVerdict: verdict);
      }
      widget.onStatusChange(l10n.dbInferenceFinished(_translateVerdict(verdict, l10n)));
    } catch (e) {
      widget.onStatusChange(l10n.dbInferenceFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isInferring = false);
    }
  }

  void _handleClearDb() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dbClearTitle, style: AppStyles.sectionTitle),
        content: Text(
          l10n.dbClearDesc,
          style: AppStyles.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: AppStyles.captionStatus),
          ),
          OutlinedButton(
            style: AppStyles.destructiveButtonStyle,
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.routines.clearLocalDatabase();
              _loadDevices();
              setState(() {
                _selectedIndex = null;
                _predictionStats = null;
              });
              widget.onStatusChange(l10n.dbClearSuccess);
            },
            child: Text(l10n.dbBtnClearData),
          ),
        ],
      ),
    );
  }

  String _translateVerdict(String v, AppLocalizations l10n) {
    if (v.contains('IRRIGATE: Soil moisture threshold drop predicted')) return l10n.verdictLstmIrrigate;
    if (v.contains('HEALTHY: Soil moisture level sufficient')) return l10n.verdictLstmHealthy;
    if (v.contains('SATURATION RISK:')) return l10n.verdictRfSaturation;
    if (v.contains('HEALTHY: Irrigation safe')) return l10n.verdictRfHealthy;
    
    if (v.startsWith('Verdict: ')) {
      final sub = v.substring(9);
      return 'Verdict: ${_translateVerdict(sub, l10n)}';
    }

    if (v.startsWith('Perjudicial')) return v.replaceFirst('Perjudicial', l10n.verdictEmuPerjudicial);
    if (v.startsWith('Healthy')) return v.replaceFirst('Healthy', l10n.verdictEmuHealthy);
    return v;
  }

  // Visual Prediction Recommendation Card mirroring HomeScreen
  Widget _buildPredictionCard(AppLocalizations l10n) {
    if (_predictionStats == null) return const SizedBox.shrink();

    final verdict = _predictionStats!['verdict'] as String? ?? l10n.dbRfNotCalculated;
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
              Icon(icon, color: color, size: 26),
              const SizedBox(width: AppStyles.spaceSM),
              Expanded(
                child: Text(
                  isYellowZone ? l10n.dbRfYellowTitle : l10n.dbRfTitle,
                  style: AppStyles.sectionTitle.copyWith(color: color, fontSize: 15),
                ),
              ),
            ],
          ),
          if (isYellowZone) ...[
            const SizedBox(height: AppStyles.spaceXS),
            Text(
              l10n.dbRfYellowWarning(endH, startH),
              style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent),
            ),
          ],
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            _translateVerdict(verdict, l10n),
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
                Expanded(
                  child: Text(
                    l10n.dbRfMinHum((minHum * 100).toStringAsFixed(1), _formatDate(effectiveMinTs)),
                    style: AppStyles.consoleBody,
                  ),
                ),
              ],
            )
          else
            Text(
              l10n.dbRfNoPredictions,
              style: AppStyles.consoleBody,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Top Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              Text(
                l10n.dbScreenTitle,
                style: AppStyles.displayHeader,
              ),
              Wrap(
                spacing: AppStyles.spaceSM,
                runSpacing: AppStyles.spaceSM,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_download),
                    label: Text(l10n.dbBtnSyncCloud),
                    onPressed: _isSyncing || _isInferring ? null : _handleSync,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(l10n.dbBtnClearDb),
                    style: AppStyles.destructiveButtonStyle,
                    onPressed: _isSyncing || _isInferring
                        ? null
                        : _handleClearDb,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),

          if (_isSyncing || _isInferring)
            const Padding(
              padding: EdgeInsets.only(bottom: AppStyles.spaceSM),
              child: LinearProgressIndicator(),
            ),

          // Device List / Details View
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      l10n.dbNoDevices,
                      textAlign: TextAlign.center,
                      style: AppStyles.captionStatus,
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final dev = _devices[index];
                      final isSelected = _selectedIndex == index;
                      final syncColor = dev.isSynced
                          ? AppStyles.successAccent
                          : AppStyles.warningAccent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppStyles.spaceSM),
                        decoration: AppStyles.cardShell(isSelected: isSelected),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            _extractPredictionStats(dev);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppStyles.spaceMD),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: AppStyles.spaceSM,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.memory,
                                          color: isSelected
                                              ? AppStyles.successAccent
                                              : AppStyles.textMuted,
                                        ),
                                        const SizedBox(width: AppStyles.spaceSM),
                                        Text(
                                          dev.name,
                                          style: AppStyles.sectionTitle.copyWith(
                                            color: isSelected
                                                ? AppStyles.successAccent
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: AppStyles.spaceSM),
                                        Text(
                                          '(${dev.deviceIdentifier})',
                                          style: AppStyles.captionStatus,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppStyles.spaceSM,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: syncColor.withValues(alpha: 0.1),
                                        border: Border.all(color: syncColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        dev.isSynced ? l10n.dbStateSynced : l10n.dbStateUnsynced,
                                        style: AppStyles.captionStatus.copyWith(
                                          color: syncColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppStyles.spaceSM),
                                Text(
                                  '${l10n.dbTelemetryInfo(dev.historicValues.length, dev.newPredictions.length)}'
                                  '${dev.latitude != null ? l10n.dbLocationInfo(dev.latitude!.toStringAsFixed(3), dev.longitude!.toStringAsFixed(3)) : ""}',
                                  style: AppStyles.consoleBody,
                                ),

                                // Expand details and prediction card if selected
                                if (isSelected) ...[
                                  const SizedBox(height: AppStyles.spaceMD),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.psychology),
                                    label: Text(l10n.dbBtnRunInference),
                                    onPressed: _isInferring
                                        ? null
                                        : _handleInference,
                                  ),
                                  _buildPredictionCard(l10n),
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
