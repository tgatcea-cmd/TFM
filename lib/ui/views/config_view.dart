import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/db/database_service.dart';
import '../../core/api/tfm_server_client.dart';
import '../../main.dart';
import '../styles.dart';
import 'map_picker_dialog.dart';
import 'package:latlong2/latlong.dart';


class ConfigView extends ConsumerStatefulWidget {
  final DatabaseService db;

  const ConfigView({
    super.key,
    required this.db,
  });

  @override
  ConsumerState<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends ConsumerState<ConfigView> {
  late final TextEditingController _urlController;
  late final TextEditingController _portController;
  late final TextEditingController _apiKeyController;

  bool _isConnecting = false;
  bool? _isConnected;
  List<String> _serverModels = [];
  
  late String _selectedModel;
  late bool _invertOutput;
  late bool _permitFill;
  late bool _forceInference;

  @override
  void initState() {
    super.initState();
    final settings = widget.db.getAppSettings();
    _urlController = TextEditingController(text: settings.tfmServerUrl);
    _portController = TextEditingController(text: settings.tfmServerPort.toString());
    _apiKeyController = TextEditingController(text: settings.tfmServerApiKey);
    
    _selectedModel = settings.selectedTfliteModel;
    _invertOutput = settings.invertModelOutput;
    _permitFill = settings.permitOpenMeteoFill;
    _forceInference = settings.alwaysForceInference;

    // Check server availability asynchronously on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_testConnection(silent: true));
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _portController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.db.saveAppSettings(
      tfmServerUrl: _urlController.text.trim(),
      tfmServerPort: int.tryParse(_portController.text.trim()) ?? 3000,
      tfmServerApiKey: _apiKeyController.text.trim(),
      selectedTfliteModel: _selectedModel,
      invertModelOutput: _invertOutput,
      permitOpenMeteoFill: _permitFill,
      alwaysForceInference: _forceInference,
    );
  }

  Future<void> _testConnection({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isConnecting = true;
        _isConnected = null;
      });
    }

    final client = TfmServerClient(
      serverUrl: _urlController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 3000,
      apiKey: _apiKeyController.text.trim(),
    );

