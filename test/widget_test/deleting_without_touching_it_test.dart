/// Removing a row without being able to hold it.
///
/// Behaviour under test — Release 7, TM-0024 / BC-0025. The card's non-touch
/// path is VoiceOver's actions rotor offering Delete on the row.
///
/// Until now the only ways into removing a row were a tap and a long press.
/// A long press is not a gesture somebody navigating by rotor can make, and the
/// tap opens a dialog whose Delete button is several stops further in — so for
/// that person a row could be read and not removed. The rotor action is the
/// same behaviour as holding the card, confirmation dialog and all: one
/// behaviour, two ways to reach it.
///
/// The checks drive the semantics tree rather than the pixels, because that is
/// what a screen reader actually meets. `tester.tap` on a card would prove the
/// touch path, which already worked.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

IntakeEntity _row() => IntakeEntity(
      id: 'intake-abc',
      unit: 'serving',
      amount: 1,
      type: IntakeTypeEntity.snack,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 22, 19, 30),
      entryType: 'quickAdd',
      quickAddLabel: 'Oat biscuits',
      snapshotKcal: 337,
      thisPhoneDidIt: true,
    );

Widget _aCard({
  void Function()? onHeld,
  void Function()? onTapped,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: IntakeCard(
          key: const Key('row'),
          intake: _row(),
          firstListElement: true,
          usesImperialUnits: false,
          onItemLongPressed: onHeld == null ? null : (_, __) => onHeld(),
          onItemTapped: onTapped == null ? null : (_, __, ___) => onTapped(),
        ),
      ),
    );

/// The row as a screen reader meets it.
///
/// Found by the Card rather than by the IntakeCard's own key, deliberately:
/// IntakeCard's outermost widget is a plain Row with no semantics of its own,
/// so looking it up by key walks past the row's node and lands on the screen.
/// The Card is what declares the container, and the container is the row.
SemanticsNode _theRow(WidgetTester tester) =>
    tester.getSemantics(find.byType(Card));

/// The id of the rotor action with this label. Null when the row does not
/// offer it, which is a real answer here rather than a failure.
int? _action(WidgetTester tester, String label) {
  final data = _theRow(tester).getSemanticsData();
  for (final id in data.customSemanticsActionIds ?? const <int>[]) {
    if (CustomSemanticsAction.getAction(id)?.label == label) return id;
  }
  return null;
}

/// Choose it, the way the rotor does — through the semantics tree, not by
/// calling the widget's callback. Anything that goes around this proves the
/// callback works and nothing about whether a screen reader can reach it.
void _choose(WidgetTester tester, String label) {
  tester.binding.pipelineOwner.semanticsOwner!.performAction(
      _theRow(tester).id, SemanticsAction.customAction, _action(tester, label));
}

void main() {
  testWidgets('the row offers Delete without being touched', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_aCard(onHeld: () {}, onTapped: () {}));
    await tester.pumpAndSettle();

    expect(_action(tester, IntakeCard.deleteAction), isNotNull,
        reason: 'the only way to remove a row is a gesture');
    handle.dispose();
  });

  testWidgets('and Edit, which is what tapping it does', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_aCard(onHeld: () {}, onTapped: () {}));
    await tester.pumpAndSettle();

    expect(_action(tester, IntakeCard.editAction), isNotNull);
    handle.dispose();
  });

  testWidgets('choosing Delete does what holding the card does',
      (tester) async {
    final handle = tester.ensureSemantics();
    var held = 0;
    await tester.pumpWidget(_aCard(onHeld: () => held += 1, onTapped: () {}));
    await tester.pumpAndSettle();

    // Not its own removal path. It goes down the one that already asks for
    // confirmation and already offers the undo.
    _choose(tester, IntakeCard.deleteAction);
    await tester.pumpAndSettle();

    expect(held, 1);
    handle.dispose();
  });

  testWidgets('choosing Edit does what tapping it does', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = 0;
    await tester.pumpWidget(_aCard(onHeld: () {}, onTapped: () => tapped += 1));
    await tester.pumpAndSettle();

    _choose(tester, IntakeCard.editAction);
    await tester.pumpAndSettle();

    expect(tapped, 1);
    handle.dispose();
  });

  testWidgets('a card nothing can be done to offers nothing', (tester) async {
    // The meal-detail screen builds these cards with no callbacks. A rotor
    // action that does nothing is worse than no action: it reads as a way out
    // that is not there.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_aCard());
    await tester.pumpAndSettle();

    expect(_action(tester, IntakeCard.deleteAction), isNull);
    expect(_action(tester, IntakeCard.editAction), isNull);
    handle.dispose();
  });
}
