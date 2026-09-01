/// A correction made from the diary moves that day's figures, not today's.
///
/// This is the quiet half of wiring up a tap on an older day. The home screen's
/// version of the same job reads `DateTime.now()` for the day to adjust, which
/// is right there and only there — the home screen only ever shows today.
/// Copied into the diary unchanged it would take an older row's old calories
/// off *today's* total and put the new ones back on today too, moving two days'
/// numbers at once and neither of them to the right thing. Nothing on screen
/// would say so: the row would show its correction and both totals would be
/// wrong afterwards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

/// The three dependencies this one method never reaches. Standing them up for
/// real would mean a health store and an activity table for a test about
/// arithmetic on two days.
class _Unused extends Fake
    implements
        GetUserActivityUsecase,
        DeleteIntakeUsecase,
        DeleteUserActivityUsecase,
        GetTrackedDayUsecase {}

void main() {
  final theDayItWasEaten = DateTime(2026, 8, 25, 8, 30);
  final today = DateTime.now();

  late AppDatabase db;
  late IntakeRepository intakes;
  late TrackedDayRepository days;
  late AddTrackedDayUsecase totals;

  setUp(() {
    db = AppDatabase.createInMemory();
    intakes = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    days = TrackedDayRepository(DailyStatsDao(db));
    totals = AddTrackedDayUsecase(days);
  });

  tearDown(() async => db.close());

  CalendarDayBloc theDiary() => CalendarDayBloc(
        _Unused(),
        GetIntakeUsecase(intakes),
        _Unused(),
        _Unused(),
        _Unused(),
        totals,
        UpdateIntakeUsecase(intakes, null),
      );

  /// One row of a hundred calories on the older day, with that day's totals
  /// already carrying it — the state the diary is in when he taps a row.
  Future<void> aRowOnTheOlderDay() async {
    await intakes.addQuickAddIntake(
      id: 'intake-oats',
      kcal: 100,
      protein: 4,
      carbs: 16,
      fat: 2,
      label: 'Overnight oats',
      mealSlot: 'breakfast',
      dateTime: theDayItWasEaten,
    );
    await totals.addNewTrackedDay(theDayItWasEaten, 2000, 250, 70, 150);
    await totals.addDayCaloriesTracked(theDayItWasEaten, 100);
    await totals.addNewTrackedDay(today, 2000, 250, 70, 150);
  }

  // Why the walkthrough step is allowed to be walked the way he walked it.
  //
  // Aidan skipped steps 5 and 6 on 1 September 2026 because the install had
  // wiped his diary, so he added an item to 25 August that same day and
  // corrected that instead: "I don't know if that tests what you're actually
  // asking me to test because I only just added it today even though I have
  // added it to a previous date." It does, and this is why: a diary row keeps
  // one time and it is the moment the food was eaten. Nothing anywhere records
  // when the row was written, so there is no field by which a row added today
  // for 25 August differs from one written on 25 August — the correction path
  // could not tell them apart if it wanted to.
  group('a row keeps no record of when it was written', () {
    test('the only time it carries is the day it is for', () async {
      final before = DateTime.now();
      await aRowOnTheOlderDay();

      final rows = await db.select(db.logEntries).get();
      final row = rows.singleWhere((r) => r.id == 'intake-oats');

      expect(DateTime.fromMillisecondsSinceEpoch(row.timestamp),
          theDayItWasEaten,
          reason: 'the day it was eaten, not the moment it was typed');
      expect(before.isAfter(theDayItWasEaten), isTrue,
          reason: 'and it really was written long after that day');
    });

    test('two rows written minutes apart come back indistinguishable',
        () async {
      // The same breakfast, on the same past day, written at two different
      // moments. If anything about the write moment reached the row, these
      // two would differ somewhere — and the moment they do, the step Aidan
      // walked stops being a fair test of the step he was asked to walk.
      Future<void> write(String id) => intakes.addQuickAddIntake(
            id: id,
            kcal: 100,
            protein: 4,
            carbs: 16,
            fat: 2,
            label: 'Overnight oats',
            mealSlot: 'breakfast',
            dateTime: theDayItWasEaten,
          );
      await write('intake-first');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await write('intake-second');

      final reader = GetIntakeUsecase(intakes);
      final first = await reader.getIntakeById('intake-first');
      final second = await reader.getIntakeById('intake-second');

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.props, isNotEmpty,
          reason: 'a comparison over nothing would pass over anything');
      // Everything that identifies the row, bar the id it was given.
      expect(first.props.where((p) => p != 'intake-first').toList(),
          second!.props.where((p) => p != 'intake-second').toList(),
          reason: 'nothing on a diary row says when it was written');
    });
  });

  test('the older day loses the old figure and gains the new one', () async {
    await aRowOnTheOlderDay();

    await theDiary()
        .updateIntakeItem('intake-oats', {'kcal': 200}, theDayItWasEaten);

    final thatDay = await days.getTrackedDay(theDayItWasEaten);
    expect(thatDay?.caloriesTracked, closeTo(200, 0.01),
        reason: '100 came off and 200 went back on, on the day it was eaten');
  });

  test('and today is left completely alone', () async {
    await aRowOnTheOlderDay();

    await theDiary()
        .updateIntakeItem('intake-oats', {'kcal': 200}, theDayItWasEaten);

    final now = await days.getTrackedDay(today);
    expect(now?.caloriesTracked ?? 0, 0,
        reason: 'a correction to 25 August must not touch what was eaten today');
  });
}
