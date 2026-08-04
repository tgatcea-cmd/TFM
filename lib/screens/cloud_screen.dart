import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/l10n/app_localizations.dart';

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
  List<dynamic> _cloudDevices = [];
  int? _selectedIndex;
  
  bool _isLoadingDevices = false;
  bool _isTesting = false;
  bool _isSyncing = false;
  bool _isEmulating = false;
  
  String _connStatus = 'UNKNOWN';
  int _unsyncedDevicesCount = 0;
  
  Map<String, dynamic>? _emulationResultMap;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  String get _localizedConnStatus {
    final l10n = AppLocalizations.of(context)!;
    switch (_connStatus) {
      case 'CONNECTED': return l10n.cloudStatusConnected;
      case 'UNREACHABLE': return l10n.cloudStatusUnreachable;
      case 'ERROR': return l10n.cloudStatusError;
      case 'TESTING...': return l10n.cloudStatusTesting;
      default: return l10n.cloudStatusConnectionUnknown;
    }
  }

  void _checkStatus() {
    final devices = widget.routines.db.getSavedDevices();
    setState(() {
      _unsyncedDevicesCount = devices.where((d) => !d.isSynced).length;
    });
  }

  String _formatDateString(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _loadCloudDevices() async {
    if (_isLoadingDevices || _isDisposed || !mounted) return;
    setState(() => _isLoadingDevices = true);
    
    try {
      final devices = await widget.routines.cloudApi.getRegisteredDevices();
      if (!_isDisposed && mounted) {
        setState(() {
          _cloudDevices = devices;
          _connStatus = 'CONNECTED';
          if (_selectedIndex != null && _selectedIndex! >= _cloudDevices.length) {
            _selectedIndex = _cloudDevices.isNotEmpty ? 0 : null;
          }
        });
      }
    } catch (_) {
      if (!_isDisposed && mounted) {
        setState(() {
          _connStatus = 'UNREACHABLE';
        });
      }
    } finally {
      if (!_isDisposed && mounted) setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _testConnection() async {
    if (_isTesting || _isDisposed || !mounted) return;
    setState(() {
      _isTesting = true;
      _connStatus = 'TESTING...';
    });
    
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.cloudTestingConnection);

    try {
      final success = await widget.routines.cloudApi.testConnection();
      if (_isDisposed || !mounted) return;
      setState(() {
        _connStatus = success ? 'CONNECTED' : 'UNREACHABLE';
      });
      widget.onStatusChange(success ? l10n.cloudApiOnline : l10n.cloudApiNoResponse);
      if (success) {
        await _loadCloudDevices();
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() => _connStatus = 'ERROR');
      widget.onStatusChange(l10n.cloudApiTestFailed(e.toString()));
    } finally {
      if (!_isDisposed && mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.cloudSyncInitiating);

    try {
      final syncService = SyncService(
        db: widget.routines.db,
        api: widget.routines.cloudApi,
      );
      await syncService.syncDirtyDevices();
      await syncService.discoverAndSyncCloudDevices();
      _checkStatus();
      await _loadCloudDevices();
      widget.onStatusChange(l10n.cloudSyncFinished);
    } catch (e) {
      widget.onStatusChange(l10n.cloudSyncError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleCloudEmulation() async {
    if (_isEmulating) return;
    if (_cloudDevices.isEmpty) {
      await _loadCloudDevices();
    }

    final l10n = AppLocalizations.of(context)!;

    if (_cloudDevices.isEmpty) {
      widget.onStatusChange(l10n.cloudEmulationAbortedNoStation);
      return;
    }

    if (_selectedIndex == null || _selectedIndex! >= _cloudDevices.length) {
      widget.onStatusChange(l10n.cloudEmulationNoSelection);
      return;
    }

    final devMap = _cloudDevices[_selectedIndex!];
    final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? devMap['deviceId'] ?? 'pico_01').toString();
    final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString();

    setState(() {
      _isEmulating = true;
      _emulationResultMap = null;
    });
    widget.onStatusChange(l10n.cloudEmulationExecuting(name, devId));

    try {
      final result = await widget.routines.emulateCloudRecommendationInMemory(devId);
      
      if (mounted) {
        setState(() {
          _emulationResultMap = result;
        });
      }
      widget.onStatusChange(l10n.cloudEmulationFinished(result['verdict'].toString()));
    } catch (e) {
      widget.onStatusChange(l10n.cloudEmulationError(e.toString()));
    } finally {
      if (mounted) setState(() => _isEmulating = false);
    }
  }

  Widget _buildApiStatusCard() {
    final settings = widget.routines.db.getAppSettings();
    final serverUrl = widget.routines.cloudApi.baseUrl;
    final hasApiKey = settings.tfmServerApiKey.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    final statusColor = _connStatus == 'CONNECTED'
        ? AppStyles.successAccent
        : (_connStatus == 'UNREACHABLE' || _connStatus == 'ERROR'
            ? AppStyles.errorAccent
            : AppStyles.warningAccent);

    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      decoration: AppStyles.cardShell(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              Text(
                l10n.cloudApiStatusTitle,
                style: AppStyles.sectionTitle.copyWith(
                  color: AppStyles.successAccent,
                ),
              ),
              Wrap(
                spacing: AppStyles.spaceSM,
                runSpacing: AppStyles.spaceSM,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.network_ping),
                    label: Text(l10n.cloudBtnTestApi),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.cloudBtnSync(_unsyncedDevicesCount)),
                    onPressed: _isSyncing ? null : _handleSync,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            l10n.cloudTargetEndpoint(serverUrl),
            style: AppStyles.consoleBody,
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            l10n.cloudApiAuthLabel(hasApiKey ? l10n.cloudApiAuthConfigured : l10n.cloudApiAuthMissing),
            style: AppStyles.consoleBody.copyWith(
              color: hasApiKey ? AppStyles.successAccent : AppStyles.warningAccent,
            ),
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Row(
            children: [
              Text(l10n.cloudConnectionStateLabel, style: AppStyles.consoleBody),
              Text(
                _localizedConnStatus,
                style: AppStyles.consoleBody.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

  Widget _buildEmulationCard() {
    if (_emulationResultMap == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final verdict = _emulationResultMap!['verdict'] as String? ?? l10n.cloudValUnknown;
    final predHum = _emulationResultMap!['predictedHumidity'] as double?;
    final radSum = _emulationResultMap!['shortwaveRadiationSum48h'] as double?;
    final refDate = _emulationResultMap!['referenceDate'] as String?;
    final targetMinDateMs = _emulationResultMap!['targetMinDateMs'] as int?;

    final settings = widget.routines.db.getAppSettings();
    final now = DateTime.now();
    final h = now.hour;
    final startH = settings.agronomicDayStart;
    final endH = settings.agronomicDayEnd;
    final bool isYellowZone = (endH < startH) 
        ? (h >= endH && h < startH)
        : (h >= endH || h < startH);

    final bool isIrrigate = verdict.toUpperCase().contains('IRRIGATE') && !verdict.toUpperCase().contains('DO NOT');

    final color = isYellowZone
        ? AppStyles.warningAccent
        : (isIrrigate ? AppStyles.waterActionAccent : AppStyles.successAccent);

    final icon = isYellowZone
        ? Icons.warning_amber_rounded
        : (isIrrigate ? Icons.water_drop : Icons.eco);

    String targetDateFormatted = l10n.cloudValNA;
    if (targetMinDateMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(targetMinDateMs);
      targetDateFormatted = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (refDate != null) {
      final parsed = DateTime.tryParse(refDate);
      if (parsed != null) {
        final target = parsed.add(const Duration(hours: 24));
        targetDateFormatted = '${target.day.toString().padLeft(2, '0')}/${target.month.toString().padLeft(2, '0')}/${target.year} ${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
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
                  isYellowZone ? l10n.cloudEmuYellowZoneTitle : l10n.cloudEmuNormalTitle,
                  style: AppStyles.sectionTitle.copyWith(color: color, fontSize: 15),
                ),
              ),
            ],
          ),
          if (isYellowZone) ...[
            const SizedBox(height: AppStyles.spaceXS),
            Text(
              l10n.cloudEmuYellowZoneWarning(endH, startH),
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
          if (predHum != null && radSum != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: AppStyles.textSecondary, size: 16),
                    const SizedBox(width: AppStyles.spaceSM),
                    Expanded(
                      child: Text(
                        l10n.cloudEmuMinHumidity((predHum * 100).toStringAsFixed(1), targetDateFormatted),
                        style: AppStyles.consoleBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: AppStyles.textSecondary, size: 16),
                    const SizedBox(width: AppStyles.spaceSM),
                    Expanded(
                      child: Text(
                        l10n.cloudEmuRadSum(radSum.toStringAsFixed(1)),
                        style: AppStyles.consoleBody,
                      ),
                    ),
                  ],
                ),
                if (refDate != null) ...[
                  const SizedBox(height: AppStyles.spaceXS),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppStyles.textSecondary, size: 16),
                      const SizedBox(width: AppStyles.spaceSM),
                      Expanded(
                        child: Text(
                          l10n.cloudEmuRefTimestamp(_formatDateString(refDate)),
                          style: AppStyles.consoleBody,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            )
        ],
      ),
    );
  }

  String _formatCoord(dynamic val, AppLocalizations l10n) {
    if (val == null) return l10n.cloudValNA;
    if (val is num) return val.toDouble().toStringAsFixed(4);
    if (val is String) {
      final d = double.tryParse(val);
      if (d != null) return d.toStringAsFixed(4);
      return val;
    }
    return val.toString();
  }

  String _resolveCoords(String devId, dynamic rawLat, dynamic rawLon, AppLocalizations l10n) {
    final serverLat = _formatCoord(rawLat, l10n);
    final serverLon = _formatCoord(rawLon, l10n);
    if (serverLat != l10n.cloudValNA && serverLon != l10n.cloudValNA) {
      return l10n.cloudCoordsLatLon(serverLat, serverLon);
    }

    final devices = widget.routines.db.getSavedDevices();
    for (var dev in devices) {
      if (dev.deviceIdentifier == devId && dev.latitude != null && dev.longitude != null) {
        return l10n.cloudCoordsLatLon(dev.latitude!.toStringAsFixed(4), dev.longitude!.toStringAsFixed(4));
      }
    }

    final appLoc = widget.routines.db.getLocationSettings();
    if (appLoc.latitude != 0.0 || appLoc.longitude != 0.0) {
      return l10n.cloudCoordsLatLon(appLoc.latitude.toStringAsFixed(4), appLoc.longitude.toStringAsFixed(4));
    }

    return l10n.cloudCoordsNA;
  }

  String _resolveDeviceDisplayName(String devId, String serverName) {
    final devices = widget.routines.db.getSavedDevices();
    for (var dev in devices) {
      if (dev.deviceIdentifier == devId && dev.name.isNotEmpty && dev.name != "Unknown Station") {
        return dev.name;
      }
    }
    return serverName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cloudHeaderTitle,
            style: AppStyles.displayHeader,
          ),
          const SizedBox(height: AppStyles.spaceMD),

          _buildApiStatusCard(),

          const SizedBox(height: AppStyles.spaceMD),
          
          if (_isTesting || _isSyncing || _isEmulating || _isLoadingDevices)
            const Padding(
              padding: EdgeInsets.only(bottom: AppStyles.spaceMD),
              child: LinearProgressIndicator(),
            ),

          Text(
            l10n.cloudRegisteredStationsTitle,
            style: AppStyles.sectionTitle,
          ),
          const SizedBox(height: AppStyles.spaceSM),

          Expanded(
            child: _cloudDevices.isEmpty
                ? Center(
                    child: Text(
                      l10n.cloudNoStationsFound,
                      textAlign: TextAlign.center,
                      style: AppStyles.captionStatus,
                    ),
                  )
                : ListView.builder(
                    itemCount: _cloudDevices.length,
                    itemBuilder: (context, index) {
                      final devMap = _cloudDevices[index];
                      final isSelected = _selectedIndex == index;
                      final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? devMap['deviceId'] ?? 'pico_$index').toString();
                      final serverName = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString();
                      final name = _resolveDeviceDisplayName(devId, serverName);
                      final rawLat = devMap['lat'] ?? devMap['latitude'];
                      final rawLon = devMap['lon'] ?? devMap['longitude'] ?? devMap['lng'];
                      final coordsStr = _resolveCoords(devId, rawLat, rawLon, l10n);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppStyles.spaceSM),
                        decoration: AppStyles.cardShell(isSelected: isSelected),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              _emulationResultMap = null;
                            });
                            widget.onStatusChange(l10n.cloudSelectedStationMsg(name));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppStyles.spaceMD),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: AppStyles.spaceXS,
                                  children: [
                                    Icon(
                                      Icons.cloud,
                                      color: isSelected ? AppStyles.successAccent : AppStyles.textMuted,
                                    ),
                                    const SizedBox(width: AppStyles.spaceSM),
                                    Text(
                                      name,
                                      style: AppStyles.sectionTitle.copyWith(
                                        color: isSelected ? AppStyles.successAccent : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: AppStyles.spaceSM),
                                    Text(
                                      '($devId)',
                                      style: AppStyles.captionStatus,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  l10n.cloudCoordinatesLabel(coordsStr),
                                  style: AppStyles.consoleBody,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: AppStyles.spaceMD),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.memory),
                                    label: Text(l10n.cloudBtnEmulateStation),
                                    onPressed: _isEmulating ? null : _handleCloudEmulation,
                                  ),
                                  _buildEmulationCard(),
                                ]
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