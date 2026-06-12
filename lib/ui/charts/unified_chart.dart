import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:signals/signals_flutter.dart';
import '../../logic/dashboard_signals.dart';
import '../../data/schemas/soil_humidity_schema.dart';
import '../../data/schemas/weather_schema.dart';
import '../../data/schemas/prediction_schema.dart';

class UnifiedAnalyticalChart extends StatelessWidget {
  final DashboardSignals signals;

  const UnifiedAnalyticalChart({super.key, required this.signals});

  @override
  Widget build(BuildContext context) {
    final humidity = signals.humidityHistory.watch(context);
    final weather = signals.weatherHistory.watch(context);
    final predictions = signals.predictionHistory.watch(context);

    if (humidity.isEmpty && predictions.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No historical data available for charting.')),
      );
    }

    final now = DateTime.now();

    // 1. Prepare Historical Data (-48h to 0)
    final sortedHum = List<SoilHumidityRecord>.from(humidity)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final humiditySpots = sortedHum.map((e) {
      final x = (e.timestamp - now.millisecondsSinceEpoch) / (1000 * 3600); 
      return FlSpot(x.toDouble(), e.value);
    }).toList();

    // 2. Prepare Future Predictions (0 to +24h)
    final sortedPred = List<PredictionRecord>.from(predictions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final predictionSpots = sortedPred.map((e) {
      final x = (e.timestamp - now.millisecondsSinceEpoch) / (1000 * 3600);
      return FlSpot(x.toDouble(), e.predictedHumidity);
    }).toList();

    // 3. Radiation Gradient (Intuitive colors)
    final List<Color> gradientColors = [];
    final List<double> stops = [];
    
    if (weather.isNotEmpty) {
      final sortedWeather = List<WeatherRecord>.from(weather)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
      const minTime = -48.0;
      const maxTime = 24.0;
      const totalRange = maxTime - minTime;

      for (var w in sortedWeather) {
        final x = (w.timestamp - now.millisecondsSinceEpoch) / (1000 * 3600);
        if (x >= minTime && x <= maxTime) {
          final stop = (x - minTime) / totalRange;
          gradientColors.add(_getRadiationColor(w.radiation));
          stops.add(stop);
        }
      }
    }

    if (gradientColors.length < 2) {
      gradientColors.addAll([Colors.blue, Colors.blue]);
      stops.addAll([0.0, 1.0]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Solid: 48h History | Dashed: 24h Prediction', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Line Color: Solar intensity (Indigo: Night → Red: Peak)', 
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.symmetric(horizontal: 50),
            minScale: 1.0,
            maxScale: 5.0,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, left: 10, top: 10, bottom: 10),
              child: LineChart(
                LineChartData(
                  minX: -48,
                  maxX: 24,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // History Line (Solid)
                    LineChartBarData(
                      spots: humiditySpots,
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors, stops: stops),
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
                          stops: stops,
                        ),
                      ),
                    ),
                    // Prediction Line (Dashed)
                    LineChartBarData(
                      spots: predictionSpots,
                      isCurved: true,
                      color: Colors.blue.withOpacity(0.5),
                      barWidth: 3,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: 12,
                        getTitlesWidget: (value, meta) {
                          // Calculate dynamic absolute date/time
                          final timeAtValue = now.add(Duration(minutes: (value * 60).toInt()));
                          final String dayMonth = '${timeAtValue.day}/${timeAtValue.month.toString().padLeft(2, '0')}';
                          final String hoursLabel = '${timeAtValue.hour}h';
                          
                          String subLabel = '';
                          if (value.toInt() == 0) subLabel = '(today)';
                          else if (value.toInt() == 24) subLabel = '(tomorrow)';

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(dayMonth, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                                Text(hoursLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                if (subLabel.isNotEmpty)
                                  Text(subLabel, style: const TextStyle(fontSize: 8, color: Colors.blue)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    verticalInterval: 12,
                    getDrawingVerticalLine: (value) => FlLine(
                      color: value == 0 ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.1),
                      strokeWidth: value == 0 ? 2 : 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRadiationColor(double rad) {
    if (rad < 100) return Colors.indigo; // Night
    if (rad < 300) return Colors.blueGrey; // Dawn/Dusk
    if (rad < 500) return Colors.teal; // Morning
    if (rad < 700) return Colors.orange; // High Sun
    return Colors.redAccent; // Peak Sun
  }
}
