class DayBoundaryCalc {
  static const int defaultDayStartHour = 2;

  /// Returns the "logical date" for a given timestamp.
  /// If the time is before [dayStartHour], it belongs to the previous calendar day.
  static DateTime logicalDate(DateTime timestamp,
      {int dayStartHour = defaultDayStartHour}) {
    if (timestamp.hour < dayStartHour) {
      final yesterday = timestamp.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }
    return DateTime(timestamp.year, timestamp.month, timestamp.day);
  }

  /// Returns the start of the logical day (date at [dayStartHour]).
  static DateTime dayStart(DateTime date,
      {int dayStartHour = defaultDayStartHour}) {
    return DateTime(date.year, date.month, date.day, dayStartHour);
  }

  /// Returns the end of the logical day (next day at [dayStartHour] minus 1ms).
  static DateTime dayEnd(DateTime date,
      {int dayStartHour = defaultDayStartHour}) {
    final nextDay = DateTime(date.year, date.month, date.day + 1, dayStartHour);
    return nextDay.subtract(const Duration(milliseconds: 1));
  }
}
