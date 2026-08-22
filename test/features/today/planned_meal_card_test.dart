/// The ghost entry: tonight's dinner sitting on the day, waiting to be real.
///
/// Behaviour under test (Release B, TM-0009): a planned meal appears on Home as
/// a card that looks like a logged food entry and says "Tap to confirm".
///
/// This file replaces one that asserted the opposite, and the reversal is the
/// point. The earlier row was built to be unmistakably *not* an entry — faded,
/// outlined, captioned "Planned", under a heading of its own — on the reasoning
/// that a planned meal must never be taken for an eaten one. Aidan looked at
/// that on Home on 20 August and said it read as a second system inside the
/// first, and had it removed. Asked again on 22 August where confirming a
/// dinner should live, he described this instead, in his words:
///
///   "a 'ghost' entry on the home screen of the phone app which looks just like
///   a regular food entry, but says 'tap to confirm' - you tap to confirm you
///   ate that thing and it becomes a real entry."
///
/// So the test that carries this item is [it looks like an entry rather than
/// announcing itself as a plan]. An implementation that went back to shouting
/// "Planned" would pass every other test here and would be the thing he asked
/// twice to be rid of.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/features/today/presentation/planned_meal_card.dart';

void main() {
  const traybake = PlannedItem(
    planId: 7,
    title: 'Chicken traybake',
    portions: 1.5,
    kcal: 960,
    mealKcalKnown: true,
  );

  Widget card(
    PlannedItem item, {
    VoidCallback? onAte,
    VoidCallback? onNotEaten,
    bool figuresOff = false,
  }) => MaterialApp(
    home: Scaffold(
      body: FiguresScope(
        figuresOff: figuresOff,
        child: PlannedMealCard(
          item: item,
          firstListElement: true,
          onAte: onAte,
          onNotEaten: onNotEaten,
        ),
      ),
    ),
  );

  /// What a thumb actually lands on. The card sits in a Row that fills the
  /// width of the screen, so the centre of [PlannedMealCard] is empty space
  /// beside it.
  final theCard = find.descendant(
    of: find.byType(PlannedMealCard),
    matching: find.byType(InkWell),
  );

  group('the ghost on the day', () {
    testWidgets('says the meal it is standing in for', (tester) async {
      await tester.pumpWidget(card(traybake));
      expect(find.text('Chicken traybake'), findsOneWidget);
    });

    testWidgets('and says what to do about it', (tester) async {
      await tester.pumpWidget(card(traybake));
      expect(find.text(PlannedMealCard.tapToConfirm), findsOneWidget);
    });

    testWidgets(
      'it looks like an entry rather than announcing itself as a plan',
      (tester) async {
        await tester.pumpWidget(card(traybake));

        // The word the old row led with. Its absence is the design, not an
        // oversight — see this file's opening note.
        expect(find.text('Planned'), findsNothing);

        // And it is the same size and shape as the cards it sits between, so it
        // reads as one of them. 120 square is what IntakeCard uses.
        final ghost = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(PlannedMealCard),
                matching: find.byType(SizedBox),
              )
              .at(1),
        );
        expect(ghost.width, 120);
        expect(ghost.height, 120);
      },
    );

    testWidgets('and it is not one of the real cards', (tester) async {
      // Looking like an entry is not the same as being one. Anything that
      // treats it as a logged intake — the ring, the meal total — must not see
      // it until it has been confirmed.
      await tester.pumpWidget(card(traybake));
      expect(find.byType(IntakeCard), findsNothing);
    });
  });

  group('the figure it carries', () {
    testWidgets('is this person\'s share of the meal', (tester) async {
      await tester.pumpWidget(card(traybake));
      expect(find.textContaining('960'), findsOneWidget);
    });

    testWidgets('says what is missing when the meal has no numbers', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(
          const PlannedItem(
            planId: 7,
            title: 'Chicken traybake',
            portions: 1.5,
          ),
        ),
      );
      expect(find.text('Awaiting calories'), findsOneWidget);
    });

    testWidgets('and which thing is missing when it is the portion', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(
          const PlannedItem(
            planId: 7,
            title: 'Chicken traybake',
            mealKcalKnown: true,
          ),
        ),
      );
      expect(find.text('Awaiting a portion'), findsOneWidget);
    });

    testWidgets('and shows no figure at all to somebody who asked not to see '
        'them', (tester) async {
      await tester.pumpWidget(card(traybake, figuresOff: true));
      expect(find.textContaining('960'), findsNothing);
      // The meal and the offer are still there — switching the numbers off
      // must not switch off the ability to confirm your dinner.
      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.text(PlannedMealCard.tapToConfirm), findsOneWidget);
    });
  });

  group('answering it', () {
    testWidgets('one tap says you ate it', (tester) async {
      var ate = false;
      await tester.pumpWidget(card(traybake, onAte: () => ate = true));
      await tester.tap(theCard);
      await tester.pumpAndSettle();
      expect(ate, isTrue);
    });

    testWidgets('holding it offers the other answer', (tester) async {
      await tester.pumpWidget(card(traybake, onNotEaten: () {}));
      await tester.longPress(theCard);
      await tester.pumpAndSettle();
      expect(find.text(PlannedMealCard.notEatenLabel), findsOneWidget);
    });

    testWidgets('and taking that answer reports it', (tester) async {
      var notEaten = false;
      await tester.pumpWidget(
        card(traybake, onNotEaten: () => notEaten = true),
      );
      await tester.longPress(theCard);
      await tester.pumpAndSettle();
      await tester.tap(find.text(PlannedMealCard.notEatenLabel));
      await tester.pumpAndSettle();
      expect(notEaten, isTrue);
    });

    testWidgets('backing out of the hold answers nothing', (tester) async {
      var notEaten = false;
      await tester.pumpWidget(
        card(traybake, onNotEaten: () => notEaten = true),
      );
      await tester.longPress(theCard);
      await tester.pumpAndSettle();
      // Dismiss the sheet without choosing. Changing your mind about answering
      // is not an answer.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(notEaten, isFalse);
    });

    testWidgets('a card nobody can answer offers nothing', (tester) async {
      // How the same card is drawn where there is no way to record an answer.
      // Buttons that do nothing are worse than no buttons.
      await tester.pumpWidget(card(traybake));
      await tester.longPress(theCard);
      await tester.pumpAndSettle();
      expect(find.text(PlannedMealCard.notEatenLabel), findsNothing);
    });
  });

  group('the wording, on its own', () {
    test('the portion covers the cases the day actually produces', () {
      expect(
        PlannedMealCard.portionText(traybake),
        'Your portion: 1.5 portions',
      );
      expect(
        PlannedMealCard.portionText(
          const PlannedItem(planId: 1, title: 'x', portions: 1),
        ),
        'Your portion: 1 portion',
      );
      expect(
        PlannedMealCard.portionText(
          const PlannedItem(planId: 1, title: 'x', portions: 2.0),
        ),
        'Your portion: 2 portions',
        reason: 'a whole number should not read as 2.0',
      );
      expect(
        PlannedMealCard.portionText(const PlannedItem(planId: 1, title: 'x')),
        'Portion not set',
        reason: 'a portion nobody has set must not be guessed at as one',
      );
    });

    test('the gap says which thing is missing', () {
      expect(PlannedMealCard.gapText(traybake), isNull);
      expect(
        PlannedMealCard.gapText(
          const PlannedItem(planId: 1, title: 'x', portions: 1),
        ),
        'Awaiting calories',
      );
      expect(
        PlannedMealCard.gapText(
          const PlannedItem(planId: 1, title: 'x', mealKcalKnown: true),
        ),
        'Awaiting a portion',
      );
    });
  });
}
