import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tfm_app/main.dart';
import 'dart:math' show pi;
import '../data/models/models.dart';
import 'styles.dart';

class UnifiedChart extends StatefulWidget {
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final List<double> radiationForecast;
  final List<WeatherRecord> weatherHistory;
  final int timeOffsetHours; // <-- NUEVO
  final double minHumidity;  // <-- NUEVO

  const UnifiedChart({
    super.key,
    required this.history,
    required this.predictions,
    required this.radiationForecast,
    required this.weatherHistory,
    required this.minHumidity,
    this.timeOffsetHours = 0, // <-- NUEVO
  });
  @override
  State<UnifiedChart> createState() => _UnifiedChartState();
}

class _UnifiedChartState extends State<UnifiedChart> {
  // Offset en horas. 0 = tiempo actual centrado.
  // Positivo significa mirar hacia el pasado. Negativo hacia el futuro.
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    // 1. Etapas basadas en la hora (IR: 10am, DA: 18pm)
    final now = DateTime.now().add(
      Duration(hours: widget.timeOffsetHours),
    ); // <-- MODIFICADO
    final isWaitingData = now.hour >= 10 && now.hour < 19;

    // Colores basados en Etapa y en los estilos globales de la App
    final rightBgColor = isWaitingData
        ? Colors.amber.withValues(alpha: 0.15)
        : Colors.green.withValues(alpha: 0.15);
    final headerColor = isWaitingData
        ? Colors.amber.shade700
        : Colors.green.shade700;

    // Resolvemos los colores temáticos de la app a pasar al Painter
    final tealColor = AppStyles.primaryTeal(context);
    final redColor = AppStyles.dangerRed(context);
    final orangeColor = AppStyles.accentOrange(context);
    final baseTime = DateTime.now();
    final limitPastMs = baseTime.subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
    final limitFutureMs = baseTime.add(const Duration(hours: 24)).millisecondsSinceEpoch;

