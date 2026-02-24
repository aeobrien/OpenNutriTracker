import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class LabelScanScreenArguments {
  final DateTime day;
  final IntakeTypeEntity? intakeType;

  /// When true, the screen returns a [LabelScanIngredientResult] via pop
  /// instead of logging an intake entry.
  final bool ingredientMode;

  const LabelScanScreenArguments({
    required this.day,
    this.intakeType,
    this.ingredientMode = false,
  });
}

/// Returned when label scan is opened in ingredient mode.
class LabelScanIngredientResult {
  final String name;
  final String? foodItemId;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  const LabelScanIngredientResult({
    required this.name,
    this.foodItemId,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
  });
}
