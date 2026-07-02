import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import 'styles.dart';

// Helper function to format DateTime simply
String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${dt.day}/${dt.month} $hour:$minute';
}

// Helper function to calculate Agronomic Day boundaries
Map<String, DateTime> _calculateAgriWindow(int timeOffsetHours) {
  final now = DateTime.now().add(Duration(hours: timeOffsetHours));
  
  // Find current Agronomic Day boundaries (7pm to 7pm)
  DateTime currentDaStart;
  DateTime currentDaEnd;
  if (now.hour < 19) {
    currentDaStart = DateTime(now.year, now.month, now.day - 1, 19, 0, 0);
    currentDaEnd = DateTime(now.year, now.month, now.day, 19, 0, 0);
  } else {
    currentDaStart = DateTime(now.year, now.month, now.day, 19, 0, 0);
    currentDaEnd = DateTime(now.year, now.month, now.day + 1, 19, 0, 0);
  }

  // 3-day window relative to the current DA:
  // Starts at 7pm of two days ago (currentDaEnd - 2 days)
  final chartStart = currentDaEnd.subtract(const Duration(days: 2));
  // Ends at 7pm of the following day (currentDaEnd + 1 day)
  final chartEnd = currentDaEnd.add(const Duration(days: 1));

  return {
    'start': chartStart,
    'end': chartEnd,
  };
}

class RadiationChart extends StatelessWidget {
  final List<WeatherRecord> weatherHistory;
  final List<double> radiationForecast;
  final int timeOffsetHours;

  const RadiationChart({
    super.key,
    required this.weatherHistory,
    required this.radiationForecast,
    this.timeOffsetHours = 0,
  });

