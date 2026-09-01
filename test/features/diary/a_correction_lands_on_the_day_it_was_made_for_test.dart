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
