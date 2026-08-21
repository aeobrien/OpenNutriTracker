/// A sentence left unfinished, then finished — against a Mantel that is
/// actually listening.
///
/// The wiring check under `test/` proves that opening the app asks. It cannot
/// prove that asking *works*, because the thing on the other end of the ask is
/// a stand-in. This is the join between the two halves, and the join is exactly
/// where the fault lived: both ends had tests, and nothing in between was ever
/// run, so a retry that had no caller at all looked fine from either side.
///
/// So this drives the real thing. It puts a row on a real person's day in the
/// state a spoken sentence starts in — provisional, in the person's own words,
/// with no food worked out — reads the day back to confirm the server agrees it
/// is unfinished, then runs the catch-up that Home now runs on opening, and
/// reads the day a third time to see whether the server settled it.
///
/// **This one spends money.** Working out a sentence is a model call at the
/// house. It is a small, cheap, non-reasoning model and one call, which is the
/// whole point of doing it once here rather than in a suite that runs on every
/// change.
///
/// **Not part of `flutter test`.** Outside `test/` on purpose, like its
/// neighbour: it fails when nothing is listening, and a suite that needs a
/// server to be green is a suite people learn to ignore.
///
///     MANTEL=http://100.71.40.51:8791 flutter test test_live/a_stuck_row_gets_settled_test.dart
///
/// Point it at a THROWAWAY Mantel on a copy of the database. It writes a real
/// row to a real day.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/said/data/clip_store.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final base = Platform.environment['MANTEL'] ?? 'http://127.0.0.1:8790';
  final ownerId = int.parse(Platform.environment['MANTEL_PERSON'] ?? '1');

  setUpAll(() async {
    HttpOverrides.global = null;
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    // ClipStore asks the platform where the app's own storage is. There is no
    // platform here, and this test keeps no recordings — it says the sentence
    // in words — so a scratch directory is the honest answer.
    final scratch = Directory.systemTemp.createTempSync('said-live');
    addTearDown(() => scratch.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => scratch.path);
    final health = await http
        .get(Uri.parse('$base/health'))
        .timeout(const Duration(seconds: 20));
    expect(health.statusCode, 200,
        reason: 'no Mantel answering at $base — start one first');
  });

  late AppDatabase db;
  late http.Client client;
  late HouseholdApi api;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late SaidRepository said;
  late DayRepository days;

  setUp(() async {
    client = http.Client();
    db = AppDatabase.createInMemory();
    api = HouseholdApi(baseUrl: base, client: client);
    household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(ownerId);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(household, outbox);
    said = SaidRepository(api, logger, outbox, ClipStore());
    days = DayRepository(api, household);
  });

  tearDown(() async {
    client.close();
    await db.close();
  });

  final now = DateTime.now();
  final day = '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  Future<LoggedItem?> rowNamed(String clientId) async {
    final view = await days.today(day);
    for (final row in view.logged) {
      if (row.clientId == clientId) return row;
    }
    return null;
  }

  test('a row left unfinished is finished by the catch-up', () async {
    // What speaking into the phone actually does: the row goes on the day
    // first, in the person's own words, with nothing worked out.
    final name = await said.heard(
      day: day,
      words: 'I had two slices of toast with butter',
    );
    await outbox.drain();

    final before = await rowNamed(name);
    expect(before, isNotNull, reason: 'the row never reached the house');
    expect(before!.stillBeingWorkedOut, isTrue,
        reason: 'the house does not think this row is unfinished, so the '
            'catch-up has nothing to be tested against');
    expect(before.kcal ?? 0, 0,
        reason: 'a row nobody has worked out should carry no figure yet');

    // This is the call Home now makes on opening, given the day it just read.
    final view = await days.today(day);
    final settled = await said.catchUp(view.logged);

    expect(settled, greaterThan(0),
        reason: 'the catch-up reached the house and nothing settled');

    final after = await rowNamed(name);
    expect(after, isNotNull, reason: 'the row vanished');
    expect(after!.stillBeingWorkedOut, isFalse,
        reason: 'still reads "Something you said" after the catch-up ran');
    expect(after.label, isNot('Something you said'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
