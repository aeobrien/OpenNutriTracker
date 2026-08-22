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
/// **It brings its own dinner.** Each test puts a meal called "a live test meal
/// — ignore" on today's plan, answers that one, and takes it back off, retiring
/// anything it put on the ledger. The first version of this file did not: it
/// answered whatever the household happened to have planned, which meant running
/// it ate a real dinner off Aidan's day and left a row behind that had to be
/// tidied by hand. It also meant the third test only passed when the house
/// happened to have two meals planned, so the suite's result depended on what
/// was for tea. A test that changes somebody's real day as a side effect is not
/// a test you can run when you want to.
///
/// It still genuinely changes the real machine while it runs — that is the
/// point — and if it is killed part-way it can leave its own meal behind. The
/// name is there so anybody who sees it knows what it is.
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
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/features/today/domain/planned_today.dart';

const _base = String.fromEnvironment('MANTEL_BASE_URL');
const _aidan = 1;

/// Said on the plan itself, so a person who sees it on the kitchen panel knows
/// what it is without having to ask anybody.
const _title = 'a live test meal — ignore';
const _portions = 1.5;

String get _today {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  final r = await http.post(Uri.parse('$_base$path'),
      headers: {'content-type': 'application/json'}, body: jsonEncode(body));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

/// What the house itself says, asked directly rather than through the phone's
/// code — a client that agrees with itself proves nothing.
Future<Map<String, dynamic>> theHouseholdsDay() async {
  final r = await http.get(Uri.parse('$_base/household/day/$_aidan/$_today'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Set<int> _entryIds(Map<String, dynamic> day) => {
      for (final e in (day['entries'] as List).cast<Map<String, dynamic>>())
        e['id'] as int,
    };

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

  /// The plan row this test made, and is the only one allowed to answer.
  late int mine;

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

    mine = (await _post('/household/plan/add',
        {'date': _today, 'title': _title, 'actor': 'live-test'}))['plan_id'] as int;
    await _post('/household/plan/portion',
        {'plan_id': mine, 'person_id': _aidan, 'portions': _portions});
  });

  tearDown(() async {
    // Off the plan whatever happened, including when the test failed part-way.
    await _post('/household/plan/$mine/remove', const {});
    await db.close();
  });

  /// Read the day the way Home does, and hand it to the ghost list.
  Future<void> readTheDay() async => planned.takeFrom(await days.today(_today));

  /// This test's own card, picked by id. Never `.first` — the household's real
  /// dinners are sitting in the same list and are not this test's to answer.
  PlannedItem myCard() => planned.items.firstWhere((p) => p.planId == mine,
      orElse: () => throw StateError(
          'the phone cannot see the meal this test just planned'));

  test('a meal the house has planned appears on the phone, as planned',
      () async {
    final itsRow = ((await theHouseholdsDay())['planned'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['plan_id'] == mine);

    await readTheDay();

    expect(myCard().title, itsRow['title'],
        reason: 'the phone and the house disagree about what is planned');
    expect(myCard().portions, itsRow['portions'],
        reason: 'the phone is showing the wrong share of the meal');
  });

  test('confirming it puts it on this person\'s day and off the plan', () async {
    final before = await theHouseholdsDay();
    final was = _entryIds(before);

    await readTheDay();
    final it = myCard();
    expect(await planned.decide(it, ate: true, slot: 'dinner'), isTrue);

    // The card goes before the house has heard — nothing has been sent yet.
    expect(planned.items.any((p) => p.planId == it.planId), isFalse,
        reason: 'a meal they have answered must not keep asking');

    await outbox.drain();

    final after = await theHouseholdsDay();
    final fresh = _entryIds(after).difference(was);
    expect(fresh, hasLength(1),
        reason: 'the answer never reached the household ledger');

    final landed = (after['entries'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((e) => e['id'] == fresh.single);
    expect(landed['label'], _title);
    expect(landed['qty'], _portions,
        reason: 'it landed with the wrong share of the meal');
    expect(landed['owner_id'], _aidan,
        reason: 'it landed on the wrong person\'s day');
    expect(landed['slot'], 'dinner',
        reason: 'the meal of the day was left to the clock, so a dinner '
            'confirmed at lunchtime lands under Lunch');
    expect(
        (after['planned'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p['plan_id'] == it.planId),
        isFalse,
        reason: 'the house still calls it planned after it was confirmed');

    // Off the day again. The row is real until this runs, so it goes here
    // rather than in tearDown, where a later failure could skip it.
    await _post('/household/entry/${fresh.single}/retire', const {});
    expect(_entryIds(await theHouseholdsDay()).contains(fresh.single), isFalse,
        reason: 'the test left its own dinner on his day');
  });

  test('refusing it takes it off the plan and puts nothing on the day',
      () async {
    final before = await theHouseholdsDay();
    final was = _entryIds(before);

    await readTheDay();
    final it = myCard();
    expect(await planned.decide(it, ate: false, slot: 'dinner'), isTrue);
    expect(planned.items.any((p) => p.planId == it.planId), isFalse);

    await outbox.drain();

    final after = await theHouseholdsDay();
    expect(
        (after['planned'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p['plan_id'] == it.planId),
        isFalse,
        reason: 'the house still calls it planned after they said no');
    expect(_entryIds(after).difference(was), isEmpty,
        reason: 'saying you did not have it put food on the day');
  });
}
