/// Undo is scoped to this phone's own actions.
///
/// Aidan's ruling, 21 August: "If two people are editing a Google document and
/// one of them adds a word, the other person can't hit undo and remove that
/// word. They can still delete the word the same way they would delete any
/// word in the document, but undo never touches it. The same should be true
/// for us."
///
/// So a row the household put on this day is not something Undo reaches for.
/// It is still removable the ordinary way — the same gesture that removes any
/// other row, which is the one that put the offer on screen in the first place.
///
/// What the deletion itself does at the house is covered by
/// correcting_a_row_the_house_sent_test.dart; this file is only about which
/// rows Undo is willing to speak for.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

IntakeEntity _row({String? externalId}) => IntakeEntity(
    id: 'local-1',
    unit: 'serving',
    amount: 1,
    type: IntakeTypeEntity.breakfast,
    meal: MealEntity.empty(),
    dateTime: DateTime(2026, 8, 21, 8, 0),
    entryType: 'quickAdd',
    quickAddLabel: 'Porridge',
    externalId: externalId,
    said: 'I had a big bowl of porridge with honey',
    snapshotKcal: 350);

void main() {
  test('a row the house sent is not this phone\'s to undo', () {
    expect(_row(externalId: 'house-9').isALocalAction, isFalse);
  });

  test('a row this phone logged still is', () {
    expect(_row().isALocalAction, isTrue);
  });

  test('the name it is known by at the house does not decide it', () {
    // householdName falls back to the local id, so it reads the same for both
    // kinds of row. Whether undo may speak for a row is a different question
    // from what the house calls it, and must not be answered from that.
    final ours = _row();
    final theirs = _row(externalId: 'house-9');
    expect(ours.householdName, 'local-1');
    expect(theirs.householdName, 'house-9');
    expect(ours.isALocalAction, isNot(theirs.isALocalAction));
  });
}
