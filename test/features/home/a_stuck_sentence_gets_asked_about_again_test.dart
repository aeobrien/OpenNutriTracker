/// A sentence that never got worked out is asked about again.
///
/// Aidan spoke his breakfast into the phone and the row sat on his day reading
/// "Something you said" with no calories against it. Not for a moment — for
/// good. He ended up with three of them, and in the walkthrough he described
/// the same thing from the other side: *"Just says 'working out what that was'
/// for ages, then stops. No food appears, eaten counter does not increase."*
///
/// The reason turned out to be nothing to do with understanding sentences. A
/// sentence is asked about **once**, in the moment it is said. If that single
/// attempt does not land — the Mac Mini asleep, the address wrong, the phone
/// put down mid-answer — the row is simply left there. The retry that was
/// supposed to catch it, [SaidRepository.catchUp], was written, documented,
/// and never called from anywhere in the app: its own comment says it runs
/// "when the day is read", and the screen that read the day was the second tab
/// — which was removed at Aidan's own instruction, taking the only moment the
/// retry could have happened with it.
///
/// Nobody noticed for the reason these are never noticed: a retry that never
/// runs and a retry that has not run yet look exactly the same from the day.
///
/// So the check is on the wiring, not the retry. It opens Home and asks whether
/// the phone had another go.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

import 'a_home_that_can_be_driven.dart';

void main() {
  tearDown(() async => GetIt.instance.reset());

  const stuck = LoggedItem(
    label: 'Something you said',
    ownerId: 1,
    authorId: 1,
    clientId: 'row-nobody-finished',
    state: 'provisional',
  );

  const finished = LoggedItem(
    label: 'wholemeal toast',
    ownerId: 1,
    authorId: 1,
    clientId: 'row-that-settled',
    kcal: 175,
  );

  Future<ADrivableHome> openHome(
    WidgetTester tester, {
    List<LoggedItem> onTheHouseholdsDay = const [],
    bool houseUnreachable = false,
  }) async {
    final home = ADrivableHome(
      onTheHouseholdsDay: onTheHouseholdsDay,
      houseUnreachable: houseUnreachable,
    );
    home.register();
    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();
    return home;
  }

  testWidgets('opening the app has another go at a row left unfinished',
      (tester) async {
    final home = await openHome(tester, onTheHouseholdsDay: [stuck, finished]);

    expect(home.said.askedToCatchUp, isNotEmpty,
        reason: 'nothing ever asks again, so the row sits there for good');
    expect(
        home.said.askedToCatchUp.first.map((r) => r.clientId),
        contains('row-nobody-finished'),
        reason: 'the unfinished row was not among the ones handed over');
  });

  testWidgets('it reads the household\'s day to find out what is unfinished',
      (tester) async {
    // The rows that are still being worked out live at the house, not in this
    // phone's diary — the diary only ever receives them once they have
    // settled, which is the thing that has not happened.
    final home = await openHome(tester, onTheHouseholdsDay: [stuck]);
    expect(home.dayAtTheHouse.asked, greaterThan(0));
  });

  testWidgets('a question left unanswered is asked again when the app opens',
      (tester) async {
    // Since 21 August a sentence that never named a meal is asked about rather
    // than filed by the clock, and nothing goes on the day until somebody says
    // which meal. That makes an unanswered question food that never arrives —
    // so if the app is closed on one, it has to come back.
    final home = ADrivableHome(onTheHouseholdsDay: const [stuck]);
    home.said.waiting = const AQuestionStillWaiting(
      about: 'row-nobody-finished',
      words: 'two eggs and a slice of toast',
      question: 'Which meal was that — breakfast, lunch, dinner or a snack?',
    );
    home.register();
    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Which meal was that — breakfast, lunch, dinner or a snack?'),
        findsOneWidget,
        reason: 'the question is on the Mac Mini and nowhere the person can '
            'see it, so the food never lands');
  });

  testWidgets('a house that cannot be reached is not an error on the day',
      (tester) async {
    // The ordinary case. The rows wait for next time, which is what they were
    // already doing, and opening the app must not put a fault in front of
    // somebody who only wanted to look at their breakfast.
    final home = await openHome(tester, houseUnreachable: true);

    expect(home.dayAtTheHouse.asked, greaterThan(0));
    expect(home.said.askedToCatchUp, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Something went wrong'), findsNothing);
  });
}
