import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

/// High-level unit converter that applies metric/imperial conversions
/// based on the user's preference. All stored values remain metric
/// internally; this class handles display conversion only.
class UnitConverter {
  static final _log = Logger('UnitConverter');

  /// Converts a weight value for display based on unit preference.
  /// [metricValue] is always in grams.
  /// Returns the value in grams (metric) or ounces (imperial).
  static double displayWeight(double metricValue, {required bool imperial}) {
    if (!imperial) return metricValue;
    return UnitCalc.gToOz(metricValue);
  }

  /// Converts a volume value for display based on unit preference.
  /// [metricValue] is always in millilitres.
  /// Returns the value in ml (metric) or fl oz (imperial).
  static double displayVolume(double metricValue, {required bool imperial}) {
    if (!imperial) return metricValue;
    return UnitCalc.mlToFlOz(metricValue);
  }

  /// Converts a body weight value for display based on unit preference.
  /// [metricValue] is always in kilograms.
  /// Returns the value in kg (metric) or lb (imperial).
  static double displayBodyWeight(double metricValue,
      {required bool imperial}) {
    if (!imperial) return metricValue;
    return UnitCalc.kgToLbs(metricValue);
  }

  /// Converts a display value back to metric for storage.
  /// [displayValue] is in the user's preferred unit system.
  /// [unit] identifies the unit type: 'g', 'ml', 'kg', 'oz', 'fl oz', 'lb'.
  static double toMetric(double displayValue, String unit) {
    switch (unit) {
      case 'oz':
        return UnitCalc.ozToG(displayValue);
      case 'fl oz' || 'fl.oz':
        return UnitCalc.flOzToMl(displayValue);
      case 'lb' || 'lbs':
        return UnitCalc.lbsToKg(displayValue);
      default:
        // Already metric (g, ml, kg) — no conversion needed
        return displayValue;
    }
  }

  /// Returns the display unit label for a food weight.
  static String weightUnitLabel({required bool imperial}) {
    return imperial ? 'oz' : 'g';
  }

  /// Returns the display unit label for a food volume.
  static String volumeUnitLabel({required bool imperial}) {
    return imperial ? 'fl oz' : 'ml';
  }

  /// Returns the display unit label for body weight.
  static String bodyWeightUnitLabel({required bool imperial}) {
    return imperial ? 'lb' : 'kg';
  }

  /// Convenience: converts a metric food amount for display, auto-detecting
  /// whether the food uses weight or volume based on [mealUnit].
  static double displayFoodAmount(double metricValue, String? mealUnit,
      {required bool imperial}) {
    if (!imperial) return metricValue;
    if (mealUnit == 'ml' || mealUnit == 'l' || mealUnit == 'dl' || mealUnit == 'cl') {
      return displayVolume(metricValue, imperial: imperial);
    }
    return displayWeight(metricValue, imperial: imperial);
  }

  /// Returns the appropriate display unit label for a food item.
  static String foodUnitLabel(String? mealUnit, {required bool imperial}) {
    if (!imperial) return mealUnit ?? 'g';
    if (mealUnit == 'ml' || mealUnit == 'l' || mealUnit == 'dl' || mealUnit == 'cl') {
      return volumeUnitLabel(imperial: imperial);
    }
    return weightUnitLabel(imperial: imperial);
  }
}
