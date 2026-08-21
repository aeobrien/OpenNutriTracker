/// Undo is scoped to this phone's own actions.
///
/// Aidan's ruling, 21 August: "If two people are editing a Google document and
/// one of them adds a word, the other person can't hit undo and remove that
/// word. They can still delete the word the same way they would delete any
/// word in the document, but undo never touches it. The same should be true
/// for us."
///
/// So a row somebody else put on this day is not something Undo reaches for.
/// It is still removable the ordinary way — the same gesture that removes any
/// other row, which is the one that put the offer on screen in the first place.
///
/// "Somebody else" is the whole difficulty. A sentence spoken into this phone
/// goes to the household and comes back down the pull looking exactly like a
/// sentence spoken at the kitchen panel, so "did it come from the house?" is
/// not the same question as "did this phone do it?" — and on 21 August Aidan
/// found the difference from the outside: "Step 1 was on the phone — logging an
/// item here would come from the phone, not from the House." Hence
/// [IntakeEntity.thisPhoneDidIt], settled once on the way in.
///
/// What the deletion itself does at the house is covered by
/// correcting_a_row_the_house_sent_test.dart; this file is only about which
/// rows Undo is willing to speak for.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

IntakeEntity _row({String? externalId, bool thisPhoneDidIt = false}) =>
    IntakeEntity(
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
    thisPhoneDidIt: thisPhoneDidIt,
    snapshotKcal: 350);

void main() {
  test('a row somebody spoke at the kitchen panel is not this phone\'s to undo',
      () {
    // It arrived from the house and this phone has no record of doing it.
    expect(_row(externalId: 'house-9').isALocalAction, isFalse);
  });

  test('a sentence spoken into this phone is still this phone\'s to undo', () {
    // The same shape of row — it went to the house and came back — but the
    // phone's own record says the phone is what sent it.
    expect(_row(externalId: 'house-9', thisPhoneDidIt: true).isALocalAction,
        isTrue);
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
