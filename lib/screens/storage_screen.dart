import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/core/utils/l10n/app_localizations.dart';
import 'package:tfm_app/screens/widgets/inference_card.dart';

/// Represents a unified model of a station, combining data from local database storage
/// and the cloud platform.
///
/// This separation of concerns preserves architectural integrity by keeping data
/// logic isolated from the UI layer. It allows the system to seamlessly handle
/// devices that exist only locally, only in the cloud, or in both locations simultaneously.
class UnifiedStation {
  /// The unique identifier of the station/device.
  final String id;
  
  /// The human-readable name of the station.
  final String name;
  
  /// The local device record from the SQLite database, if it exists.
  final Device? localDevice;
  
  /// The remote device record fetched from the cloud API, if it exists.
  final Map<String, dynamic>? cloudDevice;

  /// Creates a [UnifiedStation] linking an [id] and [name] with optional
  /// [localDevice] and [cloudDevice] data sources.
  UnifiedStation({
    required this.id,
    required this.name,
    this.localDevice,
    this.cloudDevice,
  });

  bool get hasLocal => localDevice != null;
  bool get hasCloud => cloudDevice != null;
  bool get isSynced => localDevice?.isSynced ?? false;

  double? get latitude {
    if (localDevice?.latitude != null) return localDevice!.latitude;
    if (cloudDevice != null) {
      final rawLat = cloudDevice!['lat'] ?? cloudDevice!['latitude'];
      if (rawLat is num) return rawLat.toDouble();
      if (rawLat is String) return double.tryParse(rawLat);
    }
    return null;
  }

  double? get longitude {
    if (localDevice?.longitude != null) return localDevice!.longitude;
    if (cloudDevice != null) {
      final rawLon = cloudDevice!['lon'] ?? cloudDevice!['longitude'] ?? cloudDevice!['lng'];
      if (rawLon is num) return rawLon.toDouble();
      if (rawLon is String) return double.tryParse(rawLon);
    }
    return null;
  }
}

/// A stateful widget that displays a dashboard for managing stored telemetry and station data.
///
/// It allows users to view synchronized and unsynchronized stations, test cloud API connectivity,
/// force synchronization of local telemetry to the cloud, and run local AI inferences
/// or cloud emulations on available data.
class StorageScreen extends StatefulWidget {
  /// The CLI routines interface used for database operations, API requests, and inference.
  final CliRoutines routines;
  
  /// Callback triggered when the user initiates a back navigation.
  final VoidCallback onBack;
  
  /// Callback used to report status updates to the parent layout.
  final Function(String) onStatusChange;

  /// Creates a [StorageScreen].
  ///
  /// Requires [routines] for underlying system logic, [onBack] for navigation,
  /// and [onStatusChange] for emitting UI notifications.
  const StorageScreen({
    super.key,
    required this.routines,
    required this.onBack,
    required this.onStatusChange,
  });

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

/// The state class for [StorageScreen], managing UI logic for data synchronization,
/// list selections, and orchestrating API/database commands.
class _StorageScreenState extends State<StorageScreen> {
  /// A unified list of all discovered stations from local storage and the cloud.
  List<UnifiedStation> _stations = [];
  
  /// The index of the currently selected station in the [_stations] list, if any.
  int? _selectedIndex;

  /// Indicates if a database-to-cloud synchronization process is actively running.
  bool _isSyncing = false;
  
  /// Indicates if a local AI inference process is actively running.
  bool _isInferring = false;
  
  /// Indicates if a cloud AI emulation process is actively running.
  bool _isEmulating = false;
  
  /// Indicates if a cloud connectivity test is actively running.
  bool _isTestingApi = false;

  /// The current state of connection to the cloud backend (e.g., 'CONNECTED', 'UNREACHABLE', 'UNKNOWN').
  String _cloudConnStatus = 'UNKNOWN';
  
  /// The number of local devices that contain telemetry not yet synced to the cloud.
  int _unsyncedCount = 0;

  /// The most recent result generated from an AI inference or cloud emulation.
  Map<String, dynamic>? _activeAiResult;
  
