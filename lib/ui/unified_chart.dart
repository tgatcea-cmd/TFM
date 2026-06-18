import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/models.dart';
import 'styles.dart';

// ponytail: Simplified chart style utilizing only the shared AppStyles stylesheet

class UnifiedChart extends StatelessWidget {
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final List<double> radiationForecast; // 24h hourly radiation
  final List<WeatherRecord> weatherHistory; // 48h weather history

  const UnifiedChart({
    super.key,
    required this.history,
    required this.predictions,
    required this.radiationForecast,
    required this.weatherHistory,
  });

  @override
  Widget build(BuildContext context) {
    // Sort and take latest 48 historical points
    final sortedHistory = List<SoilHumidityRecord>.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final displayHistory = sortedHistory.length > 48
        ? sortedHistory.sublist(sortedHistory.length - 48)
        : sortedHistory;

    // Sort and take latest 24 prediction points
    final sortedPreds = List<PredictionRecord>.from(predictions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final displayPreds = sortedPreds.length > 24
        ? sortedPreds.sublist(sortedPreds.length - 24)
        : sortedPreds;

    final double historyOffset = displayHistory.isNotEmpty
        ? displayHistory.length - 1.0
        : 0.0;

    // Map history to FlSpot
    final List<FlSpot> historySpots = [];
    for (int i = 0; i < displayHistory.length; i++) {
      historySpots.add(FlSpot(i.toDouble(), displayHistory[i].value));
    }

    // Map predictions to FlSpot, offset after history
    final List<FlSpot> predSpots = [];
    for (int i = 0; i < displayPreds.length; i++) {
      predSpots.add(
        FlSpot(historyOffset + i.toDouble(), displayPreds[i].predictedHumidity),
      );
    }

    // Map radiation forecast to FlSpot, offset after history
    final List<FlSpot> radiationSpots = [];
    for (int i = 0; i < radiationForecast.length; i++) {
      // Scale radiation to fit 0-100% y-axis.
      // A standard max is 1000 W/m², so we scale by dividing by 10.0
      final double scaledRad = (radiationForecast[i] / 10.0).clamp(0.0, 100.0);
      radiationSpots.add(FlSpot(historyOffset + i.toDouble(), scaledRad));
    }

    // Map past radiation to FlSpot, aligned with history by timestamp
    final List<FlSpot> pastRadiationSpots = [];
    for (int i = 0; i < displayHistory.length; i++) {
      final ts = displayHistory[i].timestamp;
      final closestWeather = weatherHistory.where(
        (w) => (w.timestamp - ts).abs() < 1800000,
      );
      if (closestWeather.isNotEmpty) {
        final rad = closestWeather.first.radiation;
        final double scaledRad = (rad / 10.0).clamp(0.0, 100.0);
        pastRadiationSpots.add(FlSpot(i.toDouble(), scaledRad));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int interval = 24;
        if (width > 600) {
          interval = 6;
        } else if (width > 400) {
          interval = 12;
        }

        // ponytail: Scrollable chart container preventing overflow on smaller mobile screens
        return Column(
          children: [
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width < 600 ? 800 : width,
                  child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot touchedSpot) =>
                          AppStyles.darkSlate.withValues(alpha: 0.9),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        if (touchedSpots.isEmpty) return [];

                        // Group all data points under a single hour display header
                        final spot = touchedSpots.first;
                        final int diff = spot.x.round() - historyOffset.toInt();
                        final time = DateTime.now().add(Duration(hours: diff));
                        final hourStr =
                            '${time.hour.toString().padLeft(2, '0')}:00';

                        final List<String> lines = [hourStr];
                        for (var s in touchedSpots) {
                          final double value = s.y;
                          // Match lines based on spot y value characteristics or s.barIndex
                          if (s.barIndex == 0) {
                            lines.add('Humidity: ${value.toStringAsFixed(1)}%');
                          } else if (s.barIndex == 1) {
                            lines.add(
                              'Past Rad: ${(value * 10.0).toStringAsFixed(0)} W/m²',
                            );
                          } else if (s.barIndex == 2) {
                            lines.add(
                              'Prediction: ${value.toStringAsFixed(1)}%',
                            );
                          } else if (s.barIndex == 3) {
                            lines.add(
                              'Rad. Forecast: ${(value * 10.0).toStringAsFixed(0)} W/m²',
                            );
                          }
                        }

                        return [
                          LineTooltipItem(
                            lines.join('\n'),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          // Return empty/null tooltips for remaining spots to display only one box
                          ...List.filled(touchedSpots.length - 1, null),
                        ];
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      VerticalLine(
                        x: historyOffset,
                        color: Colors.teal.shade700,
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (line) => 'Now',
                        ),
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1.0,
                        getTitlesWidget: (value, meta) {
                          final double rounded = value.roundToDouble();
                          if ((value - rounded).abs() > 0.05) {
                            return const SizedBox.shrink();
                          }
                          final int intVal = rounded.toInt();
                          final int diff = intVal - historyOffset.toInt();
                          // always allow index 0 (first value) on x-axis
                          if (intVal != 0 && diff % interval != 0) {
                            return const SizedBox.shrink();
                          }
                          final time = DateTime.now().add(
                            Duration(hours: diff),
                          );
                          final hourStr =
                              '${time.hour.toString().padLeft(2, '0')}:00';
                          final String label;
                          if (diff == 0) {
                            label = width > 350 ? '$hourStr (Now)' : hourStr;
                          } else {
                            label = hourStr;
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: diff == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: diff == 0
                                    ? Colors.teal.shade900
                                    : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    // 0: History Line (Solid Green)
                    if (historySpots.isNotEmpty)
                      LineChartBarData(
                        spots: historySpots,
                        isCurved: true,
                        color: AppStyles.primaryTeal,
                        barWidth: 3.0,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppStyles.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                    // 1: Past Radiation Line (Dashed Red)
                    if (pastRadiationSpots.isNotEmpty)
                      LineChartBarData(
                        spots: pastRadiationSpots,
                        isCurved: true,
                        color: AppStyles.dangerRed,
                        barWidth: 2.0,
                        dashArray: const [4, 4],
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppStyles.dangerRed.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                    // 2: Predictions Line (Dashed Orange)
                    if (predSpots.isNotEmpty)
                      LineChartBarData(
                        spots: predSpots,
                        isCurved: true,
                        color: AppStyles.accentOrange,
                        barWidth: 2.0,
                        dashArray: const [5, 5],
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppStyles.accentOrange.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                    // 3: Radiation Line (Solid Amber)
                    if (radiationSpots.isNotEmpty)
                      LineChartBarData(
                        spots: radiationSpots,
                        isCurved: true,
                        color: AppStyles.accentOrange,
                        barWidth: 2.0,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppStyles.accentOrange.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                'Humidity %',
                AppStyles.primaryTeal,
                isDashed: false,
              ),
              _buildLegendItem(
                'Past Radiation W/m²',
                AppStyles.dangerRed,
                isDashed: true,
              ),
              _buildLegendItem(
                'Prediction %',
                AppStyles.accentOrange,
                isDashed: true,
              ),
              _buildLegendItem(
                'Radiation Forecast W/m²',
                AppStyles.accentOrange,
                isDashed: false,
              ),
            ],
          ),
        ],
      );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          Row(
            children: [
              Container(width: 5, height: 3, color: color),
              const SizedBox(width: 2),
              Container(width: 5, height: 3, color: color),
            ],
          )
        else
          Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
