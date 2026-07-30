import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tfm_app/cli_routines.dart';

class ConfigScreen extends StatefulWidget {
  final CliRoutines routines;
  final VoidCallback onBack;

  const ConfigScreen({super.key, required this.routines, required this.onBack});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final FocusNode _focusNode = FocusNode();

  late String _cloudScheme;
  late String _cloudUrl;
  late int _cloudPort;
  late int _agronomicDayStart; // Prediction start
  late int _agronomicDayEnd; // Prediction end / Irrigation start - 1

  bool _isEditingCloudIp = false;
  String _inputBuffer = '';

  String _openMeteoStatus = 'Checking...';
  String _cloudPingStatus = 'Checking...';
  String _statusMsg = '';

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  late int _baseDayStart;
  late int _baseDayEnd;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    final settings = widget.routines.db.getAppSettings();
    _cloudScheme = settings.tfmServerScheme;
    _cloudUrl = settings.tfmServerUrl;
    _cloudPort = settings.tfmServerPort;
    _agronomicDayStart = settings.agronomicDayStart;
    _agronomicDayEnd = settings.agronomicDayEnd;
    _baseDayStart = settings.agronomicDayStart;
    _baseDayEnd = settings.agronomicDayEnd;

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _checkOpenMeteo();
    _checkCloudPing();
  }

  // ponytail: enforce non-overlapping valid periods by auto-shifting the opposing boundary
  void _adjustDayStart(int delta) {
    final newVal = (_agronomicDayStart + delta) % 24;
    final diff = ((newVal - _baseDayStart + 36) % 24) - 12;
    if (diff.abs() <= 3) {
      setState(() {
        _agronomicDayStart = newVal;
        // Ensure prediction & irrigation both maintain at least 1h window
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayEnd = (_agronomicDayStart - 2 + 24) % 24;
        }
        _statusMsg =
            'Prediction start: $_agronomicDayStart:00 (${diff >= 0 ? "+$diff" : "$diff"}h). Boundaries forced to prevent overlap.';
      });
    } else {
      setState(
        () => _statusMsg =
            'Limit reached: Prediction start can only be adjusted ±3h from base ($_baseDayStart:00).',
      );
    }
  }

  void _adjustDayEnd(int delta) {
    final newVal = (_agronomicDayEnd + delta) % 24;
    final diff = ((newVal - _baseDayEnd + 36) % 24) - 12;
    if (diff.abs() <= 3) {
      setState(() {
        _agronomicDayEnd = newVal;
        // Ensure prediction & irrigation both maintain at least 1h window
        if ((_agronomicDayStart - _agronomicDayEnd + 24) % 24 <= 1) {
          _agronomicDayStart = (_agronomicDayEnd + 2) % 24;
        }
        _statusMsg =
            'Irrigation end: $_agronomicDayEnd:00 (${diff >= 0 ? "+$diff" : "$diff"}h). Boundaries forced to prevent overlap.';
      });
    } else {
      setState(
        () => _statusMsg =
            'Limit reached: Irrigation end can only be adjusted ±3h from base ($_baseDayEnd:00).',
      );
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkOpenMeteo() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&current_weather=true',
            ),
          )
          .timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _openMeteoStatus = (res.statusCode == 200)
              ? 'OK (200)'
              : 'Error (${res.statusCode})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _openMeteoStatus = 'Offline / Failed');
      }
    }
  }

  Future<void> _checkCloudPing() async {
    setState(() => _cloudPingStatus = 'Testing...');
    final sw = Stopwatch()..start();

    for (final path in ['/health', '/api/ping']) {
      try {
        final res = await http.get(Uri.parse('$_cloudScheme://$_cloudUrl:$_cloudPort$path')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) setState(() => _cloudPingStatus = '${data['status']?.toString().toUpperCase() ?? 'OK'} (${sw.elapsedMilliseconds} ms)');
          return;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _cloudPingStatus = 'Unreachable / Failed');
  }

  void _saveConfiguration() {
    widget.routines.db.saveAppSettings(
      tfmServerScheme: _cloudScheme,
      tfmServerUrl: _cloudUrl,
      tfmServerPort: _cloudPort,
      agronomicDayStart: _agronomicDayStart,
      agronomicDayEnd: _agronomicDayEnd,
    );
    widget.routines.cloudApi.updateEndpoint(_cloudScheme, _cloudUrl, _cloudPort);
    setState(() {
      _statusMsg = 'Configuration applied and saved to database & live ApiClient!';
    });
  }

  void _parseAndSetCloudEndpoint(String rawInput) {
    if (rawInput.trim().isEmpty) return;
    String input = rawInput.trim();
    if (!input.contains('://')) {
      input = '$_cloudScheme://$input';
    }
    try {
      final uri = Uri.parse(input);
      if (uri.scheme.isNotEmpty) {
        _cloudScheme = uri.scheme;
      }
      if (uri.host.isNotEmpty) {
        _cloudUrl = uri.host;
      }
      if (uri.hasPort) {
        _cloudPort = uri.port;
      }
    } catch (_) {}
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (_isEditingCloudIp) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() {
          if (_inputBuffer.isNotEmpty) {
            _parseAndSetCloudEndpoint(_inputBuffer);
          }
          _isEditingCloudIp = false;
          _inputBuffer = '';
          _statusMsg =
              'Cloud endpoint updated to $_cloudScheme://$_cloudUrl:$_cloudPort. Press [a] to apply permanently.';
        });
        _checkCloudPing();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _isEditingCloudIp = false;
          _inputBuffer = '';
          _statusMsg = 'Cloud endpoint edit cancelled.';
        });
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          if (_inputBuffer.isNotEmpty) {
            _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
          }
        });
        return true;
      } else if (event.character != null &&
          !event.character!.contains(RegExp(r'[\x00-\x1F]'))) {
        setState(() {
          _inputBuffer += event.character!;
        });
        return true;
      }
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();
      return true;
    }

    if (event.character == 'c') {
      setState(() {
        _isEditingCloudIp = true;
        _inputBuffer = '';
        _statusMsg =
            'Enter Cloud Endpoint (e.g. http://192.168.1.50:3000) or press Enter to keep current:';
      });
      return true;
    }

    if (event.character == 'i') {
      _adjustDayEnd(1);
      return true;
    }
    if (event.character == 'I' || event.character == 'u') {
      _adjustDayEnd(-1);
      return true;
    }

    if (event.character == 'p') {
      _adjustDayStart(1);
      return true;
    }
    if (event.character == 'P' || event.character == 'o') {
      _adjustDayStart(-1);
      return true;
    }

    if (event.character == 'a') {
      _saveConfiguration();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final day = _now.day.toString().padLeft(2, '0');
    final month = _now.month.toString().padLeft(2, '0');
    final year = _now.year.toString().substring(2);
    final hour = _now.hour.toString().padLeft(2, '0');
    final min = _now.minute.toString().padLeft(2, '0');
    final dateStr =
        '$day/$month/$year $hour:$min (${_now.millisecondsSinceEpoch})';

    final locSettings = widget.routines.db.getLocationSettings();
    final locStr =
        'Lat: ${locSettings.latitude.toStringAsFixed(4)}, Lon: ${locSettings.longitude.toStringAsFixed(4)} (${locSettings.isGps ? 'GPS' : 'Manual'})';

    final irrStart = (_agronomicDayEnd + 1) % 24;
    final irrEnd = (_agronomicDayStart - 1 + 24) % 24;
    final predStart = _agronomicDayStart;
    final predEnd = _agronomicDayEnd;

    final content =
        '''
=== CONFIGURATION MENU ===

1. System Date & Time:
   $dateStr

2. Location Status:
   $locStr

3. Open-Meteo API Status:
   $_openMeteoStatus

4. Cloud Server Settings:
   Endpoint: $_cloudScheme://$_cloudUrl:$_cloudPort
   Ping Status: $_cloudPingStatus

5. Agronomic Day Hours:
   • Irrigation Period (Cyan Zone):  ${irrStart.toString().padLeft(2, '0')}hrs to ${irrEnd.toString().padLeft(2, '0')}hrs
   • Prediction Period (Yellow Zone): ${predStart.toString().padLeft(2, '0')}hrs to ${predEnd.toString().padLeft(2, '0')}hrs

---------------------------------------------------------
Shortcuts:
  [c]       Configure Cloud Endpoint
  [i] / [u] Adjust Irrigation Period (+1h / -1h, max ±3h)
  [p] / [o] Adjust Prediction Period (+1h / -1h, max ±3h)
  [a]       Apply & Save Configuration
  [ESC]     Back to Entry Menu
''';

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
          if (_isEditingCloudIp)
            Text(
              '> Cloud Endpoint: ${_inputBuffer.isNotEmpty ? _inputBuffer : "($_cloudScheme://$_cloudUrl:$_cloudPort)"}_',
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
