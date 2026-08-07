import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tfm_app/cli_routines.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/core/utils/l10n/app_localizations.dart';
import 'package:tfm_app/screens/home_screen.dart';
import 'package:tfm_app/screens/nearby_screen.dart';
import 'package:tfm_app/screens/config_screen.dart';
import 'package:tfm_app/screens/storage_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final routines = CliRoutines();
  await routines.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppStyles.darkTheme, 
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
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
  late String _statusMsg = AppLocalizations.of(context)!.mainStatusReady;
  bool _isStatusVisible = true;

  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _connSub = widget.routines.bleService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _statusMsg = isConnected 
              ? AppLocalizations.of(context)!.mainStatusBleConnected 
              : AppLocalizations.of(context)!.mainStatusBleDisconnected;
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
    final screens = kIsWeb
        ? [
            StorageScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {}),
            ConfigScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {}),
          ]
        : [
            HomeScreen(routines: widget.routines, onStatusChange: _setStatus),
            NearbyScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {}),
            StorageScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {}),
            ConfigScreen(routines: widget.routines, onStatusChange: _setStatus, onBack: () {}),
          ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }
    return screens[_selectedIndex];
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(child: _buildCurrentScreen()),
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
                    AppLocalizations.of(context)!.statusLabel(_statusMsg),
                    style: AppStyles.captionStatus.copyWith(
                      color: AppStyles.successAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isStatusVisible = false),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: AppStyles.textMuted),
                        const SizedBox(width: 2),
                        Text(AppLocalizations.of(context)!.hide, style: AppStyles.captionStatus),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_arrow_up, size: 14, color: AppStyles.successAccent),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context)!.status, style: AppStyles.captionStatus),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    // We reuse 'localDbTab' localization key for the unified storage view, or you can update app_en.arb later.
    return Scaffold(
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: kIsWeb
                        ? [
                            NavigationRailDestination(icon: const Icon(Icons.storage), label: Text(AppLocalizations.of(context)?.localDbTab ?? 'Storage')),
                            NavigationRailDestination(icon: const Icon(Icons.settings), label: Text(AppLocalizations.of(context)?.configTab ?? 'Config')),
                          ]
                        : [
                            NavigationRailDestination(icon: const Icon(Icons.dashboard), label: Text(AppLocalizations.of(context)?.homeTab ?? 'Home')),
                            NavigationRailDestination(icon: const Icon(Icons.bluetooth_searching), label: Text(AppLocalizations.of(context)?.nearbyTab ?? 'Nearby')),
                            NavigationRailDestination(icon: const Icon(Icons.storage), label: Text(AppLocalizations.of(context)?.localDbTab ?? 'Storage')),
                            NavigationRailDestination(icon: const Icon(Icons.settings), label: Text(AppLocalizations.of(context)?.configTab ?? 'Config')),
                          ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: _buildMainContent()),
                ],
              )
            : _buildMainContent(),
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppStyles.surfaceColor,
              selectedItemColor: AppStyles.successAccent,
              unselectedItemColor: AppStyles.textMuted,
              items: kIsWeb
                  ? [
                      BottomNavigationBarItem(icon: const Icon(Icons.storage), label: AppLocalizations.of(context)?.localDbTab ?? 'Storage'),
                      BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppLocalizations.of(context)?.configTab ?? 'Config'),
                    ]
                  : [
                      BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: AppLocalizations.of(context)?.homeTab ?? 'Home'),
                      BottomNavigationBarItem(icon: const Icon(Icons.bluetooth_searching), label: AppLocalizations.of(context)?.nearbyTab ?? 'Nearby'),
                      BottomNavigationBarItem(icon: const Icon(Icons.storage), label: AppLocalizations.of(context)?.localDbTab ?? 'Storage'),
                      BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppLocalizations.of(context)?.configTab ?? 'Config'),
                    ],
            )
          : null,
    );
  }
}