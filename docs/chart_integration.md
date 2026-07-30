# Unified Charting System Integration Guide

This guide explains how to integrate the newly refactored chart architecture into your production Flutter environment.

## 1. Architecture Overview

The charting system is located in `lib/widgets/charts/` and is divided into three layers:

1. **`time_metric_chart.dart` (The Engine)**: A highly reusable, generic `fl_chart` wrapper. It handles panning, dynamic Y-axis calculation, timezone truncations, and rendering the "Gathering" vs "Forecast" logic zones.
2. **`metrics/*.dart` (The Mappers)**: Small wrapper widgets (e.g., `radiation_chart.dart`, `humidity_chart.dart`) that convert your specific model objects (like `WeatherRecord` or `PredictionRecord`) into standard `ChartDataPoint` arrays for the Engine.
3. **`unified_chart.dart` (The Dashboard)**: A vertical orchestrator that stacks your chosen metric charts and computes the global logic stage ("ETAPA ESPERAR DATOS" vs "ETAPA DATOS LISTOS") for the UI header.

## 2. Integration in Production

To mount the charts in your main application, simply import and use the `UnifiedChart`:

```dart
import 'package:flutter_tfm_test/widgets/charts/unified_chart.dart';

// Inside your build method:
UnifiedChart(
  history: yourSoilHumidityHistory,          // List<SoilHumidityRecord>
  predictions: yourModelPredictions,         // List<PredictionRecord>
  radiationForecast: yourRadiationForecast,  // List<double>
  temperatureForecast: yourTempForecast,     // List<double>
  weatherHistory: yourWeatherHistory,        // List<WeatherRecord>
  minHumidity: 0,
  
  // Logic Zone Configuration (Optional, defaults to 19 and 9)
  forecastZoneStartHour: 19, // 19:00
  forecastZoneEndHour: 9,    // 09:00 (Next day)
  
  // Keep this 0 for production! It is only used for time-travel testing.
  timeOffsetHours: 0,
)
```

## 3. How to add a Custom Chart (e.g. Wind Speed)

Adding a new chart is incredibly simple because you never have to touch the complex `fl_chart` code again.

**Step 1:** Create `lib/widgets/charts/metrics/wind_chart.dart`.
**Step 2:** Write a simple stateless widget that maps your vector to `ChartDataPoint`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_tfm_test/widgets/charts/time_metric_chart.dart';
import 'package:flutter_tfm_test/data/models/chart_data_point.dart';

class WindChart extends StatelessWidget {
  final List<double> windVector;
  
  // ... constructor ...

  @override
  Widget build(BuildContext context) {
    // Map your custom data
    final historyData = windVector.map((val) => ChartDataPoint(
      timestamp: DateTime.now(), // Generate proper timestamps
      value: val,
    )).toList();

    return TimeMetricChart(
      title: 'Wind Speed',
      unit: 'km/h',
      history: historyData,
      forecast: [], // Empty if no forecast exists
      historyColor: Colors.blue,
      forecastColor: Colors.cyan,
    );
  }
}
```

**Step 3:** Add `WindChart(...)` directly into the `Column` inside `unified_chart.dart`.

## 4. Notes on the "Time Travel" Feature

The variable `timeOffsetHours` is exposed purely for UI/UX testing in `test_chart_workflow.dart`. It dynamically offsets `DateTime.now()` across the entire chart suite so you can verify how the system reacts when it crosses logic stage boundaries (e.g. transitioning from 18:59 to 19:00). 

**In production, always pass `timeOffsetHours: 0` (or leave it to default) so the charts lock exactly to the real-world current time.**
