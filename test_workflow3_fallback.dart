import 'dart:io';
import 'dart:math';

class HistoricalSolarModel {
  static double estimateRadSum({required double lat, required DateTime date}) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final declination = 23.45 * sin((284 + dayOfYear) * 360 / 365 * 3.14159 / 180);
    final latRad = lat * 3.14159 / 180;
    final decRad = declination * 3.14159 / 180;
    final cosZenith = max(0.2, cos(latRad) * cos(decRad) + sin(latRad) * sin(decRad));
    return 48.0 * 180.0 * cosZenith;
  }
}

void main() async {
  print('=== Workflow 3: Fallback Robustness Validation ===');
  final outFile = File('workflow3_solar_fallback.csv');
  final sink = outFile.openWrite();
  sink.writeln('DayOfYear,Date,Estimated_RadSum_W_m2');

  double lat = 39.4699; // Valencia latitude
  int year = 2026;

  for (int day = 1; day <= 365; day++) {
    DateTime date = DateTime(year, 1, 1).add(Duration(days: day - 1));
    double estimatedRad = HistoricalSolarModel.estimateRadSum(lat: lat, date: date);
    sink.writeln('$day,${date.toIso8601String().split('T')[0]},${estimatedRad.toStringAsFixed(2)}');
  }

  await sink.close();
  print('Generated 365 days of astronomical clear-sky radiation estimates for Lat: $lat');
  print('Data saved to workflow3_solar_fallback.csv');
}
