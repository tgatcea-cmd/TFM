import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tfm_app/core/models/chart_data_point.dart';

/// A highly customizable, interactive time-series line chart designed to display 
/// both historical data and future forecasts. 
/// 
/// It automatically handles:
/// - Panning interactions via raw Pointer events.
/// - Dynamic Y-axis scaling based on dataset bounds.
/// - Background zone coloring based on Gathering vs Forecasting stages.
/// - Seamless truncation of timestamps to perfectly align data on the hour.
class TimeMetricChart extends StatefulWidget {
  /// The display title of the chart.
  final String title;
  
  /// The unit of measurement for the chart's data.
  final String unit;
  
  /// A list of historical data points to plot on the chart.
  final List<ChartDataPoint> history;
  
  /// A list of forecasted data points to plot on the chart.
  final List<ChartDataPoint> forecast;
  
  /// The color used to stroke the historical data line.
  final Color historyColor;
  
  /// The color used to stroke the forecasted data line (often styled as dashed).
  final Color forecastColor;
  
  /// An optional fixed minimum value for the Y-axis. If null, calculated dynamically.
  final double? minY;
  
  /// An optional fixed maximum value for the Y-axis. If null, calculated dynamically.
  final double? maxY;
  
  /// The hour of the day (0-23) when the forecasting zone typically begins.
  final int forecastZoneStartHour;
  
  /// The hour of the day (0-23) when the forecasting zone typically ends.
  final int forecastZoneEndHour;
  
  /// An optional offset in hours applied to the current time, useful for testing or simulation.
  final int timeOffsetHours;

  const TimeMetricChart({
    super.key,
    required this.title,
    required this.unit,
    required this.history,
    required this.forecast,
    required this.historyColor,
    required this.forecastColor,
    this.minY,
    this.maxY,
    this.forecastZoneStartHour = 19,
    this.forecastZoneEndHour = 9,
    this.timeOffsetHours = 0,
  });

  @override
  State<TimeMetricChart> createState() => _TimeMetricChartState();
}

class _TimeMetricChartState extends State<TimeMetricChart> {
  /// The current minimum timestamp (in milliseconds) visible on the X-axis.
  late double minX;
  
  /// The current maximum timestamp (in milliseconds) visible on the X-axis.
  late double maxX;
  
  /// A cached list of FlSpot coordinates derived from historical data.
  List<FlSpot>? _cachedHistorySpots;
  
  /// A cached list of FlSpot coordinates derived from forecasting data.
  List<FlSpot>? _cachedForecastSpots;
  
  /// A cached list combining forecast spots and the last history spot to create a seamless visual bridge.
  List<FlSpot>? _cachedBridgeSpots;
  
  /// Reference to the last built history list to detect data changes and invalidate caches.
  List<ChartDataPoint>? _lastHistoryRef;
  
  /// Reference to the last built forecast list to detect data changes and invalidate caches.
  List<ChartDataPoint>? _lastForecastRef;
  
  @override
  void initState() {
    super.initState();
    _resetView();
  }

