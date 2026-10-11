enum ValidationStatus { ok, reviewRecommended, likelyError }

class ValidationResult {
  final double calculatedKcal;
  final double deviationPct;
  final ValidationStatus status;

  const ValidationResult({
    required this.calculatedKcal,
    required this.deviationPct,
    required this.status,
  });

  @override
  String toString() =>
      'ValidationResult(calculated: $calculatedKcal, deviation: ${deviationPct.toStringAsFixed(1)}%, status: $status)';
}

class NutritionValidator {
  static const double _proteinKcalPerGram = 4.0;
  static const double _carbsKcalPerGram = 4.0;
  static const double _fatKcalPerGram = 9.0;
  static const double _fibreKcalPerGram = 2.0;

  /// Validates consistency between reported kcal and macronutrient values
  /// using Atwater factors.
  ///
  /// If [fibreGrams] is provided, fibre is subtracted from carbs and counted
  /// at 2 kcal/g instead of 4 kcal/g.
  static ValidationResult validateConsistency({
    required double reportedKcal,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    double? fibreGrams,
  }) {
    double calculatedKcal;

    if (fibreGrams != null && fibreGrams > 0) {
      final digestibleCarbs = (carbsGrams - fibreGrams).clamp(0, double.infinity);
      calculatedKcal = (proteinGrams * _proteinKcalPerGram) +
          (digestibleCarbs * _carbsKcalPerGram) +
          (fibreGrams * _fibreKcalPerGram) +
          (fatGrams * _fatKcalPerGram);
    } else {
      calculatedKcal = (proteinGrams * _proteinKcalPerGram) +
          (carbsGrams * _carbsKcalPerGram) +
          (fatGrams * _fatKcalPerGram);
    }

    // Handle zero reported kcal
    double deviationPct;
    if (reportedKcal == 0 && calculatedKcal == 0) {
      deviationPct = 0;
    } else if (reportedKcal == 0) {
      deviationPct = 100;
    } else {
      deviationPct =
          ((calculatedKcal - reportedKcal).abs() / reportedKcal) * 100;
    }

    ValidationStatus status;
    if (deviationPct <= 15) {
      status = ValidationStatus.ok;
    } else if (deviationPct <= 40) {
      status = ValidationStatus.reviewRecommended;
    } else {
      status = ValidationStatus.likelyError;
    }

    return ValidationResult(
      calculatedKcal: calculatedKcal,
      deviationPct: deviationPct,
      status: status,
    );
  }
}
