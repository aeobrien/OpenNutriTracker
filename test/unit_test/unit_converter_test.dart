import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    group('displayWeight', () {
      test('returns grams unchanged when metric', () {
        expect(UnitConverter.displayWeight(100, imperial: false), 100.0);
      });

      test('converts grams to ounces when imperial', () {
        final result = UnitConverter.displayWeight(28.3495, imperial: true);
        expect(result, closeTo(1.0, 0.001));
      });

      test('handles zero grams', () {
        expect(UnitConverter.displayWeight(0, imperial: true), 0.0);
      });
    });

    group('displayVolume', () {
      test('returns ml unchanged when metric', () {
        expect(UnitConverter.displayVolume(250, imperial: false), 250.0);
      });

      test('converts ml to fl oz when imperial', () {
        final result = UnitConverter.displayVolume(29.5735, imperial: true);
        expect(result, closeTo(1.0, 0.001));
      });

      test('handles zero ml', () {
        expect(UnitConverter.displayVolume(0, imperial: true), 0.0);
      });
    });

    group('displayBodyWeight', () {
      test('returns kg unchanged when metric', () {
        expect(UnitConverter.displayBodyWeight(70, imperial: false), 70.0);
      });

      test('converts kg to lbs when imperial', () {
        final result = UnitConverter.displayBodyWeight(1, imperial: true);
        // 1 kg = ~2.205 lbs, rounded to nearest whole
        expect(result, closeTo(2.0, 1.0));
      });

      test('handles zero kg', () {
        expect(UnitConverter.displayBodyWeight(0, imperial: true), 0.0);
      });
    });

    group('toMetric', () {
      test('converts oz to grams', () {
        final result = UnitConverter.toMetric(1.0, 'oz');
        expect(result, closeTo(28.3495, 0.01));
      });

      test('converts fl oz to ml', () {
        final result = UnitConverter.toMetric(1.0, 'fl oz');
        expect(result, closeTo(29.5735, 0.01));
      });

      test('converts fl.oz to ml', () {
        final result = UnitConverter.toMetric(1.0, 'fl.oz');
        expect(result, closeTo(29.5735, 0.01));
      });

      test('converts lb to kg', () {
        final result = UnitConverter.toMetric(2.20462, 'lb');
        expect(result, closeTo(1.0, 0.5));
      });

      test('converts lbs to kg', () {
        final result = UnitConverter.toMetric(2.20462, 'lbs');
        expect(result, closeTo(1.0, 0.5));
      });

      test('returns grams unchanged', () {
        expect(UnitConverter.toMetric(100.0, 'g'), 100.0);
      });

      test('returns ml unchanged', () {
        expect(UnitConverter.toMetric(250.0, 'ml'), 250.0);
      });

      test('returns kg unchanged', () {
        expect(UnitConverter.toMetric(70.0, 'kg'), 70.0);
      });
    });

    group('unit labels', () {
      test('weight unit is g for metric', () {
        expect(UnitConverter.weightUnitLabel(imperial: false), 'g');
      });

      test('weight unit is oz for imperial', () {
        expect(UnitConverter.weightUnitLabel(imperial: true), 'oz');
      });

      test('volume unit is ml for metric', () {
        expect(UnitConverter.volumeUnitLabel(imperial: false), 'ml');
      });

      test('volume unit is fl oz for imperial', () {
        expect(UnitConverter.volumeUnitLabel(imperial: true), 'fl oz');
      });

      test('body weight unit is kg for metric', () {
        expect(UnitConverter.bodyWeightUnitLabel(imperial: false), 'kg');
      });

      test('body weight unit is lb for imperial', () {
        expect(UnitConverter.bodyWeightUnitLabel(imperial: true), 'lb');
      });
    });

    group('displayFoodAmount', () {
      test('returns metric value when not imperial', () {
        expect(
            UnitConverter.displayFoodAmount(100, 'g', imperial: false), 100.0);
      });

      test('converts solid food to oz when imperial', () {
        final result =
            UnitConverter.displayFoodAmount(28.3495, 'g', imperial: true);
        expect(result, closeTo(1.0, 0.001));
      });

      test('converts liquid food to fl oz when imperial', () {
        final result =
            UnitConverter.displayFoodAmount(29.5735, 'ml', imperial: true);
        expect(result, closeTo(1.0, 0.001));
      });

      test('treats null mealUnit as weight', () {
        final result =
            UnitConverter.displayFoodAmount(28.3495, null, imperial: true);
        expect(result, closeTo(1.0, 0.001));
      });
    });

    group('foodUnitLabel', () {
      test('returns original unit when metric', () {
        expect(UnitConverter.foodUnitLabel('g', imperial: false), 'g');
        expect(UnitConverter.foodUnitLabel('ml', imperial: false), 'ml');
      });

      test('returns oz for solid when imperial', () {
        expect(UnitConverter.foodUnitLabel('g', imperial: true), 'oz');
      });

      test('returns fl oz for liquid when imperial', () {
        expect(UnitConverter.foodUnitLabel('ml', imperial: true), 'fl oz');
      });

      test('returns g for null mealUnit when metric', () {
        expect(UnitConverter.foodUnitLabel(null, imperial: false), 'g');
      });
    });

    group('round-trip conversions', () {
      test('g -> oz -> g preserves value', () {
        const original = 500.0;
        final oz = UnitConverter.displayWeight(original, imperial: true);
        final restored = UnitConverter.toMetric(oz, 'oz');
        expect(restored, closeTo(original, 0.01));
      });

      test('ml -> fl oz -> ml preserves value', () {
        const original = 330.0;
        final flOz = UnitConverter.displayVolume(original, imperial: true);
        final restored = UnitConverter.toMetric(flOz, 'fl oz');
        expect(restored, closeTo(original, 0.01));
      });
    });
  });
}
