import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

void main() {
  group('MacroCalc - existing methods', () {
    test('getTotalCarbsGoal with defaults', () {
      // 2000 * 0.6 / 4 = 300
      expect(MacroCalc.getTotalCarbsGoal(2000), 300.0);
    });

    test('getTotalFatsGoal with defaults', () {
      // 2000 * 0.25 / 9 ≈ 55.56
      expect(MacroCalc.getTotalFatsGoal(2000),
          closeTo(55.56, 0.01));
    });

    test('getTotalProteinsGoal with defaults', () {
      // 2000 * 0.15 / 4 = 75
      expect(MacroCalc.getTotalProteinsGoal(2000), 75.0);
    });
  });

  group('MacroCalc - getScaledMacroTargets', () {
    test('all percentages, no fixed overrides', () {
      final targets =
          MacroCalc.getScaledMacroTargets(allowance: 2000);
      // Defaults: 60% carbs, 25% fat, 15% protein
      expect(targets.carbsGrams, 300.0); // 2000*0.6/4
      expect(targets.fatGrams, closeTo(55.56, 0.01)); // 2000*0.25/9
      expect(targets.proteinGrams, 75.0); // 2000*0.15/4
    });

    test('fixed protein, remaining calories split to carbs and fat', () {
      // Fix protein at 150g = 600 kcal
      // Remaining: 2000 - 600 = 1400 kcal
      // carbs share: 0.6/(0.6+0.25) = 0.706
      // fat share: 0.25/(0.6+0.25) = 0.294
      final targets = MacroCalc.getScaledMacroTargets(
          allowance: 2000, fixedProteinGrams: 150);
      expect(targets.proteinGrams, 150.0);
      expect(targets.carbsGrams, closeTo(1400 * 0.706 / 4, 1));
      expect(targets.fatGrams, closeTo(1400 * 0.294 / 9, 1));
    });

    test('all fixed overrides', () {
      final targets = MacroCalc.getScaledMacroTargets(
        allowance: 2000,
        fixedProteinGrams: 100,
        fixedCarbsGrams: 200,
        fixedFatGrams: 50,
      );
      expect(targets.proteinGrams, 100.0);
      expect(targets.carbsGrams, 200.0);
      expect(targets.fatGrams, 50.0);
    });

    test('zero allowance returns fixed values or zero', () {
      final targets = MacroCalc.getScaledMacroTargets(
        allowance: 0,
        fixedProteinGrams: 50,
      );
      expect(targets.proteinGrams, 50.0);
      expect(targets.carbsGrams, 0.0);
      expect(targets.fatGrams, 0.0);
    });

    test('custom percentages', () {
      final targets = MacroCalc.getScaledMacroTargets(
        allowance: 2000,
        userCarbsPct: 0.5,
        userFatPct: 0.3,
        userProteinPct: 0.2,
      );
      expect(targets.carbsGrams, 250.0); // 2000*0.5/4
      expect(targets.fatGrams, closeTo(66.67, 0.01)); // 2000*0.3/9
      expect(targets.proteinGrams, 100.0); // 2000*0.2/4
    });

    test('negative allowance returns fixed values or zero', () {
      final targets = MacroCalc.getScaledMacroTargets(allowance: -100);
      expect(targets.carbsGrams, 0.0);
      expect(targets.fatGrams, 0.0);
      expect(targets.proteinGrams, 0.0);
    });

    test('fixed macros exceeding allowance clamp remaining to zero', () {
      // Fix protein at 200g = 800 kcal, which exceeds 500 allowance
      final targets = MacroCalc.getScaledMacroTargets(
        allowance: 500,
        fixedProteinGrams: 200,
      );
      expect(targets.proteinGrams, 200.0);
      expect(targets.carbsGrams, 0.0);
      expect(targets.fatGrams, 0.0);
    });

    test('MacroTargets equality', () {
      const a = MacroTargets(carbsGrams: 100, fatGrams: 50, proteinGrams: 75);
      const b = MacroTargets(carbsGrams: 100, fatGrams: 50, proteinGrams: 75);
      expect(a, b);
    });
  });
}
