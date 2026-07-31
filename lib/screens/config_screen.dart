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

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _loadCloudDevices();
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
    if (_isLoadingDevices) return;
    setState(() => _isLoadingDevices = true);
    
    try {
      final devices = await widget.routines.cloudApi.getRegisteredDevices(); //[cite: 3]
      if (mounted) {
        setState(() {
          _cloudDevices = devices;
          if (_selectedIndex != null && _selectedIndex! >= _cloudDevices.length) {
            _selectedIndex = _cloudDevices.isNotEmpty ? 0 : null;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _testConnection() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    widget.onStatusChange('Testing connection to Cloud Server...');

    try {
      final success = await widget.routines.cloudApi.testConnection(); //[cite: 3]
      if (mounted) {
        setState(() {
          _connStatus = success ? 'CONNECTED' : 'UNREACHABLE';
        });
      }
      widget.onStatusChange(success
          ? 'Cloud API server is online and responding.'
          : 'Cloud API server returned no response or error.'); //[cite: 3]
      await _loadCloudDevices();
    } catch (e) {
      if (mounted) setState(() => _connStatus = 'ERROR');
      widget.onStatusChange('Cloud API test failed: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
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
    final settings = widget.routines.db.getAppSettings(); //[cite: 3]
    final serverUrl = widget.routines.cloudApi.baseUrl; //[cite: 3]
    final hasApiKey = settings.tfmServerApiKey.isNotEmpty; //[cite: 3]

    final statusColor = _connStatus == 'CONNECTED'
        ? Colors.greenAccent
        : (_connStatus == 'UNREACHABLE' || _connStatus == 'ERROR'
            ? Colors.redAccent
            : Colors.yellowAccent); //[cite: 3]

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'API CONNECTION STATUS',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppStyles.consoleFontFamily,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.network_ping),
                    label: const Text('Test API'),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text('Sync ($_unsyncedDevicesCount dirty)'),
                    onPressed: _isSyncing ? null : _handleSync,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Target Endpoint : $serverUrl',
            style: const TextStyle(color: Colors.white, fontFamily: AppStyles.consoleFontFamily, fontSize: 13), //[cite: 3]
          ),
          const SizedBox(height: 4),
          Text(
            'API Authorization: ${hasApiKey ? "Configured [OK]" : "Missing/Empty"}',
            style: TextStyle(
              color: hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
              fontFamily: AppStyles.consoleFontFamily, //[cite: 3]
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Connection State : ', style: TextStyle(color: Colors.white, fontFamily: AppStyles.consoleFontFamily, fontSize: 13)), //[cite: 3]
              Text(
                _connStatus, //[cite: 3]
                style: TextStyle(
                  color: statusColor,
                  fontFamily: AppStyles.consoleFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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

    final bool isIrrigate = verdict.toUpperCase().contains('IRRIGATE') && !verdict.toUpperCase().contains('DO NOT');
    final color = isIrrigate ? Colors.blueAccent : Colors.cyanAccent;
    final icon = isIrrigate ? Icons.water_drop : Icons.cloud_done;

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
                'IN-MEMORY CLOUD EMULATION',
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
          if (predHum != null && radSum != null && refDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Predicted Base Humidity: ${(predHum * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70, fontFamily: AppStyles.consoleFontFamily, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '48h Radiation Sum: ${radSum.toStringAsFixed(1)} J/m²',
                      style: const TextStyle(color: Colors.white70, fontFamily: AppStyles.consoleFontFamily, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Reference Timestamp: ${_formatDateString(refDate)}',
                      style: const TextStyle(color: Colors.white70, fontFamily: AppStyles.consoleFontFamily, fontSize: 13),
                    ),
                  ],
                )
              ],
            )
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
          Text(
            'Cloud Services & Emulation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          _buildApiStatusCard(),

          const SizedBox(height: 16),
          
          if (_isTesting || _isSyncing || _isEmulating || _isLoadingDevices) //[cite: 3]
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: LinearProgressIndicator(),
            ),

          const Text(
            'Registered Cloud Stations:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _cloudDevices.isEmpty
                ? Center(
                    child: Text(
                      'No registered stations found on Cloud Server.\nTest the connection or run a Sync.', //[cite: 3]
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cloudDevices.length, //[cite: 3]
                    itemBuilder: (context, index) {
                      final devMap = _cloudDevices[index]; //[cite: 3]
                      final isSelected = _selectedIndex == index; //[cite: 3]
                      final devId = (devMap['deviceIdentifier'] ?? devMap['id'] ?? devMap['device_id'] ?? 'pico_$index').toString(); //[cite: 3]
                      final name = (devMap['name'] ?? devMap['deviceName'] ?? devId).toString(); //[cite: 3]
                      final lat = devMap['lat'] ?? devMap['latitude'] ?? 'N/A'; //[cite: 3]
                      final lon = devMap['lon'] ?? devMap['longitude'] ?? 'N/A'; //[cite: 3]

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected ? Colors.greenAccent : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index; //[cite: 3]
                              _emulationResultMap = null;
                            });
                            widget.onStatusChange('Selected Cloud Station: $name'); //[cite: 3]
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud,
                                      color: isSelected ? Colors.greenAccent : Colors.white54,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      name, //[cite: 3]
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.greenAccent : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '($devId)', //[cite: 3]
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontFamily: AppStyles.consoleFontFamily,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Coordinates: Lat $lat, Lon $lon', //[cite: 3]
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: AppStyles.consoleFontFamily,
                                    fontSize: 12,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 12),
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