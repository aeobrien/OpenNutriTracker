/// A fresh install always gets somewhere, even when nothing answers it.
///
/// Written 20 August 2026, after the test harness opened the app on a clean
/// simulator for the first time and watched it sit on "Whose phone is this?"
/// with a spinner turning, for thirty-five seconds, with no names, no message
/// and no way onward. Nobody had ever seen that screen on a phone with no
/// server address stored, because the address survives deleting the app on a
/// real handset and so was always already there.
///
/// Two faults, and both had to be fixed for the screen to come back:
///
///  * with no address stored, the call did not fail as "can't reach it" — it
///    failed as a programming error about a URL with no scheme, which is not
///    the kind of failure any screen was watching for; and
///  * the screen only caught one kind of failure, so anything else at all left
///    it holding a spinner it would never put down.
///
/// The rule those two make together: this screen ends every attempt either
/// showing the people or showing why it can't, and never on a spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/whose_phone_page.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.createInMemory());
  tearDown(() => db.close());

  HouseholdRepository withAddress(String address, http.Client client) =>
      HouseholdRepository(
          ConfigDao(db), HouseholdApi(baseUrl: address, client: client));

  /// A client that would answer perfectly well if it were ever reached. Using
  /// one proves the failure comes from the missing address and not from the
  /// network, which is the whole point.
  http.Client willing() => MockClient((_) async => http.Response(
      '{"ok": true, "people": [{"id": 1, "name": "Aidan"}]}', 200,
      headers: {'content-type': 'application/json'}));

  group('no server address has been set', () {
    test('asking the household says it cannot be reached, in those words',
        () async {
      final api = HouseholdApi(baseUrl: '', client: willing());
      await expectLater(
        api.people(),
        throwsA(isA<HouseholdUnreachable>()),
        reason: 'an address nobody has filled in is a kitchen computer that '
            'cannot be reached, not a fault in the program',
      );
    });

    test('and an address with no http:// on the front is the same thing',
        () async {
      final api = HouseholdApi(baseUrl: '100.71.40.51:8770', client: willing());
      await expectLater(api.people(), throwsA(isA<HouseholdUnreachable>()));
    });

    testWidgets('so the first screen says so and offers to try again',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhosePhonePage(repository: withAddress('', willing())),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'a spinner that will never stop is the worst of the three '
              'things this screen could be showing');
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('the server answers with a refusal', () {
    http.Client refusing() => MockClient((_) async => http.Response(
        '{"ok": false, "error": "no household here"}', 500,
        headers: {'content-type': 'application/json'}));

    testWidgets('the screen still comes back, rather than holding a spinner',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhosePhonePage(
            repository: withAddress('http://mini', refusing())),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
