import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/core/utils/l10n/app_localizations.dart';

class NearbyScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;
  final void Function(String msg) onStatusChange;

  const NearbyScreen({
    super.key,
    required this.routines,
    required this.onBack,
    required this.onStatusChange,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with WidgetsBindingObserver {
  List<ScanResult> _devices = [];
  bool _isConnecting = false;
  
  // Hardware & Permission States
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _locationEnabled = true;
  LocationPermission _locationPerm = LocationPermission.always;
  
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen for app resumes
    
    _checkLocationStatus();

    // Listen to real-time Bluetooth adapter changes
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _adapterState = state);
        if (_isScanningAllowed) {
          _startListeningToScan();
        } else {
          widget.routines.stopBleScan();
          setState(() => _devices.clear());
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adapterStateSub?.cancel();
    _scanSub?.cancel();
    widget.routines.stopBleScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when the user returns from OS settings
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    // Desktop platforms (Windows, Linux, macOS) do not require Location services or Location permissions for BLE scanning.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (mounted) {
        setState(() {
          _locationEnabled = true;
          _locationPerm = LocationPermission.always;
        });
        if (_isScanningAllowed) {
          _startListeningToScan();
        }
      }
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    
    if (mounted) {
      setState(() {
        _locationEnabled = serviceEnabled;
        _locationPerm = permission;
      });
      
      if (_isScanningAllowed) {
        _startListeningToScan();
      }
    }
  }

  bool get _isScanningAllowed {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _adapterState == BluetoothAdapterState.on;
    }
    return _adapterState == BluetoothAdapterState.on && 
           _locationEnabled && 
           (_locationPerm == LocationPermission.always || _locationPerm == LocationPermission.whileInUse);
  }

  void _startListeningToScan() {
    if (!_isScanningAllowed) return;

    _scanSub?.cancel();
    widget.routines.searchNearbyDevices();

    _scanSub = widget.routines.bleScanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devices = results;
        });
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          widget.onStatusChange(l10n.nbFoundDevices(_devices.length));
        }
      }
    });
  }

  void _searchNearby() {
    if (!_isScanningAllowed) return;
    
    setState(() {
      _devices.clear();
    });
    final l10n = AppLocalizations.of(context)!;
    widget.onStatusChange(l10n.nbRefreshingScan);
    _startListeningToScan();
  }

  String _maskSecret(String secret) {
    if (secret.isEmpty) return '';
    return '*' * secret.length;
  }

  Future<String?> _getSavedSecret(String id) async {
    return await widget.routines.getBleSecret(id);
  }

  Future<void> _saveSecret(String id, String name, String secret) async {
    await widget.routines.saveBleSecret(id, name, secret);
  }

  Future<void> _promptConnection(ScanResult result) async {
    final l10n = AppLocalizations.of(context)!;
    final deviceId = result.device.remoteId.str;
    final deviceName = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : (result.device.platformName.isNotEmpty
              ? result.device.platformName
              : deviceId);

    final savedSecret = await _getSavedSecret(deviceId) ?? '';
    String enteredSecret = '';
    bool isObscured = true;
    bool isSavedSecretObscured = true;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppStyles.surfaceColor,
              title: Text(l10n.nbConnectDialogTitle(deviceName), style: AppStyles.sectionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nbDeviceId(deviceId),
                    style: AppStyles.captionStatus,
                  ),
                  const SizedBox(height: AppStyles.spaceMD),
                  if (savedSecret.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.nbSavedSecret(isSavedSecretObscured ? _maskSecret(savedSecret) : savedSecret),
                            style: AppStyles.consoleBody.copyWith(
                              color: isSavedSecretObscured ? AppStyles.successAccent : AppStyles.warningAccent,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSavedSecretObscured ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: AppStyles.textMuted,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isSavedSecretObscured = !isSavedSecretObscured;
                            });
                          },
                          tooltip: isSavedSecretObscured ? l10n.nbTooltipShowSaved : l10n.nbTooltipHideSaved,
                        ),
                      ],
                    ),
                    Text(
                      l10n.nbLeaveBlankHint,
                      style: AppStyles.captionStatus,
                    ),
                    const SizedBox(height: AppStyles.spaceSM),
                  ],
                  TextField(
                    obscureText: isObscured,
                    style: AppStyles.bodyText,
                    decoration: InputDecoration(
                      labelText: l10n.nbSecretLabel,
                      labelStyle: AppStyles.bodyText.copyWith(color: AppStyles.textMuted),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock, color: AppStyles.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility : Icons.visibility_off,
                          color: AppStyles.textMuted,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isObscured = !isObscured;
                          });
                        },
                        tooltip: isObscured ? l10n.nbTooltipShowSecret : l10n.nbTooltipHideSecret,
                      ),
                    ),
                    onChanged: (val) => enteredSecret = val,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel, style: AppStyles.bodyText.copyWith(color: AppStyles.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final secretToUse = enteredSecret.isNotEmpty
                        ? enteredSecret
                        : savedSecret;
                    _attemptConnection(result.device, deviceName, secretToUse);
                  },
                  child: Text(l10n.nbBtnConnect),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _attemptConnection(
    BluetoothDevice device,
    String deviceName,
    String secret,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isConnecting = true);
    widget.onStatusChange(l10n.nbConnectingStatus(deviceName));

    final bool success = await widget.routines.connectToDevice(device, secret);

    if (!mounted) return;

    if (success) {
      await _saveSecret(device.remoteId.str, deviceName, secret);
      widget.onStatusChange(l10n.nbConnectedSuccess(deviceName));
    } else {
      widget.onStatusChange(l10n.nbConnectionFailed);
    }

    setState(() => _isConnecting = false);
  }

  void _disconnect() {
    final l10n = AppLocalizations.of(context)!;
    widget.routines.disconnectBle();
    widget.onStatusChange(l10n.nbDisconnectedStatus);
    setState(() {}); 
  }

  // Visual Warning Card Builder
  Widget _buildWarningCard(String title, String description, IconData icon, String btnText, VoidCallback onAction) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppStyles.spaceMD),
        padding: const EdgeInsets.all(AppStyles.spaceLG),
        decoration: AppStyles.cardShell(borderAccent: AppStyles.errorAccent).copyWith(
          color: AppStyles.errorAccent.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppStyles.errorAccent),
            const SizedBox(height: AppStyles.spaceMD),
            Text(title, style: AppStyles.displayHeader.copyWith(color: AppStyles.errorAccent)),
            const SizedBox(height: AppStyles.spaceSM),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppStyles.bodyText,
            ),
            const SizedBox(height: AppStyles.spaceLG),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.errorAccent.withValues(alpha: 0.2),
                foregroundColor: AppStyles.errorAccent,
                side: const BorderSide(color: AppStyles.errorAccent),
                padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG, vertical: AppStyles.spaceSM),
              ),
              onPressed: onAction,
              child: Text(btnText),
            ),
          ],
        ),
      ),
    );
  }

  // Resolve which requirement is missing
  Widget? _getRequirementOverlay(AppLocalizations l10n) {
    if (_adapterState == BluetoothAdapterState.off) {
      return _buildWarningCard(
        l10n.nbWarningBtOff,
        l10n.nbWarningBtOffDesc,
        Icons.bluetooth_disabled,
        l10n.nbBtnTurnOnBt,
        () {
          if (Platform.isAndroid) FlutterBluePlus.turnOn();
        },
      );
    }
    
    if (_adapterState == BluetoothAdapterState.unauthorized) {
      return _buildWarningCard(
        l10n.nbWarningPerms,
        l10n.nbWarningPermsDesc,
        Icons.security,
        l10n.nbBtnGrantPerms,
        () => Geolocator.openAppSettings(),
      );
    }

    // Location Services and Location Permissions are strictly required for BLE scanning on mobile (Android/iOS).
    // Bypassed on desktop platforms (Windows, Linux, macOS).
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      if (!_locationEnabled) {
        return _buildWarningCard(
          l10n.nbWarningLocOff,
          l10n.nbWarningLocOffDesc,
          Icons.location_off,
          l10n.nbBtnTurnOnLoc,
          () => Geolocator.openLocationSettings(),
        );
      }

      if (_locationPerm == LocationPermission.denied || _locationPerm == LocationPermission.deniedForever) {
        return _buildWarningCard(
          l10n.nbWarningPerms,
          l10n.nbWarningPermsDesc,
          Icons.location_off,
          l10n.nbBtnGrantPerms,
          () async {
            await Geolocator.requestPermission();
            await _checkLocationStatus();
          },
        );
      }
    }

    return null; // All checks passed
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = widget.routines.isBleConnected;
    final connectedDev = widget.routines.connectedBleDevice;
    
    final requirementOverlay = _getRequirementOverlay(l10n);

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Controls
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppStyles.spaceSM,
            runSpacing: AppStyles.spaceSM,
            children: [
              Text(
                l10n.nbScreenTitle,
                style: AppStyles.displayHeader,
              ),
              Wrap(
                spacing: AppStyles.spaceSM,
                runSpacing: AppStyles.spaceSM,
                children: [
                  if (isConnected)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: Text(l10n.nbBtnDisconnect),
                      style: AppStyles.destructiveButtonStyle,
                      onPressed: _disconnect,
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.nbBtnScan),
                    onPressed: (_isConnecting || !_isScanningAllowed) ? null : _searchNearby,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),

          // Active Connection Banner
          if (isConnected)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppStyles.spaceMD),
              padding: const EdgeInsets.all(AppStyles.spaceSM),
              decoration: BoxDecoration(
                color: AppStyles.successAccent.withValues(alpha: 0.1),
                border: Border.all(color: AppStyles.successAccent),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_connected,
                    color: AppStyles.successAccent,
                  ),
                  const SizedBox(width: AppStyles.spaceSM),
                  Text(
                    l10n.nbCurrentConnection(connectedDev?.platformName ?? connectedDev?.remoteId.str ?? l10n.nbUnknownDev),
                    style: AppStyles.consoleBody.copyWith(
                      color: AppStyles.successAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Core Content Area (Warning Overlay OR Device List)
          Expanded(
            child: requirementOverlay ?? (
              _isConnecting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppStyles.spaceMD),
                          Text(
                            l10n.nbNegotiatingStatus,
                            style: AppStyles.captionStatus,
                          ),
                        ],
                      ),
                    )
                  : _devices.isEmpty
                  ? Center(
                      child: Text(
                        l10n.nbNoDevices,
                        textAlign: TextAlign.center,
                        style: AppStyles.captionStatus,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final d = _devices[index];
                        final name = d.advertisementData.advName.isNotEmpty
                            ? d.advertisementData.advName
                            : (d.device.platformName.isNotEmpty
                                  ? d.device.platformName
                                  : l10n.nbUnnamedDev);
                        final isTarget =
                            connectedDev?.remoteId == d.device.remoteId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppStyles.spaceSM),
                          decoration: AppStyles.cardShell(isSelected: isTarget),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Icon(
                                Icons.bluetooth,
                                color: isTarget
                                    ? AppStyles.successAccent
                                    : AppStyles.textMuted,
                              ),
                              title: Text(
                                name,
                                style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                l10n.nbDeviceSub(d.device.remoteId.str, d.rssi),
                                style: AppStyles.consoleBody,
                              ),
                              trailing: isTarget
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppStyles.successAccent,
                                    )
                                  : const Icon(
                                      Icons.chevron_right,
                                      color: AppStyles.textMuted,
                                    ),
                              onTap: isTarget || isConnected
                                  ? null
                                  : () => _promptConnection(d),
                            ),
                          ),
                        );
                      },
                    )
            ),
          ),
        ],
      ),
    );
  }
}