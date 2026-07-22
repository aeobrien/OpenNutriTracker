import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

void main() {
  group('DayBoundaryCalc', () {
    test('logicalDate at midnight belongs to previous day', () {
      final ts = DateTime(2025, 3, 15, 0, 0); // midnight Mar 15
      final result = DayBoundaryCalc.logicalDate(ts);
      expect(result, DateTime(2025, 3, 14));
    });

    test('logicalDate at 1AM belongs to previous day', () {
      final ts = DateTime(2025, 3, 15, 1, 30);
      final result = DayBoundaryCalc.logicalDate(ts);
      expect(result, DateTime(2025, 3, 14));
    });

    test('logicalDate at 3AM belongs to today', () {
      final ts = DateTime(2025, 3, 15, 3, 0);
      final result = DayBoundaryCalc.logicalDate(ts);
      expect(result, DateTime(2025, 3, 15));
    });

    test('logicalDate at exactly dayStartHour belongs to today', () {
      final ts = DateTime(2025, 3, 15, 2, 0);
      final result = DayBoundaryCalc.logicalDate(ts);
      expect(result, DateTime(2025, 3, 15));
    });

    test('logicalDate with custom dayStartHour', () {
      final ts = DateTime(2025, 3, 15, 3, 0);
      final result = DayBoundaryCalc.logicalDate(ts, dayStartHour: 4);
      expect(result, DateTime(2025, 3, 14)); // 3AM < 4AM → yesterday
    });

    test('logicalDate at month boundary (midnight April 1 → March 31)', () {
      final ts = DateTime(2025, 4, 1, 0, 30);
      final result = DayBoundaryCalc.logicalDate(ts);
      expect(result, DateTime(2025, 3, 31));
    });

    test('dayStart returns date at dayStartHour', () {
      final date = DateTime(2025, 3, 15);
      final result = DayBoundaryCalc.dayStart(date);
      expect(result, DateTime(2025, 3, 15, 2));
    });

    test('dayEnd returns next day dayStartHour minus 1ms', () {
      final date = DateTime(2025, 3, 15);
      final result = DayBoundaryCalc.dayEnd(date);
      expect(result.year, 2025);
      expect(result.month, 3);
      expect(result.day, 16);
      expect(result.hour, 1);
      expect(result.minute, 59);
      expect(result.second, 59);
      expect(result.millisecond, 999);
    });
  });
}
