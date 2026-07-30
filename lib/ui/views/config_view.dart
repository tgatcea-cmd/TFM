import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/db/database_service.dart';
import '../../data/models/app_settings.dart';
import '../../new_main.dart'; // To access providers
import '../styles.dart';
import 'map_picker_dialog.dart';

class ConfigView extends ConsumerStatefulWidget {
  final DatabaseService db;
  const ConfigView({super.key, required this.db});

  @override
  ConsumerState<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends ConsumerState<ConfigView> {
  late AppSettings _settings;

  // Server
  late TextEditingController _schemeCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _tokenCtrl;
  late TextEditingController _syncScheduleCtrl;

  @override
  void initState() {
    super.initState();
    _settings = widget.db.getAppSettings();
    
    // Clamp values to prevent UI assertion errors with legacy DB states
    _settings.agronomicDayStart = _settings.agronomicDayStart.clamp(16, 22);
    _settings.agronomicDayEnd = _settings.agronomicDayEnd.clamp(6, 12);
    if (!['system', 'light', 'dark'].contains(_settings.themeMode)) {
      _settings.themeMode = 'system';
    }

    _schemeCtrl = TextEditingController(text: _settings.tfmServerScheme);
    _urlCtrl = TextEditingController(text: _settings.tfmServerUrl);
    _portCtrl = TextEditingController(text: _settings.tfmServerPort.toString());
    _tokenCtrl = TextEditingController(text: _settings.tfmServerApiKey);
    _syncScheduleCtrl = TextEditingController(text: _settings.syncScheduleHours.toString());
  }

  @override
  void dispose() {
    _schemeCtrl.dispose();
    _urlCtrl.dispose();
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    _syncScheduleCtrl.dispose();
    super.dispose();
  }

  void _saveAll() {
    widget.db.saveAppSettings(
      isFirstTime: false,
      themeMode: _settings.themeMode,
      agronomicDayStart: _settings.agronomicDayStart,
      agronomicDayEnd: _settings.agronomicDayEnd,
      tfmServerScheme: _schemeCtrl.text.trim(),
      tfmServerUrl: _urlCtrl.text.trim(),
      tfmServerPort: int.tryParse(_portCtrl.text.trim()) ?? 3000,
      tfmServerApiKey: _tokenCtrl.text.trim(),
      syncScheduleHours: int.tryParse(_syncScheduleCtrl.text.trim()) ?? 24,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved!')),
    );
    // Exit if it was first time setup
    if (_settings.isFirstTime) {
      Navigator.of(context).pop();
    }
  }

  void _revertToDefault() {
    setState(() {
      _settings = AppSettings(); // Fresh instance with defaults
      _schemeCtrl.text = _settings.tfmServerScheme;
      _urlCtrl.text = _settings.tfmServerUrl;
      _portCtrl.text = _settings.tfmServerPort.toString();
      _tokenCtrl.text = _settings.tfmServerApiKey;
      _syncScheduleCtrl.text = _settings.syncScheduleHours.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reverted to defaults. Tap Save to apply.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Revert to Default',
            onPressed: _revertToDefault,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saveAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_settings.isFirstTime)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'First time setup: Please complete all important fields and save.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // 1. Information Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('App Version: 2.0.0 (Ponytail Edition)'),
                      dense: true,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final ble = ref.watch(bleServiceProvider);
                        final devName = ble.connectedDevice?.platformName ?? "None";
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text('Connected Device: $devName'),
                          dense: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Agronomic Day time period
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agronomic Day Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('Defines the "Forecasting Available" zone for the charts.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Text('Start Hour: ${_settings.agronomicDayStart}:00', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Slider(
                      value: _settings.agronomicDayStart.toDouble(),
                      min: 16,
                      max: 22,
                      divisions: 6,
                      label: '${_settings.agronomicDayStart}:00',
                      onChanged: (val) => setState(() => _settings.agronomicDayStart = val.toInt()),
                    ),
                    const SizedBox(height: 8),
                    Text('End Hour: 0${_settings.agronomicDayEnd}:00', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Slider(
                      value: _settings.agronomicDayEnd.toDouble(),
                      min: 6,
                      max: 12,
                      divisions: 6,
                      label: '0${_settings.agronomicDayEnd}:00',
                      onChanged: (val) => setState(() => _settings.agronomicDayEnd = val.toInt()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Location
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('If location permission granted, automatic pull. Otherwise manual setup.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('Update from GPS'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() {
                          _settings.gpsLat = 40.4168; // Mocked for PoC
                          _settings.gpsLon = -3.7038;
                          _settings.isGpsEnabled = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS updated (Mocked)')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text('Manual Map Setup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final LatLng? newLocation = await showDialog<LatLng>(
                          context: context,
                          builder: (context) => MapPickerDialog(
                            initialLat: _settings.manualLat,
                            initialLon: _settings.manualLon,
                          ),
                        );

                        if (newLocation != null && mounted) {
                          setState(() {
                            _settings.manualLat = newLocation.latitude;
                            _settings.manualLon = newLocation.longitude;
                            _settings.isGpsEnabled = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Manual location saved! (${newLocation.latitude.toStringAsFixed(3)}, ${newLocation.longitude.toStringAsFixed(3)})',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Server Connection
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Server Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _schemeCtrl,
                            decoration: const InputDecoration(labelText: 'Scheme', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _urlCtrl,
                            decoration: const InputDecoration(labelText: 'IP / Domain', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _portCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _tokenCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'API Token', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _syncScheduleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Automatic sync schedule (hours)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Local Database
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Local Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('Database size: ~1.2 MB (Estimated)'), // Mocked size
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Clear DB', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              widget.db.clearAllData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database cleared')));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              return ElevatedButton.icon(
                                icon: const Icon(Icons.cloud_sync),
                                label: const Text('Sync Now'),
                                onPressed: () {
                                  ref.read(syncServiceProvider).syncDirtyDevices();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual sync triggered')));
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Theme
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: _settings.themeMode,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('System Default')),
                        DropdownMenuItem(value: 'light', child: Text('Light Mode')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _settings.themeMode = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppStyles.primaryTeal(context),
                foregroundColor: Colors.white,
              ),
              onPressed: _saveAll,
              child: const Text('Save & Apply', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
