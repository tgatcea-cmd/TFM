/// Represents a single data point in a time-series chart.
///
/// This class is used to structure data for rendering charts across the application.
class ChartDataPoint {
  /// The time at which this data point was recorded or predicted.
  final DateTime timestamp;

  /// The numerical value associated with the given [timestamp].
  final double value;

  /// Creates a [ChartDataPoint] with the specified [timestamp] and [value].
  ChartDataPoint({required this.timestamp, required this.value});
}
