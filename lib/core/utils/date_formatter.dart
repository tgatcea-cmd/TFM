class AppDateFormatter {
  /// Format a DateTime, int timestamp (ms), or ISO string into uniform app-wide format:
  /// `YYYY-MM-DD HH:mm:ss` (or `YYYY-MM-DD HH:mm` if showSeconds is false)
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

extension DateTimeFloor on DateTime {
  /// Snaps a DateTime down to the floor hour (:00:00.000)
  DateTime floorToHour() {
    return DateTime(year, month, day, hour);
  }
}
