class MacroTargets {
  final double carbsGrams;
  final double fatGrams;
  final double proteinGrams;

  const MacroTargets({
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinGrams,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroTargets &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams &&
          proteinGrams == other.proteinGrams;

  @override
  int get hashCode =>
      carbsGrams.hashCode ^ fatGrams.hashCode ^ proteinGrams.hashCode;

  @override
  String toString() =>
      'MacroTargets(carbs: $carbsGrams, fat: $fatGrams, protein: $proteinGrams)';
}

class MacroCalc {
  /// Information provided by
  /// 'OBESITY: PREVENTING AND MANAGING
  /// THE GLOBAL EPIDEMIC' by WHO page 104
  /// ISBN 92 4 120894 5
  /// ISSN 0512-3054
  static const carbsKcalPerGram = 4.0;
  static const fatKcalPerGram = 9.0;
  static const proteinKcalPerGram = 4.0;

  static const _defaultCarbsPercentageGoal = 0.6;
  static const _defaultFatsPercentageGoal = 0.25;
  static const _defaultProteinsPercentageGoal = 0.15;

  /// Calculate the total carbs goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalCarbsGoal(
          double totalCalorieGoal, {double? userCarbsGoal}) =>
      (totalCalorieGoal * (userCarbsGoal ?? _defaultCarbsPercentageGoal)) /
      carbsKcalPerGram;

  /// Calculate the total fats goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalFatsGoal(
          double totalCalorieGoal, {double? userFatsGoal}) =>
      (totalCalorieGoal * (userFatsGoal ?? _defaultFatsPercentageGoal)) /
      fatKcalPerGram;

  /// Calculate the total proteins goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalProteinsGoal(
          double totalCalorieGoal, {double? userProteinsGoal}) =>
      (totalCalorieGoal *
          (userProteinsGoal ?? _defaultProteinsPercentageGoal)) /
      proteinKcalPerGram;

  /// Compute macro targets with optional fixed-gram overrides.
  ///
  /// Fixed macros stay constant regardless of allowance. Remaining calories
  /// are allocated to non-fixed macros proportionally based on their
  /// percentage shares.
  static MacroTargets getScaledMacroTargets({
    required double allowance,
    double? fixedProteinGrams,
    double? fixedCarbsGrams,
    double? fixedFatGrams,
    double? userProteinPct,
    double? userCarbsPct,
    double? userFatPct,
  }) {
    if (allowance <= 0) {
      return MacroTargets(
        carbsGrams: fixedCarbsGrams ?? 0,
        fatGrams: fixedFatGrams ?? 0,
        proteinGrams: fixedProteinGrams ?? 0,
      );
    }

    // Calculate calories consumed by fixed macros
    double fixedCalories = 0;
    if (fixedProteinGrams != null) {
      fixedCalories += fixedProteinGrams * proteinKcalPerGram;
    }
    if (fixedCarbsGrams != null) {
      fixedCalories += fixedCarbsGrams * carbsKcalPerGram;
    }
    if (fixedFatGrams != null) {
      fixedCalories += fixedFatGrams * fatKcalPerGram;
    }

    final remainingCalories = (allowance - fixedCalories).clamp(0, double.infinity);

    // Determine percentages for non-fixed macros
    final proteinPct = userProteinPct ?? _defaultProteinsPercentageGoal;
    final carbsPct = userCarbsPct ?? _defaultCarbsPercentageGoal;
    final fatPct = userFatPct ?? _defaultFatsPercentageGoal;

    // Sum of non-fixed percentages for proportional allocation
    double nonFixedPctSum = 0;
    if (fixedProteinGrams == null) nonFixedPctSum += proteinPct;
    if (fixedCarbsGrams == null) nonFixedPctSum += carbsPct;
    if (fixedFatGrams == null) nonFixedPctSum += fatPct;

    double allocate(double pct, double kcalPerGram) {
      if (nonFixedPctSum <= 0) return 0;
      return (remainingCalories * (pct / nonFixedPctSum)) / kcalPerGram;
    }

    return MacroTargets(
      proteinGrams: fixedProteinGrams ??
          allocate(proteinPct, proteinKcalPerGram),
      carbsGrams: fixedCarbsGrams ??
          allocate(carbsPct, carbsKcalPerGram),
      fatGrams: fixedFatGrams ??
          allocate(fatPct, fatKcalPerGram),
    );
  }
}
