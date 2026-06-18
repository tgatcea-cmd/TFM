import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/database_service.dart';
import '../../core/ble/ble_service.dart';
import '../../main.dart';
import '../../ui/styles.dart';
import '../../ui/unified_chart.dart';
import 'sync_progress_dialog.dart';

class TelemetryView extends ConsumerStatefulWidget {
  const TelemetryView({super.key});

  @override
  ConsumerState<TelemetryView> createState() => _TelemetryViewState();
}

class _TelemetryViewState extends ConsumerState<TelemetryView> {

  Future<void> _connectToDevice(
    BuildContext context,
    DisplayDevice device,
  ) async {
    final bleService = ref.read(bleServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    BluetoothDevice? targetDevice;
    if (device.scanResult != null) {
      targetDevice = device.scanResult!.device;
    } else {
      for (final d in bleService.cachedDevices) {
        if (d.device.remoteId.toString() == device.id) {
          targetDevice = d.device;
          break;
        }
      }
    }

    if (targetDevice != null) {
      // Show progress bars overlay dialog
      SyncProgressDialog.show(context);
      
      // Start connection/pairing/refresh sequence
      await ref
          .read(connectionSyncProgressProvider.notifier)
          .startSequence(targetDevice);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 600),
          content: Text('Device ${device.name} is offline or out of range'),
        ),
      );
    }
  }

  void _showDeviceMenu(BuildContext context) {
    ref.read(bleServiceProvider).startScan();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final devices = ref.watch(mergedDevicesProvider);
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Device Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Scanning for nearby devices...'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final r = devices[index];
                          return ListTile(
                            leading: Icon(
                              r.rssi == -100 ? Icons.bluetooth_disabled : Icons.bluetooth,
                              color: r.rssi == -100 ? Colors.grey : Colors.teal,
                            ),
                            title: Text(r.name),
                            subtitle: Text(r.rssi == -100 ? 'Offline' : '${r.rssi} dBm'),
                            trailing: IconButton(
                              icon: Icon(
                                r.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: r.isSaved ? Colors.teal : null,
                              ),
                              onPressed: () {
                                final db = ref.read(dbProvider);
                                if (r.isSaved) {
                                  db.deleteDevice(r.id);
                                } else {
                                  db.saveDevice(r.id, r.name);
                                }
                                ref.read(savedDevicesTriggerProvider.notifier).state++;
                              },
                            ),
                            onTap: () {
                              _connectToDevice(context, r);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(bleConnectedProvider);
    final db = ref.watch(dbProvider);
    final weather = ref.watch(weatherProvider);
    final bleService = ref.watch(bleServiceProvider);

    if (!isConnected) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => _showDeviceMenu(context),
          icon: const Icon(Icons.search),
          label: const Text('Check for IoT Station'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final predictions = db.getPredictionHistory();
    final lastRec = predictions.isNotEmpty ? predictions.last.recommendation : 'None';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeviceMenu(context),
        icon: const Icon(Icons.bluetooth),
        label: Text(bleService.connectedDevice?.platformName ?? "Cesar IoT Station"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (ref.read(bleServiceProvider).isConnected) {
            SyncProgressDialog.show(context);
            await ref.read(connectionSyncProgressProvider.notifier).startRefreshOnly();
          } else {
            await ref.read(weatherProvider.notifier).refresh();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: lastRec.contains('SATURATION')
                            ? AppStyles.dangerRedBg(context)
                            : AppStyles.bgTealLight(context),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        border: Border.all(
                          color: lastRec.contains('SATURATION')
                              ? AppStyles.dangerRedBorder(context)
                              : AppStyles.borderTealLight(context),
                        ),
                      ),
                      child: Text(
                        lastRec.contains('SATURATION')
                            ? 'Overwatering risk | Irrigation not recommended'
                            : 'Follow usual irrigation schedule',
                        style: lastRec.contains('SATURATION')
                            ? AppStyles.recDangerStyle(context)
                            : AppStyles.recSafeStyle(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildUnifiedChart(db, weather, isConnected),
              const SizedBox(height: 16),
              _buildHistoryTableView(db),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTableView(DatabaseService db) {
    final history = db.getSoilHumidityHistory();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Telemetry History Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        if (history.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Text('No database entries found.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[history.length - 1 - index];
              final time = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
              final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              final dateStr = '${time.year}-${time.month}-${time.day}';
              return ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: Text('Soil Humidity: ${item.value.toStringAsFixed(2)}%'),
                subtitle: Text('$dateStr @ $timeStr'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUnifiedChart(DatabaseService db, WeatherState weather, bool isConnected) {
    return UnifiedChart(
      history: isConnected ? db.getSoilHumidityHistory() : [],
      predictions: isConnected ? db.getPredictionHistory() : [],
      radiationForecast: isConnected ? weather.hourlyRadiationForecast : [],
      weatherHistory: isConnected ? db.getWeatherHistory() : [],
    );
  }
}