  @override
  Widget build(BuildContext context) {
    final window = _calculateAgriWindow(timeOffsetHours);
    final chartStart = window['start']!;
    final chartEnd = window['end']!;

    final realNow = DateTime.now().add(Duration(hours: timeOffsetHours));

    // Colors
    final redColor = AppStyles.dangerRed(context);
    final orangeColor = AppStyles.accentOrange(context);

    // Filter weather records to the 3-day window
    final limitPastMs = chartStart.millisecondsSinceEpoch;
    final limitFutureMs = chartEnd.millisecondsSinceEpoch;
    final sortedWeather = List<WeatherRecord>.from(weatherHistory)
      ..removeWhere((w) => w.timestamp < limitPastMs || w.timestamp > limitFutureMs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solar Radiation (W/m²)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: CustomPaint(
            painter: _RadiationPainter(
              chartStart: chartStart,
              chartEnd: chartEnd,
              realNow: realNow,
              weatherHistory: sortedWeather,
              radiationForecast: radiationForecast,
              redColor: redColor,
              orangeColor: orangeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadiationPainter extends CustomPainter {
  final DateTime chartStart;
  final DateTime chartEnd;
  final DateTime realNow;
  final List<WeatherRecord> weatherHistory;
  final List<double> radiationForecast;
  final Color redColor;
  final Color orangeColor;

  _RadiationPainter({
    required this.chartStart,
    required this.chartEnd,
    required this.realNow,
    required this.weatherHistory,
    required this.radiationForecast,
    required this.redColor,
    required this.orangeColor,
  });

  double _getX(int timestamp, double width) {
    final startMs = chartStart.millisecondsSinceEpoch;
    final endMs = chartEnd.millisecondsSinceEpoch;
    final percent = (timestamp - startMs) / (endMs - startMs);
    return percent.clamp(0.0, 1.0) * width;
  }

  double _getY(double value, double chartHeight) {
    return chartHeight - (value.clamp(0.0, 1000.0) / 1000.0) * chartHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    const double bottomMargin = 20.0;
    final double chartHeight = size.height - bottomMargin;

    // 1. Draw X axis baseline
    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      axisPaint,
    );

    // 2. Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      double val = i * 250.0;
      double y = _getY(val, chartHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Draw vertical Agronomic Day boundaries (7pm of each day)
    final boundaryPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.5;
    
    final textStyleX = const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold);

    // June 30 19:00, July 1 19:00, July 2 19:00, July 3 19:00
    DateTime tick = chartStart;
    while (tick.isBefore(chartEnd) || tick.isAtSameMomentAs(chartEnd)) {
      final x = _getX(tick.millisecondsSinceEpoch, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), boundaryPaint);

      // Draw X labels
      final label = _formatTime(tick);
      final span = TextSpan(text: label, style: textStyleX);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));

      tick = tick.add(const Duration(days: 1));
    }

    // 4. Draw Now vertical divider
    final nowMs = realNow.millisecondsSinceEpoch;
    final double xNow = _getX(nowMs, size.width);
    final nowDividerPaint = Paint()
      ..color = redColor.withOpacity(0.35)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(xNow, 0),
      Offset(xNow, chartHeight),
      nowDividerPaint,
    );

    // 5. Draw Radiation Data Lines
    // Past radiation (Red dashed)
    final pastPath = ui.Path();
    bool hasPast = false;
    for (var w in weatherHistory) {
      if (w.timestamp > nowMs) continue;
      final x = _getX(w.timestamp, size.width);
      final y = _getY(w.radiation, chartHeight);
      if (!hasPast) {
        pastPath.moveTo(x, y);
        hasPast = true;
      } else {
        pastPath.lineTo(x, y);
      }
    }
    if (hasPast) {
      // Simple dashed drawing or solid
      final strokePaint = Paint()
        ..color = redColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(pastPath, strokePaint);
    }

    // Future radiation forecast (Orange solid)
    final forecastPath = ui.Path();
    bool hasForecast = false;
    
    // Draw using weather history points that are in the future
    for (var w in weatherHistory) {
      if (w.timestamp <= nowMs) continue;
      final x = _getX(w.timestamp, size.width);
      final y = _getY(w.radiation, chartHeight);
      if (!hasForecast) {
        forecastPath.moveTo(x, y);
        hasForecast = true;
      } else {
        forecastPath.lineTo(x, y);
      }
    }

    // If weatherHistory doesn't cover future, draw from radiationForecast array
    if (!hasForecast && radiationForecast.isNotEmpty) {
      for (int i = 0; i < radiationForecast.length; i++) {
        final ts = nowMs + i * 3600000;
        if (ts > chartEnd.millisecondsSinceEpoch) break;
        final x = _getX(ts, size.width);
        final y = _getY(radiationForecast[i], chartHeight);
        if (i == 0) {
          forecastPath.moveTo(x, y);
        } else {
          forecastPath.lineTo(x, y);
        }
      }
      hasForecast = true;
    }

    if (hasForecast) {
      final strokePaint = Paint()
        ..color = orangeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(forecastPath, strokePaint);
    }

    // 6. Draw floating cursor chip displaying current radiation value at the central Now line
    double? currentRad;
    double closestDist = double.infinity;
    for (var w in weatherHistory) {
      final dist = (w.timestamp - nowMs).abs().toDouble();
      if (dist < closestDist) {
        closestDist = dist;
        currentRad = w.radiation;
      }
    }
    // Check forecast array if closer
    if (radiationForecast.isNotEmpty && (closestDist > 1800000.0)) {
      currentRad = radiationForecast.first;
    }

    if (currentRad != null) {
      final double y = _getY(currentRad, chartHeight);
      final span = TextSpan(
        text: '${currentRad.toStringAsFixed(0)} W/m²',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      final bgPaint = Paint()..color = orangeColor..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xNow + 6, y - tp.height / 2 - 3, xNow + 12 + tp.width + 4, y + tp.height / 2 + 3),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, bgPaint);
      tp.paint(canvas, Offset(xNow + 10, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HumidityChart extends StatelessWidget {
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final int timeOffsetHours;

  const HumidityChart({
    super.key,
    required this.history,
    required this.predictions,
    this.timeOffsetHours = 0,
  });

  @override
  Widget build(BuildContext context) {
    final window = _calculateAgriWindow(timeOffsetHours);
    final chartStart = window['start']!;
    final chartEnd = window['end']!;

    final realNow = DateTime.now().add(Duration(hours: timeOffsetHours));

    // Colors
    final tealColor = AppStyles.primaryTeal(context);
    final orangeColor = AppStyles.accentOrange(context);

    // Filter records to the 3-day window
    final limitPastMs = chartStart.millisecondsSinceEpoch;
    final limitFutureMs = chartEnd.millisecondsSinceEpoch;

    final sortedHistory = List<SoilHumidityRecord>.from(history)
      ..removeWhere((r) => r.timestamp < limitPastMs || r.timestamp > realNow.millisecondsSinceEpoch)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sortedPredictions = List<PredictionRecord>.from(predictions)
      ..removeWhere((p) => p.timestamp < realNow.millisecondsSinceEpoch || p.timestamp > limitFutureMs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate dynamic humidity range
    double minHum = 100.0;
    double maxHum = 0.0;
    for (var r in sortedHistory) {
      if (r.value < minHum) minHum = r.value;
      if (r.value > maxHum) maxHum = r.value;
    }
    for (var p in sortedPredictions) {
      if (p.predictedHumidity < minHum) minHum = p.predictedHumidity;
      if (p.predictedHumidity > maxHum) maxHum = p.predictedHumidity;
    }
    if (minHum > maxHum) {
      minHum = 60.0;
      maxHum = 100.0;
    }
    final double displayMin = (minHum - 5.0).clamp(0.0, 95.0);
    final double displayMax = (maxHum + 5.0).clamp(displayMin + 5.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soil Humidity (%)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: CustomPaint(
            painter: _HumidityPainter(
              chartStart: chartStart,
              chartEnd: chartEnd,
              realNow: realNow,
              history: sortedHistory,
              predictions: sortedPredictions,
              minHumidity: displayMin,
              maxHumidity: displayMax,
              tealColor: tealColor,
              orangeColor: orangeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _HumidityPainter extends CustomPainter {
  final DateTime chartStart;
  final DateTime chartEnd;
  final DateTime realNow;
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final double minHumidity;
  final double maxHumidity;
  final Color tealColor;
  final Color orangeColor;

  _HumidityPainter({
    required this.chartStart,
    required this.chartEnd,
    required this.realNow,
    required this.history,
    required this.predictions,
    required this.minHumidity,
    required this.maxHumidity,
    required this.tealColor,
    required this.orangeColor,
  });

  double _getX(int timestamp, double width) {
    final startMs = chartStart.millisecondsSinceEpoch;
    final endMs = chartEnd.millisecondsSinceEpoch;
    final percent = (timestamp - startMs) / (endMs - startMs);
    return percent.clamp(0.0, 1.0) * width;
  }

  double _getY(double value, double chartHeight) {
    final val = value.clamp(minHumidity, maxHumidity);
    final percent = (val - minHumidity) / (maxHumidity - minHumidity);
    return chartHeight - percent * chartHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    const double bottomMargin = 20.0;
    final double chartHeight = size.height - bottomMargin;

    // 1. Draw X axis baseline
    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      axisPaint,
    );

    // 2. Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    final double rangeStep = (maxHumidity - minHumidity) / 4.0;
    for (int i = 0; i <= 4; i++) {
      double val = minHumidity + i * rangeStep;
      double y = _getY(val, chartHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Draw vertical Agronomic Day boundaries
    final boundaryPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.5;
    
    final textStyleX = const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold);

    DateTime tick = chartStart;
    while (tick.isBefore(chartEnd) || tick.isAtSameMomentAs(chartEnd)) {
      final x = _getX(tick.millisecondsSinceEpoch, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), boundaryPaint);

      // Draw X labels
      final label = _formatTime(tick);
      final span = TextSpan(text: label, style: textStyleX);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));

      tick = tick.add(const Duration(days: 1));
    }

    // 4. Draw Now vertical divider
    final nowMs = realNow.millisecondsSinceEpoch;
    final double xNow = _getX(nowMs, size.width);
    final nowDividerPaint = Paint()
      ..color = tealColor.withOpacity(0.35)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(xNow, 0),
      Offset(xNow, chartHeight),
      nowDividerPaint,
    );

    // 5. Draw Soil Humidity Line (Teal)
    final historyPath = ui.Path();
    bool hasHistory = false;
    for (var r in history) {
      final x = _getX(r.timestamp, size.width);
      final y = _getY(r.value, chartHeight);
      if (!hasHistory) {
        historyPath.moveTo(x, y);
        hasHistory = true;
      } else {
        historyPath.lineTo(x, y);
      }
    }
    if (hasHistory) {
      final strokePaint = Paint()
        ..color = tealColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(historyPath, strokePaint);
    }

    // 6. Draw soil humidity predictions (Orange dashed)
    final predPath = ui.Path();
    bool hasPredictions = false;
    for (var p in predictions) {
      final x = _getX(p.timestamp, size.width);
      final y = _getY(p.predictedHumidity, chartHeight);
      if (!hasPredictions) {
        predPath.moveTo(x, y);
        hasPredictions = true;
      } else {
        predPath.lineTo(x, y);
      }
    }
    if (hasPredictions) {
      // Dashed paint
      final strokePaint = Paint()
        ..color = orangeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      // Simple path rendering for prediction line
      canvas.drawPath(predPath, strokePaint);
    }

    // 7. Draw floating cursor chip displaying current humidity value at the Now line
    double? currentHum;
    double closestDist = double.infinity;
    for (var r in history) {
      final dist = (r.timestamp - nowMs).abs().toDouble();
      if (dist < closestDist) {
        closestDist = dist;
        currentHum = r.value;
      }
    }
    for (var p in predictions) {
      final dist = (p.timestamp - nowMs).abs().toDouble();
      if (dist < closestDist) {
        closestDist = dist;
        currentHum = p.predictedHumidity;
      }
    }

    if (currentHum != null) {
      final double y = _getY(currentHum, chartHeight);
      final span = TextSpan(
        text: '${currentHum.toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      final bgPaint = Paint()..color = tealColor..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xNow - tp.width - 12, y - tp.height / 2 - 3, xNow - 4, y + tp.height / 2 + 3),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, bgPaint);
      tp.paint(canvas, Offset(xNow - tp.width - 9, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
