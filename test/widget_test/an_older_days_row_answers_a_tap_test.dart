/// Tapping a row on a day that is not today.
///
/// Aidan, 1 September 2026, on the day he was asked to correct an older entry:
/// *"Tapping this item or any of these items on this day does nothing at all.
/// If I press and hold on the item, I see a modal asking what I want to do,
/// giving me the option to delete or copy to today, but simply tapping the
/// items does nothing"*.
///
/// The row was alive — holding it worked. The day screen wired up holding a
/// card and never wired up tapping one, so [IntakeCard] was handed a null tap
/// and did the only thing it could with it. On today's screen the same card is
/// handed a real one, which is why the same gesture on the same widget worked
/// an hour earlier in the same sitting and made the dead one look like a
/// mystery rather than a gap.
///
/// Correcting a meal you logged yesterday is the ordinary case, not the exotic
/// one: it is at the end of the day that you notice you put down the wrong
/// amount.
library;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The row strip fetches this from the locator when it is built and does not
/// use it unless something is tapped through to a food's own screen, which
/// this test never does.
class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

class _QuietHomeBloc extends Fake implements HomeBloc {}

void main() {
  setUp(() => GetIt.instance
    ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc())
    ..registerSingleton<HomeBloc>(_QuietHomeBloc()));
  tearDown(() => GetIt.instance.reset());

  final anOlderDay = DateTime(2026, 8, 25);

  final aRowOnThatDay = IntakeEntity(
    id: 'intake-oats',
    unit: 'g',
    amount: 100.0,
    type: IntakeTypeEntity.breakfast,
    meal: MealEntity.empty(),
    dateTime: anOlderDay,
    entryType: 'quickAdd',
    quickAddLabel: 'Overnight oats',
    snapshotKcal: 276,
  );

  Widget theDayScreen({required void Function(IntakeEntity) whenTapped}) {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayInfoWidget(
            selectedDay: anOlderDay,
            trackedDayEntity: null,
            userActivities: const [],
            breakfastIntake: [aRowOnThatDay],
            lunchIntake: const [],
            dinnerIntake: const [],
            snackIntake: const [],
            usesImperialUnits: false,
            onDeleteIntake: (_, __) {},
            onDeleteActivity: (_, __) {},
            onCopyIntake: (_, __, ___) {},
            onCopyActivity: (_, __) {},
            onIntakeItemTapped: (_, intake, __) => whenTapped(intake),
          ),
        ),
      ),
    );
  }

  testWidgets('reaches the thing that corrects it', (tester) async {
    final tapped = <IntakeEntity>[];
    await tester.pumpWidget(theDayScreen(whenTapped: tapped.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Overnight oats').first);
    await tester.pumpAndSettle();

    expect(tapped, hasLength(1),
        reason: 'a tap on an older day must reach the same place as a tap on '
            'today, or the row can be read and never corrected');
    expect(tapped.single.id, 'intake-oats');
  });
}
