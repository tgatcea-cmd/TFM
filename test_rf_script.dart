import 'dart:math';
import 'package:tfm_app/features/ml_inference/random_forest.dart' as rf;
import 'package:tfm_app/features/weather/open_meteo_api.dart';

class SaviaLstmScaler {
  static const double hs30Mean = 0.7712527688624472;
  static const double hs30Std = 0.042382551037717174;
  static double scaleHs30(double val) => (val - hs30Mean) / hs30Std;
  
  static const double radSumMean = 4191.1622;
  static const double radSumStd = 1443.3734;
  static double scaleRadiation(double val) => (val - radSumMean) / radSumStd;
}

void main() async {
  double lat = 39.4699;
  double lon = -0.3763;
  DateTime refDate = DateTime(2026, 9, 17, 17, 11, 35);

  double minHs30 = 0.8272818780415077;
  double predHum = minHs30;
  
  print('=== Random Forest Inference Testing Environment ===');
  print('Input HS30 (Min): $predHum (82.7%)');
  print('Coordinates: ($lat, $lon)');
  print('Date: $refDate');
  print('----------------------------------------------------');
  
  final weatherClient = OpenMeteoClient(latitude: lat, longitude: lon);
  print('Fetching 48h weather forecast from Open-Meteo...');
  
  try {
    final weatherData = await weatherClient.fetchForecast(referenceDate: refDate);
    
    final targetStart = refDate.subtract(const Duration(hours: 24));
    final targetEnd = refDate.add(const Duration(hours: 24));
    double radSum = 0.0;
    
    for (int i = 0; i < weatherData.time.length; i++) {
      final t = weatherData.time[i];
      if (t.isAfter(targetStart) && t.isBefore(targetEnd.add(const Duration(seconds: 1)))) {
         radSum += weatherData.shortwaveRadiation[i];
      }
    }
          
    print('Calculated 48h Shortwave Radiation Sum [D1 + D2]: $radSum W/m²');

    final double rawHum = predHum;
    final double normalizedPredHum = rawHum > 1.0 ? rawHum / 100.0 : rawHum;
    final double scaledPredHum = SaviaLstmScaler.scaleHs30(normalizedPredHum);

    double normalizedRad = SaviaLstmScaler.scaleRadiation(radSum);

    print('Raw predHum Input: $predHum | Normalized: $normalizedPredHum | Scaled (HS30): $scaledPredHum');
    print('Raw 48h Radiation Sum Input: $radSum W/m² | Scaled (Z-Score): $normalizedRad');
    
    List<double> probs = rf.score([normalizedRad, scaledPredHum]);
    
    print('RF Model Score Input: [$normalizedRad, $scaledPredHum] -> Output Probs: $probs');
    
    int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;
    
    final verdictStr = resultClass == 1
          ? 'IRRIGATION AVOIDABLE: Soil moisture stable. (Class 1)'
          : 'IRRIGATION NEEDED: Soil moisture low. IRRIGATE to restore. (Class 0)';
          
    print('Final Verdict: $verdictStr');
  } catch (e) {
    print('Error executing test: $e');
  }
}
