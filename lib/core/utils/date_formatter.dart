/// Utility class for formatting dates across the application.
class AppDateFormatter {
  /// Formats a date value into a uniform app-wide string representation.
  /// 
  /// Accepts a [DateTime], an integer timestamp in milliseconds, or an ISO 8601 string in [value].
  /// Returns `YYYY-MM-DD HH:mm:ss` by default, or `YYYY-MM-DD HH:mm` if [showSeconds] is false.
  /// Returns 'N/A' if the value is null, or the string representation of the value if it cannot be parsed.
  static String format(dynamic value, {bool showSeconds = true}) {
    if (value == null) return 'N/A';
    DateTime dt;
    if (value is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return value;
      dt = parsed;
    } else {
      return value.toString();
    }

    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');

    if (showSeconds) {
      return '$year-$month-$day $hour:$minute:$second';
    }
    return '$year-$month-$day $hour:$minute';
  }
}

/// Extension on [DateTime] providing utility methods for manipulating date components.
extension DateTimeFloor on DateTime {
  /// Snaps the [DateTime] down to the floor of the current hour.
  /// 
  /// For example, `14:45:30` becomes `14:00:00.000`.
  /// Returns a new [DateTime] instance.
  DateTime floorToHour() {
    return DateTime(year, month, day, hour);
  }
}
