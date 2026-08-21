/// Holding a row to delete it: the screen must not redraw until the row is
/// actually gone.
///
/// The fault, from 21 August: the removal was started and not waited for, and
/// the redraw that followed read the day back out of the database before the
/// removal had reached it. The figure the person had just taken off the ring
/// went straight back on. One `await` fixes it — on the swipe path I watched
/// that happen and watched the fix stop it, but on the two hold-to-delete
/// paths I could not, and I said so in the build 42 note:
///
///   "I put the fix in, took it back out, and ran the same checks against the
///   broken build — and they passed anyway. The timing fell the right way on my
///   machine. […] Proving the other two needs a test that controls the timing
///   rather than a check that hopes for it, and that does not exist yet."
///
/// This is that test. It does not hope for the timing, it holds the removal
/// open: the screen is caught in the exact moment the race is made of, and
/// asked whether it has redrawn. It has not, because it is waiting. Take the
/// `await` out and it has, which is the fault, in the same second it happens.
///
/// Both hold-to-delete paths, food and exercise, because both carry the same
/// `await` and either could lose it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_card.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

import 'a_home_that_can_be_driven.dart';

UserActivityEntity someExercise() => UserActivityEntity(
      'ex-1',
      30,
      250,
      DateTime.now(),
      const PhysicalActivityEntity('code', 'Running', 'Running', 3.5, [],
          PhysicalActivityTypeEntity.running),
    );

/// The bar that says the row has gone hides itself on a timer of its own a few
/// seconds later. Let it, or the test ends with that timer still pending.
Future<void> letTheBarHideItself(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => GetIt.instance.reset());

  /// Hold the row, and say yes to the box that asks whether to delete it.
  Future<void> holdAndConfirm(WidgetTester tester, Finder row) async {
    await tester.longPress(row);
    await tester.pumpAndSettle();
    expect(find.text('Delete Item?'), findsOneWidget,
        reason: 'holding the row should ask before removing it');
    await tester.tap(find.text('OK'));
    // Let the dialog close and the handler get as far as it can — but no
    // further, because the removal it is waiting on has not been let finish.
    await tester.pumpAndSettle();
  }

  testWidgets('a food row: the day is not re-read until the row is gone',
      (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome(food: [aRowOf(350)]);
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();
    final readsBefore = home.day.reads;
    expect(readsBefore, greaterThan(0), reason: 'the day should have loaded');

    await holdAndConfirm(tester, find.text('Toast'));

    // The moment the race is made of.
    expect(home.foodRemoval.isWaiting, isTrue,
        reason: 'the removal should be under way');
    expect(home.day.reads, readsBefore,
        reason: 'the day was read back before the row had gone — this is the '
            'fault: the figure just taken off the ring goes back on');

    home.foodRemoval.finish();
    await tester.pumpAndSettle();

    expect(home.day.reads, greaterThan(readsBefore),
        reason: 'once the row is gone the day should be read again');

    await letTheBarHideItself(tester);
  });

  testWidgets('an exercise row: the same, on the other path', (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome(exercise: [someExercise()]);
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();
    final readsBefore = home.day.reads;
    expect(readsBefore, greaterThan(0));

    // The card itself, not the name underneath it — the name sits outside the
    // part that takes the press.
    await holdAndConfirm(
        tester,
        find
            .descendant(
                of: find.byType(ActivityCard), matching: find.byType(InkWell))
            .first);

    expect(home.exerciseRemoval.isWaiting, isTrue);
    expect(home.day.reads, readsBefore,
        reason: 'the day was read back before the exercise had gone — the '
            'allowance it earned goes back on the ring');

    home.exerciseRemoval.finish();
    await tester.pumpAndSettle();

    expect(home.day.reads, greaterThan(readsBefore));
  });
}
