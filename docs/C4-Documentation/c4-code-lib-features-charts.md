# C4 Code-Level Documentation: `lib/features/charts`

## 1. Overview Section
- **Name**: Charts Feature
- **Description**: Contains UI components for rendering telemetry and historical data as interactive charts.
- **Location**: `lib/features/charts`
- **Language**: Dart
- **Purpose**: Provides specialized and reusable widgets utilizing `fl_chart` to visualize different metrics (temperature, humidity, radiation, custom sensors) over time.

## 2. Code Elements Section

### Classes

#### `CustomMetricChart`
- **Description**: A stateless widget designed to render custom telemetry metrics with specific colors and thresholds.
- **Location**: `lib/features/charts/custom_metric_chart.dart`
- **Dependencies**: `fl_chart`, `TimeMetricChart`.
- **Methods**:
  - `Widget build(BuildContext context)`: Builds the chart wrapped in appropriate UI containers.

#### `HumidityChart`
- **Description**: A stateless widget specialized in plotting soil and air humidity values over time.
- **Location**: `lib/features/charts/humidity_chart.dart`
- **Dependencies**: `fl_chart`, `TimeMetricChart`.
- **Methods**:
  - `Widget build(BuildContext context)`: Builds the specific humidity visualization component.

#### `RadiationChart`
- **Description**: A stateless widget specialized in displaying shortwave solar radiation metrics.
- **Location**: `lib/features/charts/radiation_chart.dart`
- **Dependencies**: `fl_chart`, `TimeMetricChart`.
- **Methods**:
  - `Widget build(BuildContext context)`: Builds the specific radiation visualization component.

#### `TimeMetricChart`
- **Description**: A stateful core charting widget that handles the heavy lifting of `fl_chart` interactions, panning, zooming, and drawing time-series data correctly on an X/Y axis.
- **Location**: `lib/features/charts/time_metric_chart.dart`
- **Dependencies**: `fl_chart` (external).
- **Methods**:
  - `State<TimeMetricChart> createState()`
  - (Internal) `void _resetView()`: Resets panning and zooming states.
  - (Internal) `DateTime _truncateToHour(DateTime dt)`: Helper for axis tick generation.
  - (Internal) `List<VerticalRangeAnnotation> _buildZones()`: Generates background zones (e.g., night/day, irrigation restricted times).
  - (Internal) `List<FlSpot> _buildSpots(List<ChartDataPoint> data)`: Maps raw time-series data to `FlSpot` objects.
  - `Widget build(BuildContext context)`: Renders the interactive `LineChart`.

#### `UnifiedChart`
- **Description**: A stateless widget that aggregates multiple metrics into a single, comprehensive view, potentially layering multiple data series.
- **Location**: `lib/features/charts/unified_chart.dart`
- **Dependencies**: `fl_chart`, `TimeMetricChart`.
- **Methods**:
  - `Widget build(BuildContext context)`: Renders the unified overlay.

## 3. Dependencies Section
- **Internal dependencies**:
  - `TimeMetricChart` is the core dependency for `CustomMetricChart`, `HumidityChart`, `RadiationChart`, and `UnifiedChart`.
- **External dependencies**:
  - `package:fl_chart/fl_chart.dart`: The underlying external library used to render the actual lines, axes, and interactive tooltips.

## 4. Relationships Section
These charts are heavily utilized within `lib/screens/home_screen.dart` and `lib/screens/nearby_screen.dart` to present actionable telemetry data to the user. The charts process the historical data payloads provided by the BLE subsystem and ML inference results to display historical trends and future predictions.