    final ok = await client.testConnection();
    List<String> models = [];
    if (ok) {
      models = await client.listTfliteModels();
    }

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = ok;
        _serverModels = models;
        // Keep default selected if empty
        if (!_serverModels.contains('rf_irrigation.tflite')) {
          _serverModels.insert(0, 'rf_irrigation.tflite');
        }
        if (!_serverModels.contains(_selectedModel)) {
          _selectedModel = 'rf_irrigation.tflite';
        }
      });
      _saveSettings();
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Connected successfully! Found ${models.length - 1} models.' : 'Connection failed.'),
            backgroundColor: ok ? Colors.teal : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadModel() async {
    if (_selectedModel == 'rf_irrigation.tflite') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default asset model is pre-loaded.')),
      );
      return;
    }

    setState(() => _isConnecting = true);
    final client = TfmServerClient(
      serverUrl: _urlController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 3000,
      apiKey: _apiKeyController.text.trim(),
    );

    final file = await client.downloadModel(_selectedModel);
    if (mounted) {
      setState(() => _isConnecting = false);
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model $_selectedModel downloaded and set active!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download model file.')),
        );
      }
    }
  }

  Future<void> _showUploadDialog() async {
    final List<String> mockLocalModels = [
      'custom_model_v1.tflite',
      'custom_model_v2.tflite',
      'farm_optimized.tflite',
    ];

    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Local Tflite Model to Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: mockLocalModels.map((model) {
            return ListTile(
              title: Text(model),
              leading: const Icon(Icons.psychology, color: Colors.teal),
              onTap: () {
                Navigator.pop(context);
                unawaited(_uploadModel(model));
              },
            );
          }).toList(),
        ),
      ),
    ));
  }

  Future<void> _uploadModel(String filename) async {
    setState(() => _isConnecting = true);
    final client = TfmServerClient(
      serverUrl: _urlController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 3000,
      apiKey: _apiKeyController.text.trim(),
    );

    // Create mock local file to upload
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsBytes(List<int>.generate(256, (i) => i));

    final ok = await client.uploadModel(tempFile);

    try {
      await tempFile.delete();
    } catch (_) {}

    if (mounted) {
      setState(() => _isConnecting = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model $filename uploaded to server!')),
        );
        await _testConnection(silent: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TFM Server Configuration Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TFM Database Server',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_isConnected != null)
                        Icon(
                          _isConnected! ? Icons.cloud_done : Icons.cloud_off,
                          color: _isConnected! ? Colors.teal : Colors.red,
                        ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'e.g. http://10.0.2.2 or http://your-server-ip',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    onChanged: (_) => _saveSettings(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings_ethernet),
                          ),
                          onChanged: (_) => _saveSettings(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _apiKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'API Token',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                          onChanged: (_) => _saveSettings(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isConnecting ? null : () => _testConnection(),
                        icon: _isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                              )
                            : const Icon(Icons.wifi),
                        label: const Text('Test & Sync'),
                      ),
                      if (_isConnected == true)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal.shade900,
                            side: BorderSide(color: Colors.teal.shade200),
                          ),
                          onPressed: _isConnecting ? null : _showUploadDialog,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Local Model'),
                        ),
                    ],
                  ),
                  if (_isConnected == true && _serverModels.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Select Recommendation Model (.tflite)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          isExpanded: true,
                          items: _serverModels.map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedModel = val);
                              _saveSettings();
                            }
                          },
                        ),
                      ),
                    ),
                    if (_selectedModel != 'rf_irrigation.tflite') ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isConnecting ? null : _downloadModel,
                        icon: const Icon(Icons.download_for_offline),
                        label: const Text('Download Selected Model'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inference Logic Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inference Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Invert Model Output'),
                    subtitle: const Text('Toggle output recommendation classes: 0 to Healthy, 1 to Danger vs inverted.'),
                    value: _invertOutput,
                    onChanged: (val) {
                      setState(() => _invertOutput = val);
                      _saveSettings();
                    },
                    activeThumbColor: Colors.teal,
                  ),
                  SwitchListTile(
                    title: const Text('Permit OpenMeteo filling'),
                    subtitle: const Text('Allow matching missing local station weather points with Open-Meteo predictions.'),
                    value: _permitFill,
                    onChanged: (val) {
                      setState(() => _permitFill = val);
                      _saveSettings();
                    },
                    activeThumbColor: Colors.teal,
                  ),
                  SwitchListTile(
                    title: const Text('Always force inference'),
                    subtitle: const Text('Bypass checks on historical logs completeness to force RF recommendation execution.'),
                    value: _forceInference,
                    onChanged: (val) {
                      setState(() => _forceInference = val);
                      _saveSettings();
                    },
                    activeThumbColor: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location settings
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(locationProvider.notifier).updateFromGps();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Location updated successfully')),
                      );
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Refresh Location from GPS'),
                  ),
                  const SizedBox(height: 12), // Add spacing
                  
                  // ADD THE NEW OPENSTREETMAP BUTTON HERE
                  ElevatedButton.icon(
                    onPressed: () async {
                      // 1. Get current saved coordinates to center the map
                      final currentLoc = ref.read(locationProvider);
                      
                      // 2. Open the OSM Picker Dialog
                      final LatLng? newLocation = await showDialog<LatLng>(
                        context: context,
                        builder: (context) => MapPickerDialog(
                          initialLat: currentLoc.latitude,
                          initialLon: currentLoc.longitude,
                        ),
                      );

                      // 3. If user saved a location, update the state and DB
                      if (newLocation != null) {
                        ref.read(locationProvider.notifier).updateManual(
                          newLocation.latitude, 
                          newLocation.longitude
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Manual location saved! (${newLocation.latitude.toStringAsFixed(3)}, ${newLocation.longitude.toStringAsFixed(3)})')),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Pick manually from Map'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Database maintenance
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Maintenance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Purge Local Database'),
                          content: const Text(
                            'Warning: All historical records, weather information, and predictions will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                widget.db.clearAllData();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Database cleared successfully!'),
                                  ),
                                );
                              },
                              child: const Text('Clear Database'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear Database'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