  /// Flag to prevent setting state or calling routines if the widget is removed from the tree.
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUnifiedData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testCloudConnection();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadUnifiedData() async {
    if (_isDisposed || !mounted) return;

    final localDevices = widget.routines.db.getSavedDevices();
    List<dynamic> cloudDevices = [];
    
    if (_cloudConnStatus == 'CONNECTED') {
      try {
        cloudDevices = await widget.routines.cloudApi.getRegisteredDevices();
      } catch (_) {}
    }

    final Map<String, UnifiedStation> mergedMap = {};

    for (var dev in localDevices) {
      mergedMap[dev.deviceIdentifier] = UnifiedStation(
        id: dev.deviceIdentifier,
        name: dev.name,
        localDevice: dev,
      );
    }

    for (var devMap in cloudDevices) {
      final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['deviceId'] ?? 'unknown').toString();
      final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString();
      
      if (mergedMap.containsKey(devId)) {
        mergedMap[devId] = UnifiedStation(
          id: devId,
          name: mergedMap[devId]!.name,
          localDevice: mergedMap[devId]!.localDevice,
          cloudDevice: devMap,
        );
      } else {
        mergedMap[devId] = UnifiedStation(
          id: devId,
          name: name,
          cloudDevice: devMap,
        );
      }
    }

    if (!_isDisposed && mounted) {
      setState(() {
        _stations = mergedMap.values.toList();
        _unsyncedCount = localDevices.where((d) => !d.isSynced).length;

        if (_selectedIndex == null && _stations.isNotEmpty) {
          _selectStation(0);
        } else if (_selectedIndex != null && _selectedIndex! >= _stations.length) {
          _selectedIndex = _stations.isNotEmpty ? 0 : null;
          _activeAiResult = null;
          if (_selectedIndex != null) _selectStation(_selectedIndex!);
        }
      });
    }
  }

  void _selectStation(int index) {
    if (index < 0 || index >= _stations.length) return;

    setState(() {
      _selectedIndex = index;
      _activeAiResult = null;
    });

    final station = _stations[index];
    if (station.hasLocal) {
      _handleLocalInference(station);
    } else if (station.hasCloud) {
      _handleCloudEmulation(station);
    }
  }

  Future<void> _testCloudConnection() async {
    if (_isTestingApi || _isDisposed || !mounted) return;
    setState(() {
      _isTestingApi = true;
      _cloudConnStatus = 'TESTING...';
    });

    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.cloudTestingConnection);
    
    try {
      final success = await widget.routines.cloudApi.testConnection();
      if (_isDisposed || !mounted) return;
      setState(() {
        _cloudConnStatus = success ? 'CONNECTED' : 'UNREACHABLE';
      });
      widget.onStatusChange(success ? l10n.cloudApiOnline : l10n.cloudApiNoResponse);
      if (success) {
        await _loadUnifiedData();
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() => _cloudConnStatus = 'ERROR');
      widget.onStatusChange(l10n.cloudApiTestFailed(e.toString()));
    } finally {
      if (!_isDisposed && mounted) setState(() => _isTestingApi = false);
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.dbSyncingCloud);

    try {
      final syncService = SyncService(db: widget.routines.db, api: widget.routines.cloudApi);
      await syncService.syncDirtyDevices();
      await syncService.discoverAndSyncCloudDevices();
      
      for (var dev in widget.routines.db.getSavedDevices()) {
        try {
          final latestTs = dev.historicValues.isNotEmpty ? (dev.historicValues.last.tsMs ?? 0) : 0;
          await syncService.pullTelemetry(dev.deviceIdentifier, latestTs);
        } catch (_) {}
      }
      
      await _testCloudConnection();
      widget.onStatusChange(l10n.dbSyncCompleted(_stations.length));
    } catch (e) {
      widget.onStatusChange(l10n.dbSyncError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleLocalInference(UnifiedStation station) async {
    if (_isInferring || !station.hasLocal) return;
    
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isInferring = true;
      _activeAiResult = null;
    });
    
    widget.onStatusChange(l10n.dbRunningInference(station.name, station.id));

    try {
      final res = await widget.routines.runLocalInference(
        station.id,
        forceAllow: true,
        persistResults: true,
      );
      final verdict = widget.routines.inferenceBridge.status;
      
      double? minHum = (res['minHumidity'] as num?)?.toDouble();
      int? minTs = res['minDateMs'] as int?;

      if (minHum == null || minTs == null) {
        final dev = widget.routines.db.getSavedDevices().firstWhere(
          (d) => d.deviceIdentifier == station.id,
          orElse: () => Device()..newPredictions = [],
        );
        for (var p in dev.newPredictions) {
          if (minHum == null || (p.value != null && p.value! < minHum)) {
            minHum = p.value;
            int? rawTs = p.tsMs;
            if (rawTs != null && rawTs < 100000000000) rawTs = rawTs * 1000;
            minTs = rawTs;
          }
        }
      }
      
      final settings = widget.routines.db.getAppSettings();
      final now = DateTime.now();
      final h = now.hour;
      final startH = settings.agronomicDayStart;
      final endH = settings.agronomicDayEnd;
      final bool isYellowZone = (endH < startH) ? (h >= endH && h < startH) : (h >= endH || h < startH);

      if (mounted) {
        setState(() {
          _activeAiResult = {
            'source': 'LOCAL',
            'verdict': res['verdict'] ?? verdict,
            'minHumidity': minHum,
            'minDateMs': minTs,
            'radSum': res['radSum'],
            'refDate': res['refDate'],
            'isUnrecommended': isYellowZone,
            'agronomicStart': startH,
            'agronomicEnd': endH,
          };
        });
      }
      widget.onStatusChange(l10n.dbInferenceFinished(_translateVerdict(verdict, l10n)));
    } catch (e) {
      widget.onStatusChange(l10n.dbInferenceFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isInferring = false);
    }
  }

