import 'package:flutter_test/flutter_test.dart';

/// Tests for the calendar dot cleanup logic.
/// Validates that tracked days are correctly identified as empty,
/// accounting for floating-point tolerance.
void main() {
  group('Calendar dot cleanup — isDayEmpty logic', () {
    test('day with zero calories and macros is empty', () {
      expect(isDayEmpty(0.0, 0.0, 0.0, 0.0), true);
    });

    test('day with positive calories is not empty', () {
      expect(isDayEmpty(100.0, 0.0, 0.0, 0.0), false);
    });

    test('day with positive carbs only is not empty', () {
      expect(isDayEmpty(0.0, 10.0, 0.0, 0.0), false);
    });

    test('day with positive fat only is not empty', () {
      expect(isDayEmpty(0.0, 0.0, 5.0, 0.0), false);
    });

    test('day with positive protein only is not empty', () {
      expect(isDayEmpty(0.0, 0.0, 0.0, 8.0), false);
    });

    test('day with floating-point residual calories is empty', () {
      // Simulates adding 100 kcal then subtracting 100 kcal, leaving
      // a tiny floating-point residual
      final residual = 100.0 - 99.99999999999999;
      expect(isDayEmpty(residual, 0.0, 0.0, 0.0), true);
    });

    test('day with floating-point residual macros is empty', () {
      final residual = 50.0 - 49.99999999999999;
      expect(isDayEmpty(0.0, residual, residual, residual), true);
    });

    test('day with null macros is treated as zero', () {
      expect(isDayEmpty(0.0, null, null, null), true);
    });

    test('day with calories just above tolerance is not empty', () {
      expect(isDayEmpty(0.02, 0.0, 0.0, 0.0), false);
    });
  });
}

/// Pure function mirroring TrackedDayRepository.deleteDayIfEmpty logic.
bool isDayEmpty(
    double caloriesTracked, double? carbsTracked, double? fatTracked, double? proteinTracked) {
  const tolerance = 0.01;
  final hasCalories = caloriesTracked > tolerance;
  final hasMacros = (carbsTracked ?? 0) > tolerance ||
      (fatTracked ?? 0) > tolerance ||
      (proteinTracked ?? 0) > tolerance;
  return !hasCalories && !hasMacros;
}
