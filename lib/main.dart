import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/screens/home_screen.dart';
import 'package:tfm_app/screens/nearby_screen.dart';
import 'package:tfm_app/screens/config_screen.dart';
import 'package:tfm_app/screens/cloud_screen.dart';
import 'package:tfm_app/screens/local_db_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final routines = CliRoutines();
  await routines.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppStyles.darkTheme, // Apply the centralized theme here
      home: DashboardShell(routines: routines),
    ),
  );
}

class DashboardShell extends StatefulWidget {
  final CliRoutines routines;
  const DashboardShell({super.key, required this.routines});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}


class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  String _statusMsg = 'Ready';

  // Listeners for BLE state, just like your CLI
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _connSub = widget.routines.bleService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _statusMsg = isConnected ? 'BLE Connected' : 'BLE Disconnected';
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMsg = msg);
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(routines: widget.routines, onStatusChange: _setStatus);
      case 1:
        return NearbyScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {  },);
      case 2:
        return LocalDbScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {  },);
      case 3:
        return CloudScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {  },);
      case 4:
        return ConfigScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {  },);
      default:
        return const Center(child: Text("Unknown Screen"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // The visual replacement for your Global Keystrokes
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.bluetooth_searching), label: Text('Nearby')),
              NavigationRailDestination(icon: Icon(Icons.storage), label: Text('Local DB')),
              NavigationRailDestination(icon: Icon(Icons.cloud_sync), label: Text('Cloud')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Config')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildCurrentScreen()),
                // Global Status Bar replacing the cyan text block[cite: 1]
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    'STATUS: $_statusMsg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