  Future<void> _handleCloudEmulation(UnifiedStation station) async {
    if (_isEmulating || !station.hasCloud) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isEmulating = true;
      _activeAiResult = null;
    });
    
    widget.onStatusChange(l10n.cloudEmulationExecuting(station.name, station.id));

    try {
      final result = await widget.routines.emulateCloudRecommendationInMemory(station.id);
      
      final settings = widget.routines.db.getAppSettings();
      final now = DateTime.now();
      final h = now.hour;
      final startH = settings.agronomicDayStart;
      final endH = settings.agronomicDayEnd;
      final bool isYellowZone = (endH < startH) ? (h >= endH && h < startH) : (h >= endH || h < startH);

      if (mounted) {
        setState(() {
          _activeAiResult = {
            'source': 'CLOUD',
            'verdict': result['verdict'],
            'minHumidity': result['predictedHumidity'],
            'minDateMs': result['targetMinDateMs'],
            'radSum': result['shortwaveRadiationSum48h'],
            'refDate': result['referenceDate'],
            'isUnrecommended': isYellowZone,
            'agronomicStart': startH,
            'agronomicEnd': endH,
          };
        });
      }
      widget.onStatusChange(l10n.cloudEmulationFinished(result['verdict'].toString()));
    } catch (e) {
      widget.onStatusChange(l10n.cloudEmulationError(e.toString()));
    } finally {
      if (mounted) setState(() => _isEmulating = false);
    }
  }

  void _handleClearDb() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyles.surfaceColor,
        title: Text(l10n.dbClearTitle, style: AppStyles.sectionTitle),
        content: Text(l10n.dbClearDesc, style: AppStyles.bodyText),
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
              _loadUnifiedData();
              setState(() {
                _selectedIndex = null;
                _activeAiResult = null;
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
    if (v.contains('IRRIGATION AVOIDABLE:') || v.contains('Irrigation Avoidable')) {
      return l10n.verdictAvoidable;
    }
    if (v.contains('IRRIGATION NEEDED:') || v.contains('Irrigation Needed')) {
      return l10n.verdictNeeded;
    }
    if (v.startsWith('Verdict: ')) {
      return 'Verdict: ${_translateVerdict(v.substring(9), l10n)}';
    }
    return v;
  }

  void _openMapViewerDialog(UnifiedStation dev) {
    if (dev.latitude == null || dev.longitude == null) return;
    final point = LatLng(dev.latitude!, dev.longitude!);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyles.surfaceColor,
        title: Text('${dev.name} - Location', style: AppStyles.sectionTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: AppStyles.cardShell(),
                child: Text(
                  'Lat: ${dev.latitude!.toStringAsFixed(6)}, Lon: ${dev.longitude!.toStringAsFixed(6)}',
                  style: AppStyles.consoleBody.copyWith(color: AppStyles.successAccent),
                ),
              ),
              const SizedBox(height: AppStyles.spaceSM),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: point, initialZoom: 14.0),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'org.tfm.tfm_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            child: const Icon(Icons.location_on, color: AppStyles.errorAccent, size: 36),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: AppStyles.captionStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPanel(AppLocalizations l10n) {
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
                'Unified Status & Sync',
                style: AppStyles.sectionTitle.copyWith(color: AppStyles.successAccent),
              ),
              Wrap(
                spacing: AppStyles.spaceSM,
                runSpacing: AppStyles.spaceSM,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.network_ping),
                    label: Text(l10n.cloudBtnTestApi),
                    onPressed: _isTestingApi ? null : _testCloudConnection,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.dbBtnSyncCloud),
                    onPressed: _isSyncing || _isInferring || _isEmulating ? null : _handleSync,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(l10n.dbBtnClearDb),
                    style: AppStyles.destructiveButtonStyle,
                    onPressed: _isSyncing || _isInferring ? null : _handleClearDb,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.cloudConnectionStateLabel, style: AppStyles.consoleBody),
              const SizedBox(width: 4),
              Text(
                _cloudConnStatus,
                style: AppStyles.consoleBody.copyWith(
                  color: _cloudConnStatus == 'CONNECTED'
                      ? AppStyles.successAccent
                      : (_cloudConnStatus == 'UNREACHABLE' || _cloudConnStatus == 'ERROR'
                          ? AppStyles.errorAccent
                          : AppStyles.warningAccent),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text('|  Unsynced Locals: $_unsyncedCount', style: AppStyles.consoleBody),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedAiCard(AppLocalizations l10n) {
    return InferenceCard(
      data: _activeAiResult,
      l10n: l10n,
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
          const Text('Unified Stations Dashboard', style: AppStyles.displayHeader),
          const SizedBox(height: AppStyles.spaceMD),
          
          _buildTopPanel(l10n),
          
          const SizedBox(height: AppStyles.spaceMD),
          
          if (_isSyncing || _isInferring || _isEmulating || _isTestingApi)
            const Padding(
              padding: EdgeInsets.only(bottom: AppStyles.spaceSM),
              child: LinearProgressIndicator(color: AppStyles.successAccent),
            ),

          Expanded(
            child: _stations.isEmpty
                ? const Center(
                    child: Text(
                      'No stations found locally or in the cloud.\nConnect a hardware module or Sync with Cloud.',
                      textAlign: TextAlign.center,
                      style: AppStyles.captionStatus,
                    ),
                  )
                : ListView.builder(
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppStyles.spaceSM),
                        decoration: AppStyles.cardShell(isSelected: isSelected),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            if (_selectedIndex != index || _activeAiResult == null) {
                              _selectStation(index);
                            }
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
                                          Icons.hub,
                                          color: isSelected ? AppStyles.successAccent : AppStyles.textMuted,
                                        ),
                                        const SizedBox(width: AppStyles.spaceSM),
                                        Text(
                                          station.name,
                                          style: AppStyles.sectionTitle.copyWith(
                                            color: isSelected ? AppStyles.successAccent : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: AppStyles.spaceSM),
                                        Text('(${station.id})', style: AppStyles.captionStatus),
                                      ],
                                    ),
                                    Wrap(
                                      spacing: AppStyles.spaceXS,
                                      children: [
                                        if (station.hasLocal)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppStyles.techSecondaryAccent),
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            child: Text('LOCAL DB', style: AppStyles.captionStatus.copyWith(color: AppStyles.techSecondaryAccent)),
                                          ),
                                        if (station.hasCloud)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppStyles.successAccent),
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            child: Text('CLOUD', style: AppStyles.captionStatus.copyWith(color: AppStyles.successAccent)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppStyles.spaceSM),
                                Text(
                                  'Lat: ${station.latitude?.toStringAsFixed(4) ?? "N/A"}, '
                                  'Lon: ${station.longitude?.toStringAsFixed(4) ?? "N/A"}'
                                  '${station.hasLocal ? "  |  Telemetry: ${station.localDevice!.historicValues.length}" : ""}',
                                  style: AppStyles.consoleBody,
                                ),
                                
                                if (isSelected) ...[
                                  const SizedBox(height: AppStyles.spaceMD),
                                  Wrap(
                                    spacing: AppStyles.spaceSM,
                                    runSpacing: AppStyles.spaceSM,
                                    children: [
                                      if (station.hasLocal)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.memory),
                                          label: const Text('Run Local DB Inference'),
                                          onPressed: _isInferring || _isEmulating ? null : () => _handleLocalInference(station),
                                        ),
                                      if (station.hasCloud)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.cloud_sync),
                                          label: const Text('Run Cloud Emulation'),
                                          onPressed: _isInferring || _isEmulating ? null : () => _handleCloudEmulation(station),
                                        ),
                                      if (station.latitude != null && station.longitude != null)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.map),
                                          label: const Text('Locate on Map'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppStyles.techSecondaryAccent.withValues(alpha: 0.1),
                                            foregroundColor: AppStyles.techSecondaryAccent,
                                            side: const BorderSide(color: AppStyles.techSecondaryAccent),
                                          ),
                                          onPressed: () => _openMapViewerDialog(station),
                                        ),
                                    ],
                                  ),
                                  _buildUnifiedAiCard(l10n),
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