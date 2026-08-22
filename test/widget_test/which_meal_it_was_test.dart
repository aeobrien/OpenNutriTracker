/// Choosing which meal of the day a row sits under, on the dialog itself.
///
/// putting_a_row_under_another_meal_test.dart settles what happens to the row
/// once the dialog has asked for it. This file is the other half: that the
/// control is there, that it opens on the meal the row is already under, and
/// that leaving it alone asks for nothing.
///
/// The last one is the one worth holding. This control starts on a real value
/// rather than on nothing, so "I did not touch it" and "I chose the one it
/// already had" look identical on screen — and only one of them should send a
/// correction.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/what_it_was.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

/// A house that has never said who else lives here, so the "whose day is it"
/// control stays away and this file is only about the meal.
class _QuietHousehold extends Fake implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => null;
}

class _QuietLedger extends Fake implements FoodLedger {
  final List<WhatItWas> versions;

  _QuietLedger([this.versions = const []]);

  @override
  Future<List<WhatItWas>> historyOf(String intakeId) async => versions;
}

/// One earlier version of the row, offering its own way back.
final _anOlderVersion = WhatItWas(
  version: 0,
  what: 'corrected',
  snapshot: const {'label': 'Cheese sandwich', 'qty': 1, 'kcal': 300},
  putBack: const {'label': 'Cheese sandwich', 'qty': 1, 'kcal': 300},
);

IntakeEntity _row(IntakeTypeEntity under) => IntakeEntity(
      id: 'intake-abc',
      unit: 'serving',
      amount: 1,
      type: under,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 22, 19, 30),
      entryType: 'quickAdd',
      quickAddLabel: 'Cheese sandwich',
      snapshotKcal: 420,
      thisPhoneDidIt: true,
    );

Widget _aRowYouCanTap(IntakeTypeEntity under, List<IntakeEdit> given,
        {List<WhatItWas> history = const []}) =>
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final edit = await showDialog<IntakeEdit>(
                context: context,
                builder: (_) => EditDialog(
                  intakeEntity: _row(under),
                  usesImperialUnits: false,
                  ledger: _QuietLedger(history),
                ),
              );
              if (edit != null) given.add(edit);
            },
            child: const Text('Cheese sandwich'),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<HomeBloc>(_QuietHomeBloc())
      ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc())
      ..registerSingleton<HouseholdRepository>(_QuietHousehold());
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openIt(WidgetTester tester) async {
    await tester.tap(find.text('Cheese sandwich').first);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String meal) async {
    await tester.tap(find.byType(DropdownButtonFormField<IntakeTypeEntity>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(meal).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('the dialog asks which meal it was', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, []));
    await openIt(tester);

    expect(find.text(EditDialog.whichMealLabel), findsOneWidget);
  });

  testWidgets('it opens on the meal the row is already under', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, []));
    await openIt(tester);

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);
  });

  testWidgets('choosing another one asks for the move', (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, given));
    await openIt(tester);
    await choose(tester, 'Lunch');
    await save(tester);

    expect(given.single.slot, 'lunch');
    expect(given.single.fields['slot'], 'lunch');
  });

  testWidgets('leaving it alone asks for nothing', (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, given));
    await openIt(tester);
    await save(tester);

    expect(given.single.slot, isNull);
    expect(given.single.fields.containsKey('slot'), isFalse,
        reason: 'a correction nobody asked for still bumps the row at the '
            'house and discards anything on the wire for it');
  });

  testWidgets('choosing the one it already had asks for nothing either',
      (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, given));
    await openIt(tester);
    await choose(tester, 'Dinner');
    await save(tester);

    expect(given.single.slot, isNull);
  });

  testWidgets('all four meals are offered', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.snack, []));
    await openIt(tester);
    await tester.tap(find.byType(DropdownButtonFormField<IntakeTypeEntity>));
    await tester.pumpAndSettle();

    for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
      expect(find.text(meal), findsWidgets, reason: '$meal is missing');
    }
  });

  testWidgets('putting an older version back leaves the meal alone',
      (tester) async {
    // Restoring says what the row said, not where it sat. The meal of the day
    // and the date stay as they are now on purpose: a version from before a
    // slot correction would otherwise silently undo that correction too, and
    // nothing on screen said it would.
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(IntakeTypeEntity.dinner, given,
        history: [_anOlderVersion]));
    await openIt(tester);
    // Moved first, so this is not passing simply because nothing was touched.
    await choose(tester, 'Lunch');
    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    expect(given.single.kcal, 300, reason: 'sanity: it really did restore');
    expect(given.single.slot, isNull);
  });
}
