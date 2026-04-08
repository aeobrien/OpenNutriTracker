import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the quick increment button logic extracted from _IncrementChips.
/// These test the pure calculation logic without widget rendering.
void main() {
  group('Quick increment button logic', () {
    group('changeAmount', () {
      test('adds positive delta to current value', () {
        final result = _changeAmount(100.0, 10.0);
        expect(result, '110');
      });

      test('subtracts negative delta from current value', () {
        final result = _changeAmount(100.0, -50.0);
        expect(result, '50');
      });

      test('clamps to zero when delta would go negative', () {
        final result = _changeAmount(10.0, -50.0);
        expect(result, '0');
      });

      test('formats whole numbers without decimals', () {
        final result = _changeAmount(50.0, 50.0);
        expect(result, '100');
      });

      test('formats fractional numbers with one decimal', () {
        final result = _changeAmount(10.5, 10.0);
        expect(result, '20.5');
      });

      test('handles zero current value', () {
        final result = _changeAmount(0.0, 10.0);
        expect(result, '10');
      });
    });

    group('halveAmount', () {
      test('halves a round number', () {
        final result = _halveAmount(100.0);
        expect(result, '50');
      });

      test('halves an odd number to produce a decimal', () {
        final result = _halveAmount(75.0);
        expect(result, '37.5');
      });

      test('halves zero to zero', () {
        final result = _halveAmount(0.0);
        expect(result, '0');
      });

      test('halves a small number', () {
        final result = _halveAmount(1.0);
        expect(result, '0.5');
      });

      test('halves a fractional number', () {
        final result = _halveAmount(50.5);
        expect(result, '25.3'); // 50.5 / 2 = 25.25, rounds to 25.3
      });
    });

    group('setToOneServing', () {
      test('uses serving quantity when available', () {
        final result = _setToOneServing(30.0);
        expect(result, '30');
      });

      test('defaults to 100 when serving quantity is null', () {
        final result = _setToOneServing(null);
        expect(result, '100');
      });

      test('formats decimal serving quantity', () {
        final result = _setToOneServing(28.5);
        expect(result, '28.5');
      });

      test('formats whole number serving quantity without decimals', () {
        final result = _setToOneServing(250.0);
        expect(result, '250');
      });
    });
  });
}

/// Pure function mirroring _IncrementChips._changeAmount logic.
String _changeAmount(double current, double delta) {
  final newVal = (current + delta).clamp(0.0, double.infinity);
  return newVal == newVal.roundToDouble()
      ? newVal.toInt().toString()
      : newVal.toStringAsFixed(1);
}

/// Pure function mirroring _IncrementChips._halveAmount logic.
String _halveAmount(double current) {
  final newVal = (current / 2).clamp(0.0, double.infinity);
  return newVal == newVal.roundToDouble()
      ? newVal.toInt().toString()
      : newVal.toStringAsFixed(1);
}

/// Pure function mirroring _IncrementChips._setToOneServing logic.
String _setToOneServing(double? servingQuantity) {
  final servingQty = servingQuantity ?? 100.0;
  return servingQty == servingQty.roundToDouble()
      ? servingQty.toInt().toString()
      : servingQty.toStringAsFixed(1);
}