    // Clones ordenados para asegurar el trazado secuencial y filtrados al rango -48h a +24h relative to baseTime (real time)
    final sortedHistory = List<SoilHumidityRecord>.from(widget.history)
      ..removeWhere((r) => r.timestamp < limitPastMs || r.timestamp > baseTime.millisecondsSinceEpoch)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sortedPredictions = List<PredictionRecord>.from(widget.predictions)
      ..removeWhere((p) => p.timestamp < baseTime.millisecondsSinceEpoch || p.timestamp > limitFutureMs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sortedWeather = List<WeatherRecord>.from(widget.weatherHistory)
      ..removeWhere((w) => w.timestamp < limitPastMs || w.timestamp > limitFutureMs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // ponytail: Dynamic humidity range (relative to displayed data)
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
    // Safe defaults if empty or invalid
    if (minHum > maxHum) {
      minHum = 60.0;
      maxHum = 100.0;
    }
    // Relative padding: -5% on min, +5% on max
    final double displayMin = (minHum - 5.0).clamp(0.0, 95.0);
    final double displayMax = (maxHum + 5.0).clamp(displayMin + 5.0, 100.0);

    // ponytail: Debug verbosity to detect why past radiation might not be showing
    print('UnifiedChart Debug: now=$now, baseTime=$baseTime, baseTimeMs=${baseTime.millisecondsSinceEpoch}');
    print('UnifiedChart Debug: limitPastMs=$limitPastMs, limitFutureMs=$limitFutureMs');
    print('UnifiedChart Debug: raw weatherHistory count=${widget.weatherHistory.length}');
    if (widget.weatherHistory.isNotEmpty) {
      final sortedTimes = widget.weatherHistory.map((w) => w.timestamp).toList()..sort();
      print('UnifiedChart Debug: database weather range: ${sortedTimes.first} to ${sortedTimes.last}');
      print('UnifiedChart Debug: sortedWeather filtered count in chart range=${sortedWeather.length}');
      final pastCount = sortedWeather.where((w) => w.timestamp <= baseTime.millisecondsSinceEpoch).length;
      print('UnifiedChart Debug: past weather records count=${pastCount}');
      if (pastCount > 0) {
        final sample = sortedWeather.firstWhere((w) => w.timestamp <= baseTime.millisecondsSinceEpoch);
        print('UnifiedChart Debug: past weather sample ts=${sample.timestamp}, rad=${sample.radiation}');
      }
    };

    return Column(
      children: [
        // Indicador de Etapa
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWaitingData
                  ? Icons.hourglass_empty
                  : Icons.check_circle_outline,
              color: headerColor,
            ),
            const SizedBox(width: 8),
            Text(
              isWaitingData ? "ETAPA ESPERAR DATOS" : "ETAPA DATOS LISTOS",
              style: TextStyle(fontWeight: FontWeight.bold, color: headerColor),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Área del Gráfico
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior:
              Clip.hardEdge, // Recorta los desbordamientos del efecto 3D
          child: GestureDetector(
            onDoubleTap: () {
              setState(() {
                _scrollOffset = 0.0;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                // Modificador de sensibilidad del arrastre
                _scrollOffset += details.delta.dx * 0.15;
                // Clamp: Limitar el pan desde -24h (futuro max) hasta 48h (pasado max)
                _scrollOffset = _scrollOffset.clamp(-24.0, 48.0);
              });
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = constraints.maxWidth / 2;
                final height = constraints.maxHeight;

                return Stack(
                  children: [
                    // MITAD IZQUIERDA (PASADO) - Deformación 3D y compresión 2:1
                    Positioned(
                      right:
                          halfWidth, // Anclamos el borde derecho al centro exacto del stack
                      width:
                          halfWidth *
                          1.4, // Hacemos el contenedor más ancho para contrarrestar el encogimiento de la perspectiva
                      height: height,
                      child: Transform(
                        alignment: Alignment.centerRight,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspectiva más suave
                          ..rotateY(20 * pi / 180), // 20 grados hacia el fondo
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade200,
                                Colors.white,
                              ],
                              stops: const [0.0, 0.8, 1.0],
                            ),
                            border: const Border(
                              right: BorderSide(
                                color: Colors.black26,
                                width: 2,
                              ),
                            ),
                          ),
                          child: CustomPaint(
                            painter: ChartPainter(
                              isLeft: true,
                              scrollOffset: _scrollOffset,
                              isWaitingData: isWaitingData,
                              history: sortedHistory,
                              predictions: sortedPredictions,
                              weatherHistory: sortedWeather,
                              radiationForecast: widget.radiationForecast,
                              timeOffsetHours: widget.timeOffsetHours,
                              minHumidity: displayMin,
                              maxHumidity: displayMax,
                              teal: tealColor,
                              red: redColor,
                              orange: orangeColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // MITAD DERECHA (FUTURO) - Normal
                    Positioned(
                      left: halfWidth, // Anclado a la derecha del centro
                      width: halfWidth, // Ocupa exactamente la mitad derecha
                      height: height,
                      child: Container(
                        color: Colors.grey.shade50,
                        child: CustomPaint(
                          painter: ChartPainter(
                            isLeft: false,
                            scrollOffset: _scrollOffset,
                            isWaitingData: isWaitingData,
                            history: sortedHistory,
                            predictions: sortedPredictions,
                            weatherHistory: sortedWeather,
                            radiationForecast: widget.radiationForecast,
                            teal: tealColor,
                            red: redColor,
                            timeOffsetHours: widget.timeOffsetHours,
                            minHumidity: displayMin,
                            maxHumidity: displayMax,
                            orange: orangeColor,
                          ),
                        ),
                      ),
                    ),

                    // LÍNEA CENTRAL (T=0)
                    Positioned(
                      left: halfWidth - 1,
                      width: 2,
                      height: height,
                      child: Container(color: redColor),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Leyenda
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem('Humidity %', tealColor, isDashed: false),
            _buildLegendItem('Past Radiation W/m²', redColor, isDashed: true),
            if (!isWaitingData)
              _buildLegendItem('Prediction %', orangeColor, isDashed: true),
            if (!isWaitingData)
              _buildLegendItem(
                'Radiation Forecast',
                orangeColor,
                isDashed: false,
              ),
          ],
        ),
      ],
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
            height: 4,
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

class ChartPainter extends CustomPainter {
  final bool isLeft;
  final double scrollOffset;
  final bool isWaitingData;
  final List<SoilHumidityRecord> history;
  final List<PredictionRecord> predictions;
  final List<WeatherRecord> weatherHistory;
  final List<double> radiationForecast;
  final double minHumidity;
  final double maxHumidity;

  final int timeOffsetHours; // <-- NUEVO

  final Color teal;
  final Color red;
  final Color orange;

  ChartPainter({
    required this.isLeft,
    required this.scrollOffset,
    required this.isWaitingData,
    required this.history,
    required this.predictions,
    required this.weatherHistory,
    required this.radiationForecast,
    required this.minHumidity,
    required this.maxHumidity,
    required this.teal,
    required this.red,
    required this.orange,
    required this.timeOffsetHours, // <-- NUEVO
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Esencial para que el canvas de la mitad no pinte donde no debe (crea el empalme perfecto)
    canvas.clipRect(Offset.zero & size);

    // Margen inferior reservado para el texto del Eje X
    const double bottomMargin = 24.0;
    final double chartHeight = size.height - bottomMargin;

    // 1. Dibujar línea base del eje X
    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      axisPaint,
    );

    // ---- DIBUJAR BANDAS COLOR ZONING (Agronomic Day) ----
    // ponytail: Paint current zoning band AND past yellow / future green context bands
    final now = DateTime.now().add(Duration(hours: timeOffsetHours));
    final double currentHour = now.hour + now.minute / 60.0;

    if (now.hour >= 10 && now.hour < 19) {
      // Yellow condition -> Paint Yellow (current) AND Green (future)
      final double yellowStart = 10.0 - currentHour;
      final double yellowEnd = 19.0 - currentHour;
      final double greenStart = 19.0 - currentHour;
      final double greenEnd = 34.0 - currentHour;

      _drawZoningBand(canvas, chartHeight, yellowStart, yellowEnd, Colors.amber.withOpacity(0.08), size);
      _drawZoningBand(canvas, chartHeight, greenStart, greenEnd, Colors.green.withOpacity(0.08), size);
    } else {
      // Green condition -> Paint Green (current) AND Yellow (past)
      double greenStart, greenEnd, yellowStart, yellowEnd;
      if (now.hour >= 19) {
        greenStart = 19.0 - currentHour;
        greenEnd = 34.0 - currentHour;
        yellowStart = 10.0 - currentHour;
        yellowEnd = 19.0 - currentHour;
      } else {
        greenStart = -5.0 - currentHour;
        greenEnd = 10.0 - currentHour;
        yellowStart = -14.0 - currentHour;
        yellowEnd = -5.0 - currentHour;
      }

      _drawZoningBand(canvas, chartHeight, yellowStart, yellowEnd, Colors.amber.withOpacity(0.08), size);
      _drawZoningBand(canvas, chartHeight, greenStart, greenEnd, Colors.green.withOpacity(0.08), size);
    }

    // 2. Dibujar Grid horizontal y guías de Y con etiquetas de porcentaje
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.04) // ponytail: lower opacity to prevent distraction
      ..strokeWidth = 1;

    final textStyleY = const TextStyle(
      color: Colors.black38,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );

    // ponytail: dinamic grid rendering based on dynamic relative bounds
    final double rangeStep = (maxHumidity - minHumidity) / 4.0;
    for (int i = 0; i <= 4; i++) {
      double val = minHumidity + i * rangeStep;
      double y = _getY(val, chartHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // ponytail: Y-axis labels positioned next to the central Now line and color coded
      if (isLeft) {
        // Left side of the central line: draw Humidity % labels (teal)
        final span = TextSpan(text: '${val.toStringAsFixed(0)}%', style: textStyleY.copyWith(color: teal));
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(size.width - tp.width - 6, y - tp.height - 2));
      } else {
        // Right side of the central line: draw Radiation labels (red/orange)
        final double radVal = i * 250.0;
        final String labelText = i == 4 ? '1000 W/m²' : '${radVal.toStringAsFixed(0)}';
        final span = TextSpan(text: labelText, style: textStyleY.copyWith(color: red));
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(6, y - tp.height - 2));
      }
    }

    // 3. Dibujar las etiquetas de las Horas (Eje X)
    _drawXAxisLabels(canvas, size, chartHeight);

    final double nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    const double msPerHour = 3600000.0;

    // ---- HISTÓRICO HUMEDAD (VERDE) ----
    List<Offset> historyPoints = [];
    for (var r in history) {
      double h = (r.timestamp - nowMs) / msPerHour;
      historyPoints.add(
        Offset(_getX(h, size.width), _getY(r.value, chartHeight)),
      );
    }
    _drawDataLines(
      canvas,
      historyPoints,
      Paint()
        ..color = teal
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // ---- HISTÓRICO RADIACIÓN (ROJO DASHED) ----
    // ponytail: only draw radiation in the past (<= nowMs) and scale independently from 0 to 1000 W/m2
    List<Offset> radHistoryPoints = [];
    for (var w in weatherHistory) {
      if (w.timestamp > nowMs) continue;
      double h = (w.timestamp - nowMs) / msPerHour;
      radHistoryPoints.add(
        Offset(
          _getX(h, size.width),
          _getRadY(w.radiation, chartHeight),
        ),
      );
    }
    _drawDataLines(
      canvas,
      radHistoryPoints,
      Paint()
        ..color = red
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      isDashed: true,
    );

    // ---- PREDICCIONES Y FORECAST (Solo en ETAPA DATOS LISTOS) ----
    if (!isWaitingData) {
      // Prediccion Humedad (Naranja Dashed)
      List<Offset> predPoints = [];
      for (var p in predictions) {
        double h = (p.timestamp - nowMs) / msPerHour;
        predPoints.add(
          Offset(_getX(h, size.width), _getY(p.predictedHumidity, chartHeight)),
        );
      }
      _drawDataLines(
        canvas,
        predPoints,
        Paint()
          ..color = orange
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
        isDashed: true,
      );

      // Forecast Radiacion (Naranja Sólido)
      // ponytail: scale future radiation forecast independently from 0 to 1000 W/m2
      List<Offset> radForecastPoints = [];
      for (int i = 0; i < radiationForecast.length; i++) {
        double h = i.toDouble();
        radForecastPoints.add(
          Offset(
            _getX(h, size.width),
            _getRadY(radiationForecast[i], chartHeight),
          ),
        );
      }
      _drawDataLines(
        canvas,
        radForecastPoints,
        Paint()
          ..color = orange
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawXAxisLabels(Canvas canvas, Size size, double chartHeight) {
    final textStyle = const TextStyle(
      color: Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    // ponytail: Dynamic tick density based on width/compression
    final double halfWidth = size.width;
    
    int pastStep = 12;
    if ((1 / 48) * halfWidth >= 30) {
      pastStep = 1;
    } else if ((6 / 48) * halfWidth >= 30) {
      pastStep = 6;
    }

    int futureStep = 6;
    if ((1 / 24) * halfWidth >= 30) {
      futureStep = 1;
    } else if ((2 / 24) * halfWidth >= 30) {
      futureStep = 2;
    } else if ((3 / 24) * halfWidth >= 30) {
      futureStep = 3;
    } else if ((4 / 24) * halfWidth >= 30) {
      futureStep = 4;
    }

    // ponytail: Dynamic tick step is bound to the physical screen half isLeft
    // If scrolling past the central line, ticks adapt density based on their current side
    final int step = isLeft ? pastStep : futureStep;

    for (int h = -72; h <= 72; h++) {
      bool shouldDrawLabel = false;
      if (h == 0) {
        shouldDrawLabel = true;
      } else {
        shouldDrawLabel = h % step == 0;
      }

      if (!shouldDrawLabel) continue;

      double x = _getX(h.toDouble(), size.width);

      if (x >= -20 && x <= size.width + 20) {
        String label = h == 0 ? "Now" : (h > 0 ? "+${h}h" : "${h}h");

        final span = TextSpan(text: label, style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();

        // Dibujamos la etiqueta debajo de la linea (chartHeight)
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));

        // Opcional: dibujar una pequeña muesca (tick) en el eje X
        final tickPaint = Paint()
          ..color = Colors.black38
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(x, chartHeight),
          Offset(x, chartHeight + 4),
          tickPaint,
        );
      }
    }
  }

  /// Calcula posición X usando escalas compresivas independientes
  double _getX(double hour, double width) {
    // Si hago scroll positivo, points se mueven a la derecha (sumo el offset a la hora)
    double shiftedHour = hour + scrollOffset;
    if (isLeft) {
      // Compresión en el Pasado (Rango de 48h mapeado al 100% de la mitad izquierda)
      return ((shiftedHour + 48) / 48) * width;
    } else {
      // Normal en el futuro (Rango de 24h mapeado al 100% de la mitad derecha) -> Compresión 2:1 respecto al pasado
      return (shiftedHour / 24) * width;
    }
  }

  /// Calcula la posición Y (minHumidity-maxHumidity invertido para canvas)
  double _getY(double value, double chartHeight) {
    // ponytail: scale Y position based on dynamic relative bounds
    final val = value.clamp(minHumidity, maxHumidity);
    final percent = (val - minHumidity) / (maxHumidity - minHumidity);
    return chartHeight - percent * chartHeight;
  }

  // ponytail: scale radiation independently from 0 to 1000 W/m2
  double _getRadY(double value, double chartHeight) {
    return chartHeight - (value.clamp(0.0, 1000.0) / 1000.0) * chartHeight;
  }

  // ponytail: helper method to paint zoning bands dynamically
  void _drawZoningBand(Canvas canvas, double chartHeight, double start, double end, Color color, Size size) {
    final double xStart = _getX(start, size.width);
    final double xEnd = _getX(end, size.width);
    final double drawLeft = xStart.clamp(0.0, size.width);
    final double drawRight = xEnd.clamp(0.0, size.width);
    if (drawLeft < drawRight) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(drawLeft, 0, drawRight, chartHeight),
        paint,
      );
    }
  }

  /// Metodo de ayuda para conectar y dibujar las líneas
  void _drawDataLines(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    bool isDashed = false,
  }) {
    if (points.isEmpty) return;

    Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (isDashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Dibujar puntos indicadores pequeños sobre las lineas
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    for (var p in points) {
      // Filtrar para evitar procesamientos inútiles fuera de vista
      if (p.dx >= -10 && p.dx <= 1000) {
        canvas.drawCircle(p, 2.5, dotPaint);
      }
    }
  }

  /// Implementación estándar para trazar lineas punteadas en un CustomPainter
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    for (ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final ui.Path extract = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    // Repintar siempre que el usuario arrastre para el mini-histórico
    return scrollOffset != oldDelegate.scrollOffset ||
        isWaitingData != oldDelegate.isWaitingData;
  }
}
