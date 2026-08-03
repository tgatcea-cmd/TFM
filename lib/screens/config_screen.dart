import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/features/location/location_controller.dart';

class ConfigScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;
  final void Function(String msg) onStatusChange;

  const ConfigScreen({
    super.key,
    required this.routines,
    required this.onBack,
    required this.onStatusChange,
  });

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late String _cloudScheme;
  late String _cloudUrl;
  late int _cloudPort;
  
  late int _agronomicDayStart; // Prediction start
  late int _agronomicDayEnd;   // Prediction end / Irrigation start - 1
  late int _baseDayStart;
  late int _baseDayEnd;

  String _openMeteoStatus = 'Checking...';
  String _cloudPingStatus = 'Checking...';
  String _scheduleWarning = '';

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final settings = widget.routines.db.getAppSettings(); //[cite: 8]
    _cloudScheme = settings.tfmServerScheme; //[cite: 8]
    _cloudUrl = settings.tfmServerUrl; //[cite: 8]
    _cloudPort = settings.tfmServerPort; //[cite: 8]
    _agronomicDayStart = settings.agronomicDayStart; //[cite: 8]
    _agronomicDayEnd = settings.agronomicDayEnd; //[cite: 8]
    _baseDayStart = settings.agronomicDayStart; //[cite: 8]
    _baseDayEnd = settings.agronomicDayEnd; //[cite: 8]

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _checkOpenMeteo(); //[cite: 8]
    _checkCloudPing(); //[cite: 8]
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleAutoGpsLocation() async {
    widget.onStatusChange('Acquiring GPS location...');
    try {
      final locService = LocationService();
      final pos = await locService.getCurrentPosition();
      if (pos != null) {
        widget.routines.db.saveLocationSettings(pos.latitude, pos.longitude, true);
        setState(() {});
        widget.onStatusChange(
          'Location updated automatically via GPS: Lat ${pos.latitude.toStringAsFixed(4)}, Lon ${pos.longitude.toStringAsFixed(4)}',
        );
      } else {
        widget.onStatusChange('Failed to get GPS location. Check location permissions/services.');
      }
    } catch (e) {
      widget.onStatusChange('GPS Location Error: $e');
    }
  }

  Future<void> _openMapPickerDialog() async {
    final locSettings = widget.routines.db.getLocationSettings();
    LatLng selectedPoint = LatLng(
      (locSettings.latitude != 0.0) ? locSettings.latitude : 40.4168,
      (locSettings.longitude != 0.0) ? locSettings.longitude : -3.7038,
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setMapState) {
            return AlertDialog(
              backgroundColor: AppStyles.surfaceColor,
              title: const Text('Select Location on Map', style: AppStyles.sectionTitle),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spaceSM),
                      color: Colors.black38,
                      child: Text(
                        'Tap anywhere on the map to place point:\nLat: ${selectedPoint.latitude.toStringAsFixed(4)}, Lon: ${selectedPoint.longitude.toStringAsFixed(4)}',
                        style: AppStyles.consoleBody.copyWith(color: AppStyles.successAccent),
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceSM),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: selectedPoint,
                            initialZoom: 13.0,
                            onTap: (tapPosition, point) {
                              setMapState(() {
                                selectedPoint = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'org.tfm.tfm_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedPoint,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppStyles.errorAccent,
                                    size: 36,
                                  ),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: AppStyles.captionStatus),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Location'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.routines.db.saveLocationSettings(
                      selectedPoint.latitude,
                      selectedPoint.longitude,
                      false,
                    );
                    setState(() {});
                    widget.onStatusChange(
                      'Location manually set: Lat ${selectedPoint.latitude.toStringAsFixed(4)}, Lon ${selectedPoint.longitude.toStringAsFixed(4)}',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLocationSettingsChoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppStyles.spaceMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configure Location Mode', style: AppStyles.sectionTitle),
              const SizedBox(height: AppStyles.spaceMD),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppStyles.successAccent),
                title: const Text('Automatic (GPS)', style: AppStyles.bodyText),
                subtitle: const Text('Acquire current position using device GPS hardware', style: AppStyles.captionStatus),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAutoGpsLocation();
                },
              ),
              const Divider(color: AppStyles.dividerColor),
              ListTile(
                leading: const Icon(Icons.map, color: AppStyles.waterActionAccent),
                title: const Text('Manual (Interactive Map)', style: AppStyles.bodyText),
                subtitle: const Text('Tap on an interactive map to pick exact field coordinates', style: AppStyles.captionStatus),
                onTap: () {
                  Navigator.pop(ctx);
                  _openMapPickerDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Business Logic for Agronomic Schedule ---
  // Adjusts prediction start boundary, limiting to ±3h from base and preventing overlap[cite: 8]
  void _adjustDayStart(int delta) {
    final newVal = (_agronomicDayStart + delta) % 24;
    final diff = ((newVal - _baseDayStart + 36) % 24) - 12; //[cite: 8]
    
    if (diff.abs() <= 3) { //[cite: 8]
      setState(() {
        _agronomicDayStart = newVal;
        // Ensure prediction & irrigation both maintain at least 1h window[cite: 8]
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayEnd = (_agronomicDayStart - 2 + 24) % 24; //[cite: 8]
        }
        _scheduleWarning = '';
      });
      widget.onStatusChange('Prediction start updated to $_agronomicDayStart:00.');
    } else {
      setState(() {
        _scheduleWarning = 'Limit reached: Prediction start can only be adjusted ±3h from base ($_baseDayStart:00).'; //[cite: 8]
      });
    }
  }

  // Adjusts irrigation boundary, limiting to ±3h from base and preventing overlap[cite: 8]
  void _adjustDayEnd(int delta) {
    final newVal = (_agronomicDayEnd + delta) % 24;
    final diff = ((newVal - _baseDayEnd + 36) % 24) - 12; //[cite: 8]
    
    if (diff.abs() <= 3) { //[cite: 8]
      setState(() {
        _agronomicDayEnd = newVal;
        // Ensure prediction & irrigation both maintain at least 1h window[cite: 8]
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayStart = (_agronomicDayEnd + 2) % 24; //[cite: 8]
        }
        _scheduleWarning = '';
      });
      widget.onStatusChange('Irrigation end updated to $_agronomicDayEnd:00.');
    } else {
      setState(() {
        _scheduleWarning = 'Limit reached: Irrigation end can only be adjusted ±3h from base ($_baseDayEnd:00).'; //[cite: 8]
      });
    }
  }

  // --- Network Checks ---
  Future<void> _checkOpenMeteo() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&current_weather=true'), //[cite: 8]
      ).timeout(const Duration(seconds: 4));
      
      if (mounted) {
        setState(() {
          _openMeteoStatus = (res.statusCode == 200) ? 'OK (200)' : 'Error (${res.statusCode})'; //[cite: 8]
        });
      }
    } catch (_) {
      if (mounted) setState(() => _openMeteoStatus = 'Offline / Failed'); //[cite: 8]
    }
  }

  Future<void> _checkCloudPing() async {
    setState(() => _cloudPingStatus = 'Testing...');
    final sw = Stopwatch()..start();

    for (final path in ['/health', '/api/ping']) { //[cite: 8]
      try {
        final res = await http.get(Uri.parse('$_cloudScheme://$_cloudUrl:$_cloudPort$path')).timeout(const Duration(seconds: 3)); //[cite: 8]
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) setState(() => _cloudPingStatus = '${data['status']?.toString().toUpperCase() ?? 'OK'} (${sw.elapsedMilliseconds} ms)'); //[cite: 8]
          return;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _cloudPingStatus = 'Unreachable / Failed'); //[cite: 8]
  }

  // --- Core Persistence ---
  void _saveConfiguration() {
    widget.routines.db.saveAppSettings(
      tfmServerScheme: _cloudScheme,
      tfmServerUrl: _cloudUrl,
      tfmServerPort: _cloudPort,
      agronomicDayStart: _agronomicDayStart,
      agronomicDayEnd: _agronomicDayEnd,
    ); //[cite: 8]
    widget.routines.cloudApi.updateEndpoint(_cloudScheme, _cloudUrl, _cloudPort); //[cite: 8]
    widget.onStatusChange('Configuration applied and saved to database & live ApiClient!'); //[cite: 8]
  }

  void _parseAndSetCloudEndpoint(String rawInput) {
    if (rawInput.trim().isEmpty) return;
    String input = rawInput.trim();
    if (!input.contains('://')) {
      input = '$_cloudScheme://$input'; //[cite: 8]
    }
    try {
      final uri = Uri.parse(input);
      if (uri.scheme.isNotEmpty) _cloudScheme = uri.scheme; //[cite: 8]
      if (uri.host.isNotEmpty) _cloudUrl = uri.host; //[cite: 8]
      if (uri.hasPort) _cloudPort = uri.port; //[cite: 8]
    } catch (_) {}
  }

  // --- GUI Dialog for Endpoint ---
  Future<void> _editCloudEndpointDialog() async {
    final String currentEndpoint = '$_cloudScheme://$_cloudUrl:$_cloudPort';
    String enteredValue = currentEndpoint;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cloud Endpoint'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'e.g. http://192.168.1.50:3000',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: currentEndpoint),
          onChanged: (val) => enteredValue = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, enteredValue),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result != currentEndpoint) {
      setState(() {
        _parseAndSetCloudEndpoint(result);
      });
      widget.onStatusChange('Cloud endpoint updated. Remember to press Apply & Save.');
      unawaited(_checkCloudPing());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year.toString().substring(2)} '
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    final locSettings = widget.routines.db.getLocationSettings();
    final locStr = 'Lat: ${locSettings.latitude.toStringAsFixed(4)}, Lon: ${locSettings.longitude.toStringAsFixed(4)} (${locSettings.isGps ? 'GPS' : 'Manual'})';

    final irrStart = (_agronomicDayEnd + 1) % 24;
    final irrEnd = (_agronomicDayStart - 1 + 24) % 24;
    final predStart = _agronomicDayStart;
    final predEnd = _agronomicDayEnd;

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Configuration',
                style: AppStyles.displayHeader,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Apply & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.successAccent.withValues(alpha: 0.2),
                  foregroundColor: AppStyles.successAccent,
                  side: const BorderSide(color: AppStyles.successAccent),
                ),
                onPressed: _saveConfiguration,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          Expanded(
            child: ListView(
              children: [
                // 1. System & Environment Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: AppStyles.cardShell(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ENVIRONMENT', style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      ListTile(
                        leading: const Icon(Icons.access_time, color: AppStyles.textSecondary),
                        title: const Text('System Date & Time', style: AppStyles.bodyText),
                        subtitle: Text('$dateStr  (${_now.millisecondsSinceEpoch})', style: AppStyles.consoleBody),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on, color: AppStyles.textSecondary),
                        title: const Text('Location Settings', style: AppStyles.bodyText),
                        subtitle: Text(locStr, style: AppStyles.consoleBody),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_location_alt, color: AppStyles.techSecondaryAccent),
                          onPressed: _showLocationSettingsChoice,
                          tooltip: 'Configure Location Mode',
                        ),
                        onTap: _showLocationSettingsChoice,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spaceSM),

                // 2. API & Cloud Services Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: AppStyles.cardShell(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NETWORK SERVICES', style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny, color: AppStyles.textSecondary),
                        title: const Text('Open-Meteo API Status', style: AppStyles.bodyText),
                        trailing: Text(
                          _openMeteoStatus, 
                          style: AppStyles.consoleBody.copyWith(
                            color: _openMeteoStatus.contains('OK') ? AppStyles.successAccent : AppStyles.errorAccent, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cloud, color: AppStyles.textSecondary),
                        title: const Text('Cloud Server Endpoint', style: AppStyles.bodyText),
                        subtitle: Text('$_cloudScheme://$_cloudUrl:$_cloudPort\nPing: $_cloudPingStatus', style: AppStyles.consoleBody),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppStyles.waterActionAccent),
                          onPressed: _editCloudEndpointDialog,
                          tooltip: 'Edit Endpoint',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spaceSM),

                // 3. Agronomic Schedule Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: AppStyles.cardShell(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AGRONOMIC SCHEDULE (24H)', style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      
                      // Irrigation Period Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: AppStyles.spaceSM, horizontal: AppStyles.spaceMD),
                        decoration: BoxDecoration(
                          color: AppStyles.techSecondaryAccent.withValues(alpha: 0.1),
                          border: Border.all(color: AppStyles.techSecondaryAccent.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Irrigation Period', style: AppStyles.bodyText.copyWith(color: AppStyles.techSecondaryAccent, fontWeight: FontWeight.bold)),
                                Text('${irrStart.toString().padLeft(2, '0')}hrs to ${irrEnd.toString().padLeft(2, '0')}hrs', style: AppStyles.consoleBody),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _adjustDayEnd(-1), color: AppStyles.techSecondaryAccent),
                                Text('Shift', style: AppStyles.captionStatus.copyWith(color: AppStyles.techSecondaryAccent)),
                                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _adjustDayEnd(1), color: AppStyles.techSecondaryAccent),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyles.spaceSM),

                      // Prediction Period Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: AppStyles.spaceSM, horizontal: AppStyles.spaceMD),
                        decoration: BoxDecoration(
                          color: AppStyles.warningAccent.withValues(alpha: 0.1),
                          border: Border.all(color: AppStyles.warningAccent.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prediction Period', style: AppStyles.bodyText.copyWith(color: AppStyles.warningAccent, fontWeight: FontWeight.bold)),
                                Text('${predStart.toString().padLeft(2, '0')}hrs to ${predEnd.toString().padLeft(2, '0')}hrs', style: AppStyles.consoleBody),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _adjustDayStart(-1), color: AppStyles.warningAccent),
                                Text('Shift', style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent)),
                                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _adjustDayStart(1), color: AppStyles.warningAccent),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      if (_scheduleWarning.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppStyles.spaceSM),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppStyles.warningAccent, size: 16),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: Text(
                                  _scheduleWarning,
                                  style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}