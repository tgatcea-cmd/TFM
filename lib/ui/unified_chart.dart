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
    final double nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    const double msPerHour = 3600000.0;

    // 1. Map history to FlSpot (Time-based X-axis)
    final List<FlSpot> historySpots = history
        .map((r) => FlSpot((r.timestamp - nowMs) / msPerHour, r.value))
        .where((s) => s.x >= -48.0 && s.x <= 0.0) // Limit to past 48h
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // 2. Map predictions to FlSpot
    final List<FlSpot> predSpots = predictions
        .map((r) => FlSpot((r.timestamp - nowMs) / msPerHour, r.predictedHumidity))
        .where((s) => s.x >= 0.0 && s.x <= 24.0) // Limit to next 24h
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // 3. Map past radiation to FlSpot (Independent of history!)
    final List<FlSpot> pastRadiationSpots = weatherHistory
        .map((w) {
          final double scaledRad = (w.radiation / 10.0).clamp(0.0, 100.0);
          return FlSpot((w.timestamp - nowMs) / msPerHour, scaledRad);
        })
        .where((s) => s.x >= -48.0 && s.x <= 0.0)
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // 4. Map radiation forecast to FlSpot
    final List<FlSpot> radiationSpots = [];
    for (int i = 0; i < radiationForecast.length; i++) {
      if (i > 24) break;
      final double scaledRad = (radiationForecast[i] / 10.0).clamp(0.0, 100.0);
      radiationSpots.add(FlSpot(i.toDouble(), scaledRad)); // i is hours in future
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
                      // We no longer strictly need minX/maxX, FlChart handles it based on spots, 
                      // but setting them explicitly prevents jumping when data is empty
                      minX: -48,
                      maxX: 24,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (LineBarSpot touchedSpot) =>
                              AppStyles.darkSlate(context).withValues(alpha: 0.9),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            if (touchedSpots.isEmpty) return [];

                            final spot = touchedSpots.first;
                            final int diff = spot.x.round(); // Hours relative to now
                            final time = DateTime.now().add(Duration(hours: diff));
                            final hourStr = '${time.hour.toString().padLeft(2, '0')}:00';

                            final List<String> lines = [
                              diff < 0 ? '$hourStr (${diff.abs()}h ago)' : 
                              diff == 0 ? '$hourStr (Now)' : '$hourStr (In ${diff}h)'
                            ];

                            for (var s in touchedSpots) {
                              final double value = s.y;
                              final color = s.bar.color;
                              final isDashed = s.bar.dashArray != null;
                              
                              if (color == AppStyles.primaryTeal(context)) {
                                lines.add('Humidity: ${value.toStringAsFixed(1)}%');
                              } else if (color == AppStyles.dangerRed(context)) {
                                lines.add('Past Rad: ${(value * 10.0).toStringAsFixed(0)} W/m²');
                              } else if (color == AppStyles.accentOrange(context)) {
                                if (isDashed) {
                                  lines.add('Prediction: ${value.toStringAsFixed(1)}%');
                                } else {
                                  lines.add('Rad. Forecast: ${(value * 10.0).toStringAsFixed(0)} W/m²');
                                }
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
                            x: 0.0, // NOW is exactly 0
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
                              
                              final int diff = rounded.toInt();
                              
                              // Check standard interval logic
                              if (diff != 0 && diff % interval != 0) {
                                return const SizedBox.shrink();
                              }
                              
                              final time = DateTime.now().add(Duration(hours: diff));
                              final hourStr = '${time.hour.toString().padLeft(2, '0')}:00';
                              
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
                            color: AppStyles.primaryTeal(context),
                            barWidth: 3.0,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppStyles.primaryTeal(context).withValues(alpha: 0.1),
                            ),
                          ),
                        // 1: Past Radiation Line (Dashed Red)
                        if (pastRadiationSpots.isNotEmpty)
                          LineChartBarData(
                            spots: pastRadiationSpots,
                            isCurved: true,
                            color: AppStyles.dangerRed(context),
                            barWidth: 2.0,
                            dashArray: const [4, 4],
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppStyles.dangerRed(context).withValues(alpha: 0.05),
                            ),
                          ),
                        // 2: Predictions Line (Dashed Orange)
                        if (predSpots.isNotEmpty)
                          LineChartBarData(
                            spots: predSpots,
                            isCurved: true,
                            color: AppStyles.accentOrange(context),
                            barWidth: 2.0,
                            dashArray: const [5, 5],
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppStyles.accentOrange(context).withValues(alpha: 0.05),
                            ),
                          ),
                        // 3: Radiation Line (Solid Amber)
                        if (radiationSpots.isNotEmpty)
                          LineChartBarData(
                            spots: radiationSpots,
                            isCurved: true,
                            color: AppStyles.accentOrange(context),
                            barWidth: 2.0,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppStyles.accentOrange(context).withValues(alpha: 0.08),
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
                  AppStyles.primaryTeal(context),
                  isDashed: false,
                ),
                _buildLegendItem(
                  'Past Radiation W/m²',
                  AppStyles.dangerRed(context),
                  isDashed: true,
                ),
                _buildLegendItem(
                  'Prediction %',
                  AppStyles.accentOrange(context),
                  isDashed: true,
                ),
                _buildLegendItem(
                  'Radiation Forecast W/m²',
                  AppStyles.accentOrange(context),
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