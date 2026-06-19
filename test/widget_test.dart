import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tfm_app/main.dart';
import 'package:tfm_app/core/ble/ble_service.dart';

class FakeBleService implements BleService {
  @override
  final Stream<Object> dataStream = const Stream.empty();

  @override
  final Stream<bool> connectionStateStream = Stream.value(false);

  @override
  final Stream<List<ScanResult>> scanResults = Stream.value([]);

  @override
  bool get isConnected => false;

  @override
  BluetoothDevice? get connectedDevice => null;

  @override
  List<ScanResult> get cachedDevices => [];

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App dashboard load smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope with BleService overridden and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleServiceProvider.overrideWithValue(FakeBleService()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the "Check for IoT Station" button is displayed since we are not connected.
    expect(find.text('Check for IoT Station'), findsOneWidget);
  });
}
