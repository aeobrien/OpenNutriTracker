class MealSlotRange {
  final int startHour;
  final int endHour;

  const MealSlotRange(this.startHour, this.endHour);

  bool contains(int hour) => hour >= startHour && hour < endHour;
}

class MealSlotCalc {
  static const defaultRanges = {
    'breakfast': MealSlotRange(6, 10),
    'lunch': MealSlotRange(10, 14),
    'dinner': MealSlotRange(17, 21),
  };

  /// Suggests a meal slot based on the time of day.
  /// Returns "breakfast", "lunch", "dinner", or "snack".
  static String suggestSlot(DateTime timestamp,
      {Map<String, MealSlotRange>? ranges}) {
    final effectiveRanges = ranges ?? defaultRanges;
    final hour = timestamp.hour;

    for (final entry in effectiveRanges.entries) {
      if (entry.value.contains(hour)) {
        return entry.key;
      }
    }
    return 'snack';
  }
}
