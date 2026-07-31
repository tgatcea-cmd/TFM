import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tfm_app/cli_routines.dart';

class NearbyScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;

  const NearbyScreen({super.key, required this.routines, required this.onBack});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final FocusNode _focusNode = FocusNode();
  List<ScanResult> _devices = [];
  bool _isSelecting = false;
  String _selectionInput = '';

  bool _isEnteringSecret = false;
  ScanResult? _selectedDevice;
  String _suggestedSecret = '';
  String _enteredSecret = '';
  int _retryCount = 0;
  bool _isConnecting = false;
  String _statusMsg = '';
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _startListeningToScan();
  }

  void _startListeningToScan() {
    _scanSub?.cancel(); // Cancel existing listener if re-scanning
    widget.routines.searchNearbyDevices();

    _scanSub = widget.routines.bleService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devices = results;
          _statusMsg = 'Found ${_devices.length} devices...';
        });
      }
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    widget.routines.bleService.stopScan(); // Stop scan when exiting  screen
    _focusNode.dispose();
    super.dispose();
  }

  void _searchNearby() {
    setState(() {
      _statusMsg = 'Refreshing scan...';
      _devices.clear();
    });
    _startListeningToScan();
  }


  String _maskSecret(String secret) {
    if (secret.isEmpty) return '';
    if (secret.length <= 2) return secret;
    return '${secret[0]}${'*' * (secret.length - 2)}${secret[secret.length - 1]}';
  }

  Future<String?> _getSavedSecret(String id) async {
    return await widget.routines.secureStorage.getDeviceSecret(id);
  }

  Future<void> _saveSecret(String id, String name, String secret) async {
    widget.routines.db.saveDeviceBasic(id, name);
    await widget.routines.secureStorage.saveDeviceSecret(id, secret);
  }

  void _processSelection() async {
    final idx = int.tryParse(_selectionInput);
    if (idx != null && idx >= 0 && idx < _devices.length) {
      _selectedDevice = _devices[idx];
      final saved =
          await _getSavedSecret(_selectedDevice!.device.remoteId.str) ?? '';
      if (!mounted) return;
      setState(() {
        _suggestedSecret = saved;
        _enteredSecret = '';
        _isEnteringSecret = true;
        _retryCount = 0;
        _statusMsg =
            'Enter secret for ${_selectedDevice!.device.platformName} (Press Enter to use saved if shown)';
      });
    } else {
      setState(() {
        _statusMsg = 'Invalid selection.';
      });
    }
    _isSelecting = false;
    _selectionInput = '';
  }

  Future<void> _attemptConnection() async {
    if (_selectedDevice == null) return;

    String secretToUse = _enteredSecret.isNotEmpty
        ? _enteredSecret
        : _suggestedSecret;
    if (_enteredSecret.isEmpty && _suggestedSecret.isEmpty) {
      secretToUse = ''; // Default is ""
    }

    setState(() {
      _isEnteringSecret = false;
      _isConnecting = true;
      _statusMsg = 'Connecting...';
    });

    final bool success = await widget.routines.connectToDevice(
      _selectedDevice!.device,
      secretToUse,
    );

    if (!mounted) return;

    if (success) {
      await _saveSecret(
        _selectedDevice!.device.remoteId.str,
        _selectedDevice!.device.platformName,
        secretToUse,
      );
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _selectedDevice = null;
        _statusMsg = 'Connected successfully!';
      });
    } else {
      _retryCount++;
      if (_retryCount >= 3) {
        setState(() {
          _isConnecting = false;
          _selectedDevice = null;
          _statusMsg = 'Connection failed 3 times. Aborting.';
        });
      } else {
        setState(() {
          _isConnecting = false;
          _isEnteringSecret = true;
          _enteredSecret = '';
          _statusMsg = 'Connection failed. Retry $_retryCount/3. Enter secret:';
        });
      }
    }
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isAlt = HardwareKeyboard.instance.isAltPressed;

    if (isAlt && event.logicalKey == LogicalKeyboardKey.keyD) {
      widget.routines.bleService.disconnect();
      setState(() => _statusMsg = 'Disconnected.');
      return true;
    }

    if (_isConnecting) return true; // Block input while connecting

    if (_isEnteringSecret) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _attemptConnection();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _isEnteringSecret = false;
          _selectedDevice = null;
          _statusMsg = 'Cancelled connection.';
        });
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          if (_enteredSecret.isNotEmpty) {
            _enteredSecret = _enteredSecret.substring(
              0,
              _enteredSecret.length - 1,
            );
          } else {
            // If they backspace on empty, clear suggested to let them type fully empty if they want
            _suggestedSecret = '';
          }
        });
        return true;
      } else if (event.character != null &&
          !event.character!.contains(RegExp(r'[\x00-\x1F]'))) {
        setState(() {
          _enteredSecret += event.character!;
        });
        return true;
      }
      return false;
    }

    if (_isSelecting) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() => _processSelection());
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _isSelecting = false;
          _selectionInput = '';
          _statusMsg = 'Cancelled selection.';
        });
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          if (_selectionInput.isNotEmpty) {
            _selectionInput = _selectionInput.substring(
              0,
              _selectionInput.length - 1,
            );
          }
        });
        return true;
      } else if (event.character != null &&
          RegExp(r'[0-9]').hasMatch(event.character!)) {
        setState(() {
          _selectionInput += event.character!;
        });
        return true;
      }
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();
      return true;
    }
    if (event.character == 'n') {
      _searchNearby();
      return true;
    }
    if (event.character == 's') {
      setState(() {
        _isSelecting = true;
        _selectionInput = '';
        _statusMsg = 'Select device number:';
      });
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.routines.bleService.isConnected;
    String content = '=== NEARBY BLE DEVICES ===\n';
    if (isConnected) {
      final id =
          widget.routines.bleService.connectedDevice?.remoteId.str ??
          'Connected Station';
      content += 'State: CONNECTED to [$id]\n\n';
    } else {
      content += 'State: DISCONNECTED\n\n';
    }

    if (_devices.isEmpty) {
      content += 'No devices found.\n';
    } else {
      for (int i = 0; i < _devices.length; i++) {
        final d = _devices[i];
        final name = d.advertisementData.advName.isNotEmpty
            ? d.advertisementData.advName
            : d.device.platformName;
        content += '[$i] $name (${d.device.remoteId})\n';
      }
    }
    content +=
        '\nShortcuts:\n  [n] Refresh/Scan  | [s] Select Device  | [Alt+D] Disconnect\n  [ESC] Back to Main Menu\n';

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      autofocus: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSelecting)
            Text(
              '> Select: $_selectionInput',
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          if (_isEnteringSecret)
            Text(
              '> Secret: ${_enteredSecret.isNotEmpty ? _enteredSecret : (_suggestedSecret.isNotEmpty ? '(${_maskSecret(_suggestedSecret)})' : '""')}_',
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          if (_statusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _statusMsg,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
