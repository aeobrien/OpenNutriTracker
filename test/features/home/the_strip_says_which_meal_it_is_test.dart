/// A ghost card answered under Dinner is answered as dinner.
///
/// Behaviour under test: when somebody taps a planned meal to confirm it, the
/// answer carries which meal of the day it was, and that word comes from the
/// strip the card was sitting in.
///
/// This file exists because of a bug Aidan found on his phone on 22 August.
/// Tonight's chicken katsu appeared correctly under Dinner, he tapped it at
/// about a quarter to one, and it landed under Lunch. Nothing in the answer
/// said which meal it was, so the Mac Mini fell back to the clock, and the
/// clock said lunch.
///
/// The plan cannot supply the missing word — a plan is one meal against a date
/// and does not know it is dinner. The strip does, because it is the dinner
/// strip. So the test that matters is the second one: the same card in a
/// different strip answers with that strip's meal, which is what proves the
/// word is read off the list rather than written in as 'dinner' somewhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

import 'a_home_that_can_be_driven.dart';

void main() {
  const katsu = PlannedItem(
    planId: 30,
    title: 'Chicken katsu',
    portions: 1.5,
    kcal: 700,
    mealKcalKnown: true,
  );

  late String? answeredWith;

  setUp(() {
    answeredWith = null;
    // The list reaches into the locator the moment it is built. Nothing in
    // this file drives what it finds there — it is only asked to exist.
    ADrivableHome().register();
  });

  tearDown(() async => GetIt.instance.reset());

  Widget aStripOf(AddMealType type) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: IntakeVerticalList(
        day: DateTime.now(),
        title: 'A meal',
        listIcon: IntakeTypeEntity.dinner.getIconData(),
        addMealType: type,
        intakeList: const [],
        usesImperialUnits: false,
        onDeleteIntakeCallback: (_, __) {},
        planned: const [katsu],
        onAtePlanned: (item, slot) => answeredWith = slot,
        onPlannedNotEaten: (item, slot) => answeredWith = slot,
      ),
    ),
  );

  /// Draw the strip and put aside the one complaint it is expected to make.
  ///
  /// The ghost card is four points too tall for the 120-point box the list
  /// gives it: the meal's name and "Awaiting calories" end up on top of each
  /// other. That is exactly what Aidan saw on his phone on 22 August —
  /// "layered and confusing" — and he asked for the behaviour to be got right
  /// first and the layout later. So this notices the overflow and carries on
  /// rather than letting it fail a test about something else. When the card is
  /// given room, this returns null and the line can go.
  Future<void> draw(WidgetTester tester, AddMealType type) async {
    await tester.pumpWidget(aStripOf(type));
    tester.takeException();
  }

  Finder theGhost() => find.descendant(
    of: find.byKey(const ValueKey('planned-30')),
    matching: find.byType(InkWell),
  );

  testWidgets('the dinner strip answers dinner', (tester) async {
    await draw(tester, AddMealType.dinnerType);
    await tester.tap(theGhost());
    await tester.pumpAndSettle();
    expect(answeredWith, 'dinner');
  });

  testWidgets('and the lunch strip answers lunch', (tester) async {
    // Today only dinners are planned. If breakfasts or lunches ever are, this
    // is what says the answer follows the card rather than a guess made once.
    await draw(tester, AddMealType.lunchType);
    await tester.tap(theGhost());
    await tester.pumpAndSettle();
    expect(answeredWith, 'lunch');
  });

  testWidgets('and "did not have it" carries the same word', (tester) async {
    await draw(tester, AddMealType.dinnerType);
    await tester.longPress(theGhost());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Didn\'t have it'));
    await tester.pumpAndSettle();
    expect(answeredWith, 'dinner');
  });

  test('the words the strip uses are the words the household ledger takes', () {
    // 'breakfast' | 'lunch' | 'dinner' | 'snack' — the Mac Mini accepts these
    // four and quietly falls back to the clock for anything else, so a rename
    // on this side would go unnoticed rather than error.
    expect(
      [for (final t in AddMealType.values) t.getIntakeType().name],
      ['breakfast', 'lunch', 'dinner', 'snack'],
    );
  });
}
