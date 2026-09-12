import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/weekly_calc.dart';

void main() {
  group('WeeklyCalc', () {
    test('full week aggregation', () {
      final days = List.generate(
          7,
          (_) => const TrackedDay(
                target: 2000,
                intake: 1800,
                carbsTarget: 300,
                carbsIntake: 250,
                fatTarget: 55,
                fatIntake: 50,
                proteinTarget: 75,
                proteinIntake: 70,
              ));
      final summary = WeeklyCalc.aggregate(days);
      expect(summary.totalTarget, 14000);
      expect(summary.totalIntake, 12600);
      expect(summary.totalRemaining, 1400);
      expect(summary.daysTracked, 7);
      expect(summary.macroTotals.carbsTarget, 2100);
      expect(summary.macroTotals.carbsIntake, 1750);
    });

    test('partial week (3 days)', () {
      final days = [
        const TrackedDay(target: 2000, intake: 1900),
        const TrackedDay(target: 2000, intake: 2100),
        const TrackedDay(target: 2000, intake: 2000),
      ];
      final summary = WeeklyCalc.aggregate(days);
      expect(summary.daysTracked, 3);
      expect(summary.totalTarget, 6000);
      expect(summary.totalIntake, 6000);
      expect(summary.totalRemaining, 0);
    });

    test('empty list', () {
      final summary = WeeklyCalc.aggregate([]);
      expect(summary.daysTracked, 0);
      expect(summary.totalTarget, 0);
      expect(summary.totalIntake, 0);
      expect(summary.totalRemaining, 0);
    });

    test('all over target', () {
      final days = [
        const TrackedDay(target: 2000, intake: 2500),
        const TrackedDay(target: 2000, intake: 2300),
      ];
      final summary = WeeklyCalc.aggregate(days);
      expect(summary.totalRemaining, -800); // 4000 - 4800
    });

    test('mixed days with macros', () {
      final days = [
        const TrackedDay(
          target: 2000,
          intake: 1500,
          proteinTarget: 75,
          proteinIntake: 80,
        ),
        const TrackedDay(
          target: 2200,
          intake: 2400,
          proteinTarget: 82,
          proteinIntake: 60,
        ),
      ];
      final summary = WeeklyCalc.aggregate(days);
      expect(summary.totalTarget, 4200);
      expect(summary.totalIntake, 3900);
      expect(summary.totalRemaining, 300);
      expect(summary.macroTotals.proteinTarget, 157);
      expect(summary.macroTotals.proteinIntake, 140);
    });
  });
}
