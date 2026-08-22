/// The ghost entry's path, run against the real Mac Mini.
///
/// Every other test of this feature answers its own questions: a fake server in
/// memory hands back a planned meal and the same test checks what was done with
/// it. That proves the parts. This one uses the phone's own classes — the same
/// [DayRepository], [Outbox] and [HouseholdLogger] the running app uses — against
/// the actual household server, and then asks that server, over its own HTTP,
/// what happened. Nothing here is a stand-in.
///
///   flutter test test/live/the_ghost_path_against_the_real_house_test.dart \
///     --dart-define=MANTEL_BASE_URL=http://<host>:8770
///
/// It needs a meal planned for today with a portion set for person 1, and it
/// **changes that day**: one planned meal is confirmed and another refused. That
/// is the point — something really happens, on the real machine.
///
/// What it deliberately does not cover, and cannot: the screen. A widget test
/// runs in made-up time and with the network stubbed out, so no test in this
/// repo can draw the real card from the real house. The tool for that is
/// `integration_test/`, which needs a real device — this app has no simulator
/// build, because its barcode scanner ships no arm64 simulator slice. So the
/// last link, a thumb on a real card, is checked by a person.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/planned_today.dart';

const _base = String.fromEnvironment('MANTEL_BASE_URL');
const _aidan = 1;

String get _today {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// What the house itself says, asked directly rather than through the phone's
/// code — a client that agrees with itself proves nothing.
Future<Map<String, dynamic>> theHouseholdsDay() async {
  final r = await http.get(Uri.parse('$_base/household/day/$_aidan/$_today'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

void main() {
  if (_base.isEmpty) {
    test('the ghost path against the real house', () {},
        skip: 'run with --dart-define=MANTEL_BASE_URL=http://<host>:8770');
    return;
  }

  late AppDatabase db;
  late Outbox outbox;
  late DayRepository days;
  late PlannedToday planned;

  setUp(() async {
    // The test framework stubs the network out. This file exists for the
    // network.
    HttpOverrides.global = null;

    db = AppDatabase.createInMemory();
    final api = HouseholdApi(baseUrl: _base);
    final household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    days = DayRepository(api, household);
    planned = PlannedToday(HouseholdLogger(household, outbox));
    await household.setOwner(_aidan);
  });

  tearDown(() async => db.close());

  /// Read the day the way Home does, and hand it to the ghost list.
  Future<void> readTheDay() async => planned.takeFrom(await days.today(_today));

  test('the house has something planned for today, and the phone can see it',
      () async {
    final fromTheHouse = await theHouseholdsDay();
    expect(fromTheHouse['planned'], isNotEmpty,
        reason: 'nothing is planned for today, so there is nothing to check');

    await readTheDay();

    expect(planned.items.map((p) => p.title).toList(),
        [for (final p in fromTheHouse['planned']) p['title']],
        reason: 'the phone and the house disagree about what is planned');
    expect(planned.items.first.portions,
        (fromTheHouse['planned'] as List).first['portions'],
        reason: 'the phone is showing the wrong share of the meal');
  });

  test('confirming one puts it on this person\'s day and off the plan',
      () async {
    final before = await theHouseholdsDay();
    final wasEaten = (before['entries'] as List).length;

    await readTheDay();
    final it = planned.items.first;
    expect(await planned.decide(it, ate: true), isTrue);

    // The card goes before the house has heard — nothing has been sent yet.
    expect(planned.items.any((p) => p.planId == it.planId), isFalse,
        reason: 'a meal they have answered must not keep asking');

    await outbox.drain();

    final after = await theHouseholdsDay();
    final entries = (after['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.length, wasEaten + 1,
        reason: 'the answer never reached the household ledger');
    final landed = entries.firstWhere((e) => e['label'] == it.title);
    expect(landed['qty'], it.portions,
        reason: 'it landed with the wrong share of the meal');
    expect(landed['owner_id'], _aidan,
        reason: 'it landed on the wrong person\'s day');
    expect(
        (after['planned'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p['plan_id'] == it.planId),
        isFalse,
        reason: 'the house still calls it planned after it was confirmed');
  });

  test('refusing one takes it off the plan and puts nothing on the day',
      () async {
    final before = await theHouseholdsDay();
    expect(before['planned'], isNotEmpty,
        reason: 'nothing left planned for today to refuse');
    final wasEaten = (before['entries'] as List).length;

    await readTheDay();
    final it = planned.items.first;
    expect(await planned.decide(it, ate: false), isTrue);
    expect(planned.items.any((p) => p.planId == it.planId), isFalse);

    await outbox.drain();

    final after = await theHouseholdsDay();
    expect(
        (after['planned'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p['plan_id'] == it.planId),
        isFalse,
        reason: 'the house still calls it planned after they said no');
    expect((after['entries'] as List).length, wasEaten,
        reason: 'saying you did not have it put food on the day');
  });
}
