/// "Just me" or "both of us", on the sheet that already asks how much.
///
/// Behaviour under test (Release B, TM-0011): the control that says who a food
/// was for. What it must get right:
///
///  * it is not there at all until the house has said there is somebody else,
///    so a phone nobody has claimed and a Mac Mini that has never answered both
///    leave the sheet exactly as it was;
///  * it starts at "just me" every single time — a remembered answer is how one
///    shared dinner turns every later breakfast into two;
///  * choosing "both of us" asks for their amount by name, starting them at the
///    same amount and letting it be changed, because a shared packet is usually
///    but not always split evenly;
///  * and going back to "just me" withdraws them again, rather than leaving a
///    number behind that would quietly still be logged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/who_was_it_for.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late TextEditingController myAmount;

  HouseholdPerson? reportedPerson;
  double? reportedAmount;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    myAmount = TextEditingController(text: '40');
    reportedPerson = null;
    reportedAmount = null;
  });

  tearDown(() async {
    myAmount.dispose();
    await db.close();
  });

  Widget screen() => MaterialApp(
        home: Scaffold(
          body: WhoWasItFor(
            myAmount: myAmount,
            household: household,
            onChanged: (other, amount) {
              reportedPerson = other;
              reportedAmount = amount;
            },
          ),
        ),
      );

  group('when the house has two people in it', () {
    setUp(() async => household.setOwner(mini.aidan));

    testWidgets('both answers are offered', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WhoWasItFor.justMeLabel), findsOneWidget);
      expect(find.text(WhoWasItFor.bothOfUsLabel), findsOneWidget);
    });

    testWidgets('it starts as just mine, and asks for nothing else',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text("Emily's amount"), findsNothing);
      expect(reportedPerson, isNull);
      expect(reportedAmount, isNull);
    });

    testWidgets('choosing both of us asks for her amount, by name',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(WhoWasItFor.bothOfUsLabel));
      await tester.pumpAndSettle();

      expect(find.text("Emily's amount"), findsOneWidget);
    });

    testWidgets('she starts on the same amount he did', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(WhoWasItFor.bothOfUsLabel));
      await tester.pumpAndSettle();

      expect(reportedPerson?.name, 'Emily');
      expect(reportedAmount, 40);
    });

    testWidgets('and her amount can be changed without touching his',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(WhoWasItFor.bothOfUsLabel));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, "Emily's amount"), '15');
      await tester.pumpAndSettle();

      expect(reportedAmount, 15);
      expect(myAmount.text, '40', reason: 'his own amount is his own');
    });

    testWidgets('going back to just me withdraws her again', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(WhoWasItFor.bothOfUsLabel));
      await tester.pumpAndSettle();
      expect(reportedAmount, 40);

      await tester.tap(find.text(WhoWasItFor.justMeLabel));
      await tester.pumpAndSettle();

      expect(reportedPerson, isNull);
      expect(reportedAmount, isNull,
          reason: 'a number left behind here is a meal logged against '
              'somebody who did not eat it');
      expect(find.text("Emily's amount"), findsNothing);
    });
  });

  group('when the question does not arise', () {
    testWidgets('nobody has said whose phone this is — nothing is shown',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WhoWasItFor.bothOfUsLabel), findsNothing);
    });

    testWidgets('the Mac Mini has never answered — nothing is shown',
        (tester) async {
      await household.setOwner(mini.aidan);
      mini.reachable = false;
      // A fresh phone: the owner is known, but who else lives here has never
      // been fetched, so there is nothing cached to fall back on either.
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WhoWasItFor.bothOfUsLabel), findsNothing);
    });

    testWidgets('a sleeping Mac Mini still knows who she is, once it has said',
        (tester) async {
      await household.setOwner(mini.aidan);
      await household.people(); // heard once, while it was awake
      mini.reachable = false;

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WhoWasItFor.bothOfUsLabel), findsOneWidget);
    });
  });
}
