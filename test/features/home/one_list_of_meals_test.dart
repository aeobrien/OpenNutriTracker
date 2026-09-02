/// The meals of the day come from one list, and Dinner keeps what is its own.
///
/// The four strips on the Today screen — Breakfast, Lunch, Dinner, Snack —
/// used to be four copies of the same block of code, written out one after
/// another. They are now drawn from a single list that says what the meals of
/// the day are and what order they come in.
///
/// A person sees no difference, and that is the point: the first test here is
/// that nothing moved. It cannot be shown failing against the old code,
/// because the old code drew the same four strips — a change meant to change
/// nothing has no before-and-after, and pretending otherwise would be the kind
/// of claim this project has been careful not to make.
///
/// The second test is the one with teeth, and it is why this file exists at
/// all. The four blocks were no longer identical: the Dinner one had grown six
/// extra things since June — the meals the household has planned, drawn as
/// ghost cards, and the three ways of answering them. The obvious way to write
/// the loop drops all six, and every existing test would still have passed,
/// because the test that covers ghost cards drives the strip on its own rather
/// than through the screen. So: a planned meal, and the screen asked where it
/// ended up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

import 'a_home_that_can_be_driven.dart';

void main() {
  tearDown(() async => GetIt.instance.reset());

  /// The strip titles, read down the screen in the order they are drawn.
  List<String> theMealsDownTheScreen(WidgetTester tester) => tester
      .widgetList<IntakeVerticalList>(find.byType(IntakeVerticalList))
      .map((strip) => strip.title)
      .toList();

  testWidgets('the four meals are still there, in the same order',
      (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome();
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();

    expect(theMealsDownTheScreen(tester),
        ['Breakfast', 'Lunch', 'Dinner', 'Snack']);
  });

  testWidgets('a planned meal is still handed to Dinner and to nothing else',
      (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome(plannedForToday: const [
      PlannedItem(planId: 7, title: 'Chicken katsu'),
    ]);
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();

    // A separate fault, found by writing this test and deliberately left in
    // rather than dodged: a ghost card is 96 pixels tall, and a meal whose
    // name wraps onto a second line pushes "tap to confirm" four pixels past
    // the bottom of it. "Chicken katsu" is one such name — it is the meal from
    // the 22 August bug, so it is the realistic case rather than a contrived
    // one. Taking the complaint here keeps this test about where the plan is
    // handed; the clipping is reported on its own and not fixed inside a
    // change that was only meant to move some code around.
    final theCardIsFourPixelsTooSmall = tester.takeException();
    expect(theCardIsFourPixelsTooSmall.toString(), contains('overflowed'));

    final strips =
        tester.widgetList<IntakeVerticalList>(find.byType(IntakeVerticalList));
    final dinner = strips.firstWhere((s) => s.title == 'Dinner');
    final others = strips.where((s) => s.title != 'Dinner');

    expect(dinner.planned.map((p) => p.title), ['Chicken katsu']);
    expect(dinner.onAtePlanned, isNotNull,
        reason: 'a ghost card nobody can answer is worse than no ghost card');
    expect(dinner.onPlannedNotEaten, isNotNull);
    expect(dinner.onAtePlannedForBoth, isNotNull);

    for (final strip in others) {
      expect(strip.planned, isEmpty,
          reason: '${strip.title} has no plan of its own to show');
    }

    // And it reached the screen: the meal is on it, not merely handed to it.
    expect(find.text('Chicken katsu'), findsOneWidget);
  });
}
