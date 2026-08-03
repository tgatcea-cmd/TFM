import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/screens/home_screen.dart';
import 'package:tfm_app/screens/nearby_screen.dart';
import 'package:tfm_app/screens/config_screen.dart';
import 'package:tfm_app/screens/local_db_screen.dart';
import 'package:tfm_app/screens/cloud_screen.dart';

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
  bool _isStatusVisible = true;

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
                // Togglable Global Status Bar
                if (_isStatusVisible)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spaceMD,
                      vertical: AppStyles.spaceXS,
                    ),
                    color: AppStyles.surfaceColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'STATUS: $_statusMsg',
                            style: AppStyles.captionStatus.copyWith(
                              color: AppStyles.successAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isStatusVisible = false),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down, size: 16, color: AppStyles.textMuted),
                                SizedBox(width: 2),
                                Text('Hide', style: AppStyles.captionStatus),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppStyles.spaceSM, bottom: 2.0),
                      child: InkWell(
                        onTap: () => setState(() => _isStatusVisible = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppStyles.surfaceColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            border: Border.all(color: AppStyles.dividerColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up, size: 14, color: AppStyles.successAccent),
                              SizedBox(width: 4),
                              Text('Status', style: AppStyles.captionStatus),
                            ],
                          ),
                        ),
                      ),
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
