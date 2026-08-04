import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tfm_app/core/models/app_rf_model.dart';
import 'package:tfm_app/l10n/app_localizations.dart';

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

  String? _openMeteoStatus;
  String? _cloudPingStatus;
  String? _scheduleWarning;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final settings = widget.routines.db.getAppSettings();
    _cloudScheme = settings.tfmServerScheme;
    _cloudUrl = settings.tfmServerUrl;
    _cloudPort = settings.tfmServerPort;
    _agronomicDayStart = settings.agronomicDayStart;
    _agronomicDayEnd = settings.agronomicDayEnd;
    _baseDayStart = settings.agronomicDayStart;
    _baseDayEnd = settings.agronomicDayEnd;

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    
    // We defer calling the checks slightly so `context` is fully ready for l10n
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkOpenMeteo();
       _checkCloudPing();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _showMlModelManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => MlModelManagerSheet(routines: widget.routines),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleAutoGpsLocation() async {
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.cfgAcquiringGps);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location services disabled');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw Exception('Location permission denied');
      
      final pos = await Geolocator.getCurrentPosition();
      widget.routines.db.saveLocationSettings(pos.latitude, pos.longitude, true);
      setState(() {});
      widget.onStatusChange(
        l10n.cfgGpsUpdated(pos.latitude.toStringAsFixed(4), pos.longitude.toStringAsFixed(4))
      );
    } catch (e) {
      widget.onStatusChange(l10n.cfgGpsError(e.toString()));
    }
  }

  Future<void> _openMapPickerDialog() async {
    final l10n = AppLocalizations.of(context)!;
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
              title: Text(l10n.cfgMapTitle, style: AppStyles.sectionTitle),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spaceSM),
                      color: AppStyles.consoleBackground.withValues(alpha: 0.5),
                      child: Text(
                        l10n.cfgMapHint(selectedPoint.latitude.toStringAsFixed(4), selectedPoint.longitude.toStringAsFixed(4)),
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
                  child: Text(l10n.cancel, style: AppStyles.captionStatus),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l10n.cfgBtnConfirmLoc),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.routines.db.saveLocationSettings(
                      selectedPoint.latitude,
                      selectedPoint.longitude,
                      false,
                    );
                    setState(() {});
                    widget.onStatusChange(
                      l10n.cfgMapUpdated(selectedPoint.latitude.toStringAsFixed(4), selectedPoint.longitude.toStringAsFixed(4))
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.cfgLocModeTitle, style: AppStyles.sectionTitle),
              const SizedBox(height: AppStyles.spaceMD),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppStyles.successAccent),
                title: Text(l10n.cfgLocModeAuto, style: AppStyles.bodyText),
                subtitle: Text(l10n.cfgLocModeAutoDesc, style: AppStyles.captionStatus),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAutoGpsLocation();
                },
              ),
              const Divider(color: AppStyles.dividerColor),
              ListTile(
                leading: const Icon(Icons.map, color: AppStyles.waterActionAccent),
                title: Text(l10n.cfgLocModeManual, style: AppStyles.bodyText),
                subtitle: Text(l10n.cfgLocModeManualDesc, style: AppStyles.captionStatus),
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
  void _adjustDayStart(int delta) {
    final l10n = AppLocalizations.of(context)!;
    final newVal = (_agronomicDayStart + delta) % 24;
    final diff = ((newVal - _baseDayStart + 36) % 24) - 12;
    
    if (diff.abs() <= 3) {
      setState(() {
        _agronomicDayStart = newVal;
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayEnd = (_agronomicDayStart - 2 + 24) % 24;
        }
        _scheduleWarning = null;
      });
      widget.onStatusChange(l10n.cfgPredStartUpdated(_agronomicDayStart));
    } else {
      setState(() {
        _scheduleWarning = l10n.cfgPredLimit(_baseDayStart);
      });
    }
  }

  void _adjustDayEnd(int delta) {
    final l10n = AppLocalizations.of(context)!;
    final newVal = (_agronomicDayEnd + delta) % 24;
    final diff = ((newVal - _baseDayEnd + 36) % 24) - 12;
    
    if (diff.abs() <= 3) {
      setState(() {
        _agronomicDayEnd = newVal;
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayStart = (_agronomicDayEnd + 2) % 24;
        }
        _scheduleWarning = null;
      });
      widget.onStatusChange(l10n.cfgIrrEndUpdated(_agronomicDayEnd));
    } else {
      setState(() {
        _scheduleWarning = l10n.cfgIrrLimit(_baseDayEnd);
      });
    }
  }

  // --- Network Checks ---
  Future<void> _checkOpenMeteo() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _openMeteoStatus = l10n.cfgChecking);
    try {
      final res = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&current_weather=true'),
      ).timeout(const Duration(seconds: 4));
      
      if (mounted) {
        setState(() {
          _openMeteoStatus = (res.statusCode == 200) ? l10n.cfgMeteoOk : l10n.cfgMeteoError(res.statusCode);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _openMeteoStatus = l10n.cfgMeteoOffline);
    }
  }

  Future<void> _checkCloudPing() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _cloudPingStatus = l10n.cfgPingTesting);
    final sw = Stopwatch()..start();

    for (final path in ['/health', '/api/ping']) {
      try {
        final res = await http.get(Uri.parse('$_cloudScheme://$_cloudUrl:$_cloudPort$path')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) setState(() => _cloudPingStatus = l10n.cfgPingRes(data['status']?.toString().toUpperCase() ?? 'OK', sw.elapsedMilliseconds));
          return;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _cloudPingStatus = l10n.cfgPingFailed);
  }

  // --- Core Persistence ---
  void _saveConfiguration() {
    final l10n = AppLocalizations.of(context)!;
    widget.routines.db.saveAppSettings(
      tfmServerScheme: _cloudScheme,
      tfmServerUrl: _cloudUrl,
      tfmServerPort: _cloudPort,
      agronomicDayStart: _agronomicDayStart,
      agronomicDayEnd: _agronomicDayEnd,
    );
    widget.routines.cloudApi.updateEndpoint(_cloudScheme, _cloudUrl, _cloudPort);
    widget.onStatusChange(l10n.cfgSavedStatus);
  }

  void _parseAndSetCloudEndpoint(String rawInput) {
    if (rawInput.trim().isEmpty) return;
    String input = rawInput.trim();
    if (!input.contains('://')) {
      input = '$_cloudScheme://$input';
    }
    try {
      final uri = Uri.parse(input);
      if (uri.scheme.isNotEmpty) _cloudScheme = uri.scheme;
      if (uri.host.isNotEmpty) _cloudUrl = uri.host;
      if (uri.hasPort) _cloudPort = uri.port;
    } catch (_) {}
  }

  // --- GUI Dialog for Endpoint ---
  Future<void> _editCloudEndpointDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final String currentEndpoint = '$_cloudScheme://$_cloudUrl:$_cloudPort';
    String enteredValue = currentEndpoint;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cfgEndpointTitle),
        content: TextField(
          decoration: InputDecoration(
            labelText: l10n.cfgEndpointLabel,
            hintText: l10n.cfgEndpointHint('http://192.168.1.50:3000'),
            border: const OutlineInputBorder(),
          ),
          controller: TextEditingController(text: currentEndpoint),
          onChanged: (val) => enteredValue = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: AppStyles.bodyText.copyWith(color: AppStyles.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, enteredValue),
            child: Text(l10n.cfgBtnUpdate),
          ),
        ],
      ),
    );

    if (result != null && result != currentEndpoint) {
      setState(() {
        _parseAndSetCloudEndpoint(result);
      });
      widget.onStatusChange(l10n.cfgEndpointUpdated);
      unawaited(_checkCloudPing());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year.toString().substring(2)} '
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    final locSettings = widget.routines.db.getLocationSettings();
    final locStr = l10n.cfgLocString(locSettings.latitude.toStringAsFixed(4), locSettings.longitude.toStringAsFixed(4), locSettings.isGps ? 'GPS' : 'Manual');
    final activeModel = widget.routines.db.getActiveRfModel();
    final savedModels = widget.routines.db.getSavedRfModels();

    final irrStart = (_agronomicDayEnd + 1) % 24;
    final irrEnd = (_agronomicDayStart - 1 + 24) % 24;
    final predStart = _agronomicDayStart;
    final predEnd = _agronomicDayEnd;
    
    final resolvedMeteoStatus = _openMeteoStatus ?? l10n.cfgChecking;
    final resolvedPingStatus = _cloudPingStatus ?? l10n.cfgPingTesting;

    // Resolve Ping Visual Color Feedback
    Color pingColor = AppStyles.textSecondary;
    if (resolvedPingStatus.contains('Failed') || resolvedPingStatus.contains('Error') || resolvedPingStatus.contains('Fall')) {
      pingColor = AppStyles.errorAccent;
    } else if (resolvedPingStatus.contains('OK')) {
      pingColor = AppStyles.successAccent;
    }

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
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
                l10n.cfgScreenTitle,
                style: AppStyles.displayHeader,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.cfgBtnApplySave),
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
                      Text(l10n.cfgEnvSection, style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      
                      // Time Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.access_time, color: AppStyles.textSecondary, size: 24),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.cfgSysTimeLabel, style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text('$dateStr  (${_now.millisecondsSinceEpoch})', style: AppStyles.consoleBody),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppStyles.spaceSM),
                        child: Divider(color: AppStyles.dividerColor, height: 1),
                      ),
                      
                      // Location Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.location_on, color: AppStyles.textSecondary, size: 24),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.cfgLocSettingsLabel, style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(locStr, style: AppStyles.consoleBody),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_location_alt, size: 16),
                            label: Text(l10n.cfgBtnUpdate),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppStyles.techSecondaryAccent,
                              side: const BorderSide(color: AppStyles.techSecondaryAccent),
                              minimumSize: const Size(130, 36),
                            ),
                            onPressed: _showLocationSettingsChoice,
                          ),
                        ],
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
                      Text(l10n.cfgNetSection, style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      
                      // Open Meteo Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.wb_sunny, color: AppStyles.textSecondary, size: 24),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.cfgMeteoLabel, style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  resolvedMeteoStatus, 
                                  style: AppStyles.consoleBody.copyWith(
                                    color: resolvedMeteoStatus.contains('OK') ? AppStyles.successAccent : AppStyles.errorAccent, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.network_ping, size: 16),
                            label: Text(l10n.cloudBtnTestApi),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppStyles.textSecondary,
                              side: const BorderSide(color: AppStyles.dividerColor),
                              minimumSize: const Size(130, 36),
                            ),
                            onPressed: _checkOpenMeteo,
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppStyles.spaceSM),
                        child: Divider(color: AppStyles.dividerColor, height: 1),
                      ),
                      
                      // Cloud Server Endpoint Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.cloud, color: AppStyles.textSecondary, size: 24),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.cfgCloudLabel, style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text('$_cloudScheme://$_cloudUrl:$_cloudPort', style: AppStyles.consoleBody),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text('Ping: $resolvedPingStatus', style: AppStyles.consoleBody.copyWith(color: pingColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: Text(l10n.cfgBtnUpdate),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppStyles.waterActionAccent,
                                  side: const BorderSide(color: AppStyles.waterActionAccent),
                                  minimumSize: const Size(130, 36),
                                ),
                                onPressed: _editCloudEndpointDialog,
                              ),
                              const SizedBox(height: AppStyles.spaceSM),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.network_ping, size: 16),
                                label: Text(l10n.cloudBtnTestApi),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppStyles.textSecondary,
                                  side: const BorderSide(color: AppStyles.dividerColor),
                                  minimumSize: const Size(130, 36),
                                ),
                                onPressed: _checkCloudPing,
                              ),
                            ],
                          ),
                        ],
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
                      Text(l10n.cfgAgroSection, style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
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
                                Text(l10n.cfgIrrPeriod, style: AppStyles.bodyText.copyWith(color: AppStyles.techSecondaryAccent, fontWeight: FontWeight.bold)),
                                Text(l10n.cfgPeriodRange(irrStart.toString().padLeft(2, '0'), irrEnd.toString().padLeft(2, '0')), style: AppStyles.consoleBody),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _adjustDayEnd(-1), color: AppStyles.techSecondaryAccent),
                                Text(l10n.cfgShiftBtn, style: AppStyles.captionStatus.copyWith(color: AppStyles.techSecondaryAccent)),
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
                                Text(l10n.cfgPredPeriod, style: AppStyles.bodyText.copyWith(color: AppStyles.warningAccent, fontWeight: FontWeight.bold)),
                                Text(l10n.cfgPeriodRange(predStart.toString().padLeft(2, '0'), predEnd.toString().padLeft(2, '0')), style: AppStyles.consoleBody),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _adjustDayStart(-1), color: AppStyles.warningAccent),
                                Text(l10n.cfgShiftBtn, style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent)),
                                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _adjustDayStart(1), color: AppStyles.warningAccent),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      if (_scheduleWarning != null && _scheduleWarning!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppStyles.spaceSM),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppStyles.warningAccent, size: 16),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: Text(
                                  _scheduleWarning!,
                                  style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spaceSM),

                // 4. ML Models Management Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: AppStyles.cardShell(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MACHINE LEARNING MODELS (RANDOM FOREST)',
                        style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: AppStyles.dividerColor),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.psychology, color: AppStyles.techSecondaryAccent, size: 28),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeModel != null
                                      ? 'Active: ${activeModel.cropName} (v${activeModel.version})'
                                      : 'Active: Default Embedded Model',
                                  style: AppStyles.bodyText.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: activeModel != null ? AppStyles.successAccent : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  activeModel != null
                                      ? (activeModel.description.isNotEmpty ? activeModel.description : 'Custom downloaded Random Forest Classifier')
                                      : 'Built-in 2-feature Random Forest classifier (Solar Radiation + Soil Moisture)',
                                  style: AppStyles.captionStatus,
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  '${savedModels.length} custom model(s) stored on device',
                                  style: AppStyles.consoleBody.copyWith(color: AppStyles.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.model_training, size: 16),
                            label: const Text('Manage Catalog'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppStyles.techSecondaryAccent,
                              side: const BorderSide(color: AppStyles.techSecondaryAccent),
                              minimumSize: const Size(130, 36),
                            ),
                            onPressed: _showMlModelManager,
                          ),
                        ],
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

