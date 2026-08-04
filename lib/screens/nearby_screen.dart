import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/l10n/app_localizations.dart';

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

class _NearbyScreenState extends State<NearbyScreen> {
  List<ScanResult> _devices = [];
  bool _isConnecting = false;
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _startListeningToScan();
  }

  void _startListeningToScan() {
    _scanSub?.cancel();
    widget.routines.searchNearbyDevices();

    _scanSub = widget.routines.bleService.scanResults.listen((results) {
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

  @override
  void dispose() {
    _scanSub?.cancel();
    widget.routines.bleService.stopScan();
    super.dispose();
  }

  void _searchNearby() {
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
    return await widget.routines.secureStorage.getDeviceSecret(id);
  }

  Future<void> _saveSecret(String id, String name, String secret) async {
    widget.routines.db.saveDeviceBasic(id, name);
    await widget.routines.secureStorage.saveDeviceSecret(
      id,
      secret,
    );
  }

  // --- GUI Dialog replacing the CLI prompt ---
  Future<void> _promptConnection(ScanResult result) async {
    final l10n = AppLocalizations.of(context)!;
    final deviceId = result.device.remoteId.str;
    final deviceName = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : (result.device.platformName.isNotEmpty
              ? result.device.platformName
              : deviceId);

    // Fetch the saved secret before showing the dialog
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
              title: Text(l10n.nbConnectDialogTitle(deviceName)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nbDeviceId(deviceId),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  if (savedSecret.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.nbSavedSecret(isSavedSecretObscured ? _maskSecret(savedSecret) : savedSecret),
                            style: TextStyle(
                              color: isSavedSecretObscured ? Colors.greenAccent : Colors.amberAccent,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSavedSecretObscured ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: Colors.grey,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: l10n.nbSecretLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility : Icons.visibility_off,
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
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
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

    // Trigger the connection routine
    final bool success = await widget.routines.connectToDevice(device, secret);

    if (!mounted) return;

    if (success) {
      await _saveSecret(device.remoteId.str, deviceName, secret);
      widget.onStatusChange(l10n.nbConnectedSuccess(deviceName));
    } else {
      widget.onStatusChange(l10n.nbConnectionFailed);
      // Optionally re-prompt here, but letting the user tap the device again is standard GUI UX.
    }

    setState(() => _isConnecting = false);
  }

  void _disconnect() {
    final l10n = AppLocalizations.of(context)!;
    widget.routines.bleService.disconnect();
    widget.onStatusChange(l10n.nbDisconnectedStatus);
    setState(() {}); // Trigger rebuild to update UI
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = widget.routines.bleService.isConnected;
    final connectedDev = widget.routines.bleService.connectedDevice;

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
                    onPressed: _isConnecting ? null : _searchNearby,
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

          // Device List
          Expanded(
            child: _isConnecting
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
