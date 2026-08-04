import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/features/location/location_controller.dart';
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

  Future<void> _handleAutoGpsLocation() async {
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.cfgAcquiringGps);
    try {
      final locService = LocationService();
      final pos = await locService.getCurrentPosition();
      if (pos != null) {
        widget.routines.db.saveLocationSettings(pos.latitude, pos.longitude, true);
        setState(() {});
        widget.onStatusChange(
          l10n.cfgGpsUpdated(pos.latitude.toStringAsFixed(4), pos.longitude.toStringAsFixed(4))
        );
      } else {
        widget.onStatusChange(l10n.cfgGpsFailed);
      }
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
                      color: Colors.black38,
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
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
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

    final irrStart = (_agronomicDayEnd + 1) % 24;
    final irrEnd = (_agronomicDayStart - 1 + 24) % 24;
    final predStart = _agronomicDayStart;
    final predEnd = _agronomicDayEnd;
    
    final resolvedMeteoStatus = _openMeteoStatus ?? l10n.cfgChecking;
    final resolvedPingStatus = _cloudPingStatus ?? l10n.cfgPingTesting;

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
                      ListTile(
                        leading: const Icon(Icons.access_time, color: AppStyles.textSecondary),
                        title: Text(l10n.cfgSysTimeLabel, style: AppStyles.bodyText),
                        subtitle: Text('$dateStr  (${_now.millisecondsSinceEpoch})', style: AppStyles.consoleBody),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on, color: AppStyles.textSecondary),
                        title: Text(l10n.cfgLocSettingsLabel, style: AppStyles.bodyText),
                        subtitle: Text(locStr, style: AppStyles.consoleBody),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_location_alt, color: AppStyles.techSecondaryAccent),
                          onPressed: _showLocationSettingsChoice,
                          tooltip: l10n.cfgTooltipLoc,
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
                      Text(l10n.cfgNetSection, style: AppStyles.captionStatus.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(color: AppStyles.dividerColor),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny, color: AppStyles.textSecondary),
                        title: Text(l10n.cfgMeteoLabel, style: AppStyles.bodyText),
                        trailing: Text(
                          resolvedMeteoStatus, 
                          style: AppStyles.consoleBody.copyWith(
                            color: resolvedMeteoStatus.contains('OK') ? AppStyles.successAccent : AppStyles.errorAccent, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cloud, color: AppStyles.textSecondary),
                        title: Text(l10n.cfgCloudLabel, style: AppStyles.bodyText),
                        subtitle: Text('$_cloudScheme://$_cloudUrl:$_cloudPort\nPing: $resolvedPingStatus', style: AppStyles.consoleBody),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppStyles.waterActionAccent),
                          onPressed: _editCloudEndpointDialog,
                          tooltip: l10n.cfgTooltipEditEnd,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}