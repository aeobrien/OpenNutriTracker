class TrackedDay {
  final double target;
  final double intake;
  final double carbsTarget;
  final double carbsIntake;
  final double fatTarget;
  final double fatIntake;
  final double proteinTarget;
  final double proteinIntake;

  const TrackedDay({
    required this.target,
    required this.intake,
    this.carbsTarget = 0,
    this.carbsIntake = 0,
    this.fatTarget = 0,
    this.fatIntake = 0,
    this.proteinTarget = 0,
    this.proteinIntake = 0,
  });
}

class MacroTotals {
  final double carbsTarget;
  final double carbsIntake;
  final double fatTarget;
  final double fatIntake;
  final double proteinTarget;
  final double proteinIntake;

  const MacroTotals({
    required this.carbsTarget,
    required this.carbsIntake,
    required this.fatTarget,
    required this.fatIntake,
    required this.proteinTarget,
    required this.proteinIntake,
  });
}

class WeeklySummary {
  final double totalTarget;
  final double totalIntake;
  final double totalRemaining;
  final int daysTracked;
  final MacroTotals macroTotals;

  const WeeklySummary({
    required this.totalTarget,
    required this.totalIntake,
    required this.totalRemaining,
    required this.daysTracked,
    required this.macroTotals,
  });
}

class WeeklyCalc {
  /// Aggregates a list of tracked days into a weekly summary.
  static WeeklySummary aggregate(List<TrackedDay> days) {
    double totalTarget = 0;
    double totalIntake = 0;
    double carbsTarget = 0;
    double carbsIntake = 0;
    double fatTarget = 0;
    double fatIntake = 0;
    double proteinTarget = 0;
    double proteinIntake = 0;

    for (final day in days) {
      totalTarget += day.target;
      totalIntake += day.intake;
      carbsTarget += day.carbsTarget;
      carbsIntake += day.carbsIntake;
      fatTarget += day.fatTarget;
      fatIntake += day.fatIntake;
      proteinTarget += day.proteinTarget;
      proteinIntake += day.proteinIntake;
    }

    return WeeklySummary(
      totalTarget: totalTarget,
      totalIntake: totalIntake,
      totalRemaining: totalTarget - totalIntake,
      daysTracked: days.length,
      macroTotals: MacroTotals(
        carbsTarget: carbsTarget,
        carbsIntake: carbsIntake,
        fatTarget: fatTarget,
        fatIntake: fatIntake,
        proteinTarget: proteinTarget,
        proteinIntake: proteinIntake,
      ),
    );
  }
}