class MlModelManagerSheet extends StatefulWidget {
  final CliRoutines routines;
  const MlModelManagerSheet({super.key, required this.routines});

  @override
  State<MlModelManagerSheet> createState() => _MlModelManagerSheetState();
}

class _MlModelManagerSheetState extends State<MlModelManagerSheet> {
  bool _isLoading = true;
  String? _errorMsg;
  List<Map<String, dynamic>> _cloudModels = [];
  List<RfModel> _localModels = [];
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final cloudRes = await widget.routines.cloudApi.getAvailableRfModels();
      final localRes = widget.routines.db.getSavedRfModels();
      if (mounted) {
        setState(() {
          _cloudModels = cloudRes;
          _localModels = localRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownload(Map<String, dynamic> metadata) async {
    final mId = metadata['model_id'];
    setState(() => _processingIds.add(mId));
    try {
      final jsonPayload = await widget.routines.cloudApi.downloadRfModel(mId);
      widget.routines.db.saveRfModel(metadata, jsonPayload);
      _localModels = widget.routines.db.getSavedRfModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${metadata['crop_name']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(mId));
    }
  }

  void _handleSetActive(String modelId) {
    widget.routines.db.setActiveRfModel(modelId);
    setState(() {
      _localModels = widget.routines.db.getSavedRfModels();
    });
  }

  void _handleDelete(String modelId, String name) {
    widget.routines.db.deleteRfModel(modelId);
    setState(() {
      _localModels = widget.routines.db.getSavedRfModels();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted $name from device.')));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppStyles.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ML Models Catalog',
                    style: AppStyles.displayHeader.copyWith(
                      color: AppStyles.techSecondaryAccent,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppStyles.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spaceSM),
              Text(
                'Download crop-specific Random Forest classifiers from the server to use for local & cloud inference. Long-press a downloaded model to delete it.',
                style: AppStyles.bodyText.copyWith(
                  color: AppStyles.textSecondary,
                ),
              ),
              const Divider(
                color: AppStyles.dividerColor,
                height: AppStyles.spaceXL,
              ),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMsg != null)
                Center(
                  child: Text(
                    'Error: $_errorMsg',
                    style: AppStyles.bodyText.copyWith(
                      color: AppStyles.errorAccent,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _cloudModels.length,
                    itemBuilder: (context, index) {
                      final meta = _cloudModels[index];
                      final mId = meta['model_id'];
                      final isProcessing = _processingIds.contains(mId);

                      final localMatch = _localModels
                          .where((m) => m.modelId == mId)
                          .firstOrNull;
                      final isDownloaded = localMatch != null;
                      final isActive = isDownloaded && localMatch.isActive;

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppStyles.spaceSM,
                        ),
                        decoration: AppStyles.cardShell(
                          isSelected: isActive,
                          borderAccent: AppStyles.dividerColor,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.psychology,
                            color: isActive
                                ? AppStyles.successAccent
                                : (isDownloaded
                                      ? AppStyles.textSecondary
                                      : AppStyles.textMuted),
                          ),
                          title: Text(
                            meta['crop_name'] ?? mId,
                            style: AppStyles.sectionTitle.copyWith(
                              color: isActive
                                  ? AppStyles.successAccent
                                  : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Version: ${meta['version'] ?? 'N/A'} | ${meta['size_kb'] ?? '?'} KB\n${meta['description'] ?? ''}',
                            style: AppStyles.captionStatus,
                          ),
                          isThreeLine: true,
                          trailing: isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : isDownloaded
                              ? (isActive
                                    ? const Chip(
                                        label: Text('ACTIVE'),
                                        backgroundColor:
                                            AppStyles.successAccent,
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed: () => _handleSetActive(mId),
                                        child: const Text('Set Active'),
                                      ))
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download'),
                                  onPressed: () => _handleDownload(meta),
                                ),
                          onLongPress: isDownloaded && !isActive
                              ? () =>
                                    _handleDelete(mId, meta['crop_name'] ?? mId)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}