import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/schemas/soil_humidity_schema.dart';
import '../data/schemas/prediction_schema.dart';

class UnifiedChart extends StatelessWidget {
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final List<double> radiationForecast; // 24h hourly radiation

  const UnifiedChart({
    super.key,
    required this.history,
    required this.predictions,
    required this.radiationForecast,
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

    // Map radiation to FlSpot, offset after history
    final List<FlSpot> radiationSpots = [];
    for (int i = 0; i < radiationForecast.length; i++) {
      // Scale radiation to fit 0-100% y-axis.
      // A standard max is 1000 W/m², so we scale by dividing by 10.0
      final double scaledRad = (radiationForecast[i] / 10.0).clamp(0.0, 100.0);
      radiationSpots.add(FlSpot(historyOffset + i.toDouble(), scaledRad));
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Determine interval based on width
          int interval = 24;
          if (width > 600) {
            interval = 6;
          } else if (width > 400) {
            interval = 12;
          }

          return Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (LineBarSpot touchedSpot) =>
                            Colors.teal.shade900.withValues(alpha: 0.9),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final int diff =
                                spot.x.round() - historyOffset.toInt();
                            final time = DateTime.now().add(
                              Duration(hours: diff),
                            );
                            final hourStr =
                                '${time.hour.toString().padLeft(2, '0')}:00';

                            String valueSuffix = '';
                            final double value = spot.y;

                            if (spot.barIndex == 0) {
                              valueSuffix = '%';
                            } else if (spot.barIndex == 1) {
                              valueSuffix = '%';
                            } else if (spot.barIndex == 2) {
                              valueSuffix = ' x10 W/m²';
                            }

                            return LineTooltipItem(
                              '$hourStr\n${value.toStringAsFixed(1)}$valueSuffix',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          }).toList();
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
                            padding: const EdgeInsets.only(top: 8, right: 4),
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontSize: 9,
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
                            // ponytail: always allow index 0 (first value) on x-axis
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
                                  fontSize: 9,
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
                      // History Line (Solid Green)
                      LineChartBarData(
                        spots: historySpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                      // Predictions Line (Dashed Orange)
                      LineChartBarData(
                        spots: predSpots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2,
                        dashArray: [5, 5],
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange.withValues(alpha: 0.05),
                        ),
                      ),
                      // Radiation Line (Solid Amber)
                      if (radiationSpots.isNotEmpty)
                        LineChartBarData(
                          spots: radiationSpots,
                          isCurved: true,
                          color: Colors.amber.shade600,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.amber.shade600.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('Humidity %', Colors.green, isDashed: false),
                  _buildLegendItem(
                    'Prediction %',
                    Colors.orange,
                    isDashed: true,
                  ),
                  if (radiationSpots.isNotEmpty)
                    _buildLegendItem(
                      'Radiation x10 W/m²',
                      Colors.amber.shade600,
                      isDashed: false,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {required bool isDashed}) {
    // ponytail: simplified legend showing only indicator shape and label
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
