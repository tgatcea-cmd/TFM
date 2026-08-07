import 'package:flutter_test/flutter_test.dart';
import 'package:tfm_app/features/ml_inference/inference_engine.dart';
import 'package:tfm_app/features/ml_inference/lstm_inference.dart';
import 'package:tfm_app/core/database/app_database.dart';
import 'package:tfm_app/core/models/app_settings.dart';
import 'package:tfm_app/core/models/app_rf_model.dart';

class FakeDatabaseService implements DatabaseService {
  RfModel? activeRfModel;
  AppSettings settings = AppSettings();

  @override
  RfModel? getActiveRfModel() => activeRfModel;

  @override
  AppSettings getAppSettings() => settings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SaviaLstmScaler Unit Tests', () {
    test('Correctly scales and unscales HS30 soil moisture values', () {
      const rawVwc = 0.7712527688624472; // Mean
      final scaledMean = SaviaLstmScaler.scaleHs30(rawVwc);
      expect(scaledMean, closeTo(0.0, 0.001));

      final unscaledMean = SaviaLstmScaler.unscaleHs30(scaledMean);
      expect(unscaledMean, closeTo(rawVwc, 0.001));

      // Low moisture (0.15 VWC / 15%)
      final scaledLow = SaviaLstmScaler.scaleHs30(0.15);
      expect(scaledLow, lessThan(-10.0));
    });
  });

  group('InferenceBridge.evaluateRecommendation Unit Tests', () {
    late FakeDatabaseService fakeDb;
    late InferenceBridge bridge;

    setUp(() {
      fakeDb = FakeDatabaseService();
      bridge = InferenceBridge(fakeDb);
    });

    test('Case 1: Normal Soil Moisture (77%) & Moderate Radiation -> IRRIGATION AVOIDABLE', () {
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.77,
      );

      expect(res['verdict'], contains('Irrigation Avoidable'));
      expect(res['recommendation'], contains('IRRIGATION AVOIDABLE'));
      expect(res['minHumidity'], closeTo(0.77, 0.001));
    });

    test('Case 2: High Healthy Soil Moisture (79%) & High Radiation -> IRRIGATION AVOIDABLE', () {
      final res = bridge.evaluateRecommendation(
        radSum: 500.0,
        predHum: 0.79,
      );

      expect(res['verdict'], contains('Irrigation Avoidable'));
      expect(res['recommendation'], contains('IRRIGATION AVOIDABLE'));
      expect(res['minHumidity'], closeTo(0.79, 0.001));
    });

    test('Case 3: Low Soil Moisture (15%) & Moderate Radiation -> IRRIGATION NEEDED', () {
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.15,
      );

      expect(res['verdict'], contains('Irrigation Needed'));
      expect(res['recommendation'], contains('IRRIGATION NEEDED'));
      expect(res['minHumidity'], closeTo(0.15, 0.001));
    });

    test('Case 4: Percentage Input Formatting (77.0%) -> Converts to fraction 0.77 & IRRIGATION AVOIDABLE', () {
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 77.0, // Handled as percentage
      );

      expect(res['verdict'], contains('Irrigation Avoidable'));
      expect(res['minHumidity'], closeTo(0.77, 0.001));
    });

    test('Case 5: Debug Low Moisture Injection ON -> Forces 15% VWC & IRRIGATION NEEDED', () {
      bridge.injectLowMoisture = true;
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.80, // High input moisture, but injected flag is ON
      );

      expect(res['verdict'], contains('Irrigation Needed'));
      expect(res['recommendation'], contains('IRRIGATION NEEDED'));
      expect(res['minHumidity'], closeTo(0.15, 0.001));
    });

    test('Case 6: Debug Low Moisture Injection OFF -> Evaluates real high moisture -> IRRIGATION AVOIDABLE', () {
      bridge.injectLowMoisture = false;
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.77,
      );

      expect(res['verdict'], contains('Irrigation Avoidable'));
      expect(res['minHumidity'], closeTo(0.77, 0.001));
    });

    test('Case 7: Invert Model Output Flag -> Flips Irrigation Avoidable to Irrigation Needed', () {
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.77,
        invertModelOutput: true,
      );

      expect(res['verdict'], contains('Irrigation Needed'));
      expect(res['recommendation'], contains('IRRIGATION NEEDED'));
    });

    test('Case 8: RefDate Night Hour Evaluation -> Flags as Unrecommended Yellow Zone', () {
      final nightTime = DateTime(2026, 8, 7, 20, 0); // 20:00 (inside 19-10 night window)
      final res = bridge.evaluateRecommendation(
        radSum: 300.0,
        predHum: 0.77,
        refDate: nightTime,
      );

      expect(res['isUnrecommended'], isTrue);
      expect(res['agronomicStart'], equals(19));
      expect(res['agronomicEnd'], equals(10));
    });
  });
}
