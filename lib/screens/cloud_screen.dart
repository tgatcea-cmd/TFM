import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/database/db_sync.dart';
import 'package:tfm_app/core/theme/app_styles.dart';

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
  
  // Replaced the string with a Map to feed our visual card
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
    widget.onStatusChange('Testing connection to Cloud Server...');

    try {
      final success = await widget.routines.cloudApi.testConnection();
      if (_isDisposed || !mounted) return;
      setState(() {
        _connStatus = success ? 'CONNECTED' : 'UNREACHABLE';
      });
      widget.onStatusChange(success
          ? 'Cloud API server is online and responding.'
          : 'Cloud API server returned no response or error.');
      if (success) {
        await _loadCloudDevices();
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() => _connStatus = 'ERROR');
      widget.onStatusChange('Cloud API test failed: $e');
    } finally {
      if (!_isDisposed && mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    widget.onStatusChange('Initiating Cloud Synchronization...');

    try {
      final syncService = SyncService(
        db: widget.routines.db,
        api: widget.routines.cloudApi,
      );
      await syncService.syncDirtyDevices(); //[cite: 3]
      await syncService.discoverAndSyncCloudDevices(); //[cite: 3]
      _checkStatus();
      await _loadCloudDevices(); //[cite: 3]
      widget.onStatusChange('Cloud sync finished.');
    } catch (e) {
      widget.onStatusChange('Cloud sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleCloudEmulation() async {
    if (_isEmulating) return;
    if (_cloudDevices.isEmpty) {
      await _loadCloudDevices(); //[cite: 3]
    }

    if (_cloudDevices.isEmpty) {
      widget.onStatusChange('Emulation Aborted: No registered station found on Cloud server.'); //[cite: 3]
      return;
    }

    if (_selectedIndex == null || _selectedIndex! >= _cloudDevices.length) {
      widget.onStatusChange('No station selected! Please select a cloud station first.');
      return;
    }

    final devMap = _cloudDevices[_selectedIndex!];
    final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? devMap['deviceId'] ?? 'pico_01').toString(); //[cite: 3]
    final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString(); //[cite: 3]

    setState(() {
      _isEmulating = true;
      _emulationResultMap = null;
    });
    widget.onStatusChange('Executing Local RF Recommendation in RAM for [$name] ($devId)...');

    try {
      final result = await widget.routines.emulateCloudRecommendationInMemory(devId); //[cite: 3]
      
      if (mounted) {
        setState(() {
          _emulationResultMap = result;
        });
      }
      widget.onStatusChange('In-Memory Cloud Emulation Finished: ${result['verdict']}'); //[cite: 3]
    } catch (e) {
      widget.onStatusChange('In-Memory Cloud Emulation Error: $e'); //[cite: 3]
    } finally {
      if (mounted) setState(() => _isEmulating = false);
    }
  }

  Widget _buildApiStatusCard() {
    final settings = widget.routines.db.getAppSettings();
    final serverUrl = widget.routines.cloudApi.baseUrl;
    final hasApiKey = settings.tfmServerApiKey.isNotEmpty;

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
                'API CONNECTION STATUS',
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
                    label: const Text('Test API'),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text('Sync ($_unsyncedDevicesCount dirty)'),
                    onPressed: _isSyncing ? null : _handleSync,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            'Target Endpoint : $serverUrl',
            style: AppStyles.consoleBody,
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            'API Authorization: ${hasApiKey ? "Configured [OK]" : "Missing/Empty"}',
            style: AppStyles.consoleBody.copyWith(
              color: hasApiKey ? AppStyles.successAccent : AppStyles.warningAccent,
            ),
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Row(
            children: [
              const Text('Connection State : ', style: AppStyles.consoleBody),
              Text(
                _connStatus,
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

  Widget _buildEmulationCard() {
    if (_emulationResultMap == null) return const SizedBox.shrink();

    final verdict = _emulationResultMap!['verdict'] as String? ?? 'UNKNOWN';
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

    String targetDateFormatted = 'N/A';
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
                  isYellowZone ? 'IN-MEMORY CLOUD EMULATION (YELLOW ZONE)' : 'IN-MEMORY CLOUD EMULATION',
                  style: AppStyles.sectionTitle.copyWith(color: color, fontSize: 15),
                ),
              ),
            ],
          ),
          if (isYellowZone) ...[
            const SizedBox(height: AppStyles.spaceXS),
            Text(
              '[DATA GATHERING PHASE] System in Yellow Zone ($endH:00 - $startH:00). Emulated RAM prediction is for observation only.',
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
                        'Minimum predicted humidity: ${(predHum * 100).toStringAsFixed(1)}%\nExpected at: $targetDateFormatted',
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
                        '48h Radiation Sum: ${radSum.toStringAsFixed(1)} J/m²',
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
                          'Reference Timestamp: ${_formatDateString(refDate)}',
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

  String _formatCoord(dynamic val) {
    if (val == null) return 'N/A';
    if (val is num) return val.toDouble().toStringAsFixed(4);
    if (val is String) {
      final d = double.tryParse(val);
      if (d != null) return d.toStringAsFixed(4);
      return val;
    }
    return val.toString();
  }

  String _resolveCoords(String devId, dynamic rawLat, dynamic rawLon) {
    final serverLat = _formatCoord(rawLat);
    final serverLon = _formatCoord(rawLon);
    if (serverLat != 'N/A' && serverLon != 'N/A') {
      return 'Lat $serverLat, Lon $serverLon';
    }

    final devices = widget.routines.db.getSavedDevices();
    for (var dev in devices) {
      if (dev.deviceIdentifier == devId && dev.latitude != null && dev.longitude != null) {
        return 'Lat ${dev.latitude!.toStringAsFixed(4)}, Lon ${dev.longitude!.toStringAsFixed(4)}';
      }
    }

    final appLoc = widget.routines.db.getLocationSettings();
    if (appLoc.latitude != 0.0 || appLoc.longitude != 0.0) {
      return 'Lat ${appLoc.latitude.toStringAsFixed(4)}, Lon ${appLoc.longitude.toStringAsFixed(4)}';
    }

    return 'Lat N/A, Lon N/A';
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
    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloud Services & Emulation',
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

          const Text(
            'Registered Cloud Stations:',
            style: AppStyles.sectionTitle,
          ),
          const SizedBox(height: AppStyles.spaceSM),

          Expanded(
            child: _cloudDevices.isEmpty
                ? const Center(
                    child: Text(
                      'No registered stations found on Cloud Server.\nTest the connection or run a Sync.',
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
                      final coordsStr = _resolveCoords(devId, rawLat, rawLon);

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
                            widget.onStatusChange('Selected Cloud Station: $name');
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
                                  'Coordinates: $coordsStr',
                                  style: AppStyles.consoleBody,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: AppStyles.spaceMD),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.memory),
                                    label: const Text('Emulate Cloud Station'),
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