  @override
  void didUpdateWidget(TimeMetricChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) _cachedHistorySpots = null;
    if (oldWidget.forecast != widget.forecast) _cachedForecastSpots = null;
  }

  /// Resets the chart's viewing window to center around the current time.
  /// 
  /// Sets [minX] to 48 hours ago and [maxX] to 24 hours into the future,
  /// accounting for the [widget.timeOffsetHours].
  void _resetView() {
    final nowMs = DateTime.now().add(Duration(hours: widget.timeOffsetHours)).millisecondsSinceEpoch.toDouble();
    minX = nowMs - 48 * 3600000.0;
    maxX = nowMs + 24 * 3600000.0;
  }

  /// Truncates a given [DateTime] to its hour precision.
  /// 
  /// Returns a new [DateTime] with minutes, seconds, and milliseconds set to zero.
  DateTime _truncateToHour(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour);
  }

  /// Builds vertical range background annotations indicating distinct phases 
  /// of the agronomic day (e.g., gathering vs. forecasting).
  /// 
  /// Returns a list of [VerticalRangeAnnotation] representing the visual zones.
  List<VerticalRangeAnnotation> _buildZones() {
    final now = DateTime.now().add(Duration(hours: widget.timeOffsetHours));
    final startH = widget.forecastZoneStartHour; // e.g. 19
    final endH = widget.forecastZoneEndHour;     // e.g. 9

    DateTime agroDayStart;
    if (now.hour >= endH) {
      agroDayStart = DateTime(now.year, now.month, now.day, endH);
    } else {
      agroDayStart = DateTime(now.year, now.month, now.day - 1, endH);
    }

    final yellowStart = agroDayStart;
    final yellowEnd = DateTime(agroDayStart.year, agroDayStart.month, agroDayStart.day, startH);

    final greenStart = yellowEnd;
    final greenEnd = DateTime(agroDayStart.year, agroDayStart.month, agroDayStart.day + 1, endH);

    return [
      VerticalRangeAnnotation(
        x1: yellowStart.millisecondsSinceEpoch.toDouble(),
        x2: yellowEnd.millisecondsSinceEpoch.toDouble(),
        color: Colors.amber.withValues(alpha: 0.15),
      ),
      VerticalRangeAnnotation(
        x1: greenStart.millisecondsSinceEpoch.toDouble(),
        x2: greenEnd.millisecondsSinceEpoch.toDouble(),
        color: Colors.green.withValues(alpha: 0.15),
      ),
    ];
  }

  /// Converts a raw list of [ChartDataPoint] into a list of plottable [FlSpot]s.
  /// 
  /// Deduplicates and sorts the points based on their hour-truncated timestamps 
  /// to ensure a clean rendering of the line chart.
  List<FlSpot> _buildSpots(List<ChartDataPoint> data) {
    final Map<int, double> hourlyMap = {};
    for (var point in data) {
      final hourMs = _truncateToHour(point.timestamp).millisecondsSinceEpoch;
      hourlyMap[hourMs] = point.value; 
    }
    final sortedKeys = hourlyMap.keys.toList()..sort();
    return sortedKeys.map((ms) => FlSpot(ms.toDouble(), hourlyMap[ms]!)).toList();
  }

  /// Builds the visual representation of the interactive time metric chart.
  /// 
  /// Manages cache validation for [FlSpot] data, dynamically calculates the Y-axis 
  /// boundaries, determines optimal X-axis step intervals based on zoom level, 
  /// and constructs the core [LineChart] widget wrapped in a pan-aware [Listener].
  @override
  Widget build(BuildContext context) {
    if (_cachedHistorySpots == null || _lastHistoryRef != widget.history) {
      _lastHistoryRef = widget.history;
      _cachedHistorySpots = _buildSpots(widget.history);
      _cachedBridgeSpots = null;
    }
    if (_cachedForecastSpots == null || _lastForecastRef != widget.forecast) {
      _lastForecastRef = widget.forecast;
      _cachedForecastSpots = _buildSpots(widget.forecast);
      _cachedBridgeSpots = null;
    }

    final historyFlSpots = _cachedHistorySpots!;
    final forecastFlSpots = _cachedForecastSpots!;
    final nowMs = DateTime.now().add(Duration(hours: widget.timeOffsetHours)).millisecondsSinceEpoch.toDouble();

    // Connect forecast to the last history spot so curved lines meet seamlessly
    if (_cachedBridgeSpots == null) {
      final List<FlSpot> forecastSpotsWithBridge = List.from(forecastFlSpots);
      if (historyFlSpots.isNotEmpty && forecastSpotsWithBridge.isNotEmpty) {
        if (forecastSpotsWithBridge.first.x > historyFlSpots.last.x) {
          forecastSpotsWithBridge.insert(0, historyFlSpots.last);
        }
      }
      _cachedBridgeSpots = forecastSpotsWithBridge;
    }
    final forecastSpotsWithBridge = _cachedBridgeSpots!;

    // Y Axis scaling rules:
    // Min is always 0.
    // If unit is '%' or percentage, max is 100.
    // Otherwise, max is greatest value + 20% padding.
    final double calculatedMinY = widget.minY ?? 0.0;
    final double calculatedMaxY;

    final isPercentage = widget.unit.contains('%') || 
                         widget.title.toLowerCase().contains('humidity') || 
                         widget.title.toLowerCase().contains('moisture');

    if (widget.maxY != null) {
      calculatedMaxY = widget.maxY!;
    } else if (isPercentage) {
      calculatedMaxY = 100.0;
    } else {
      double maxVal = 0.0;
      for (var p in historyFlSpots.followedBy(forecastFlSpots)) {
        if (p.y > maxVal) maxVal = p.y;
      }
      calculatedMaxY = maxVal > 0 ? (maxVal * 1.20) : 100.0;
    }

    // Dynamic X axis step calculation to avoid clutter on small screens
    final visibleHours = (maxX - minX) / 3600000.0;
    int stepHours = 3;
    if (visibleHours > 60) {
      stepHours = 12;
    } else if (visibleHours > 30) {
      stepHours = 6;
    } else if (visibleHours > 12) {
      stepHours = 4;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.title} (${widget.unit})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 20, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _resetView();
                });
              },
              tooltip: 'Center to Now',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Listener(
          onPointerMove: (event) {
            setState(() {
              final shift = -event.delta.dx * (240000.0); 
              minX += shift;
              maxX += shift;
            });
          },
          child: Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRect( 
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX,
                  maxX: maxX,
                  minY: calculatedMinY,
                  maxY: calculatedMaxY,
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: _buildZones(),
                  ),
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      VerticalLine(
                        x: nowMs,
                        color: Colors.red.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: historyFlSpots,
                      isCurved: true,
                      color: widget.historyColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: forecastSpotsWithBridge,
                      isCurved: true,
                      color: widget.forecastColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 3600000.0, // Base query interval 1 hour
                        getTitlesWidget: (value, meta) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          
                          if (dt.minute != 0) return const SizedBox.shrink();

                          if (dt.hour == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM dd').format(dt),
                                style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
                              ),
                            );
                          } else if (dt.hour % stepHours == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${dt.hour}h',
                                style: const TextStyle(fontSize: 9, color: Colors.black54),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (calculatedMaxY - calculatedMinY) / 4 == 0 ? 1 : (calculatedMaxY - calculatedMinY) / 4,
                    verticalInterval: stepHours * 3600000.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1);
                    },
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          if (touchedSpots.indexOf(spot) != 0) return null;
                          final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MM/dd HH:mm').format(dt)}\n${spot.y.toStringAsFixed(1)} ${widget.unit}',
                            const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

