/// Weight, its history, and the trend — the phone half.
///
/// Behaviour under test (Release H, TM-0030):
///
///  * the trend appears under the weight already on Profile, and the dated
///    history opens off that same row. No weight tab, no weight screen: Aidan
///    stopped an earlier build over exactly this, a second surface doing a job
///    an existing one already did;
///  * the line a person reads says which way it is going in words they would
///    have used themselves, and says nothing at all when there is not enough
///    to say it honestly;
///  * weights come in from Apple Health one at a time through the queue that
///    already carries everything else, named after their day so bringing the
///    same stretch in twice changes nothing;
///  * and a weight somebody typed beats one that was imported for the same
///    day, whichever arrived last.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/domain/weight_record.dart';
import 'package:opennutritracker/features/weight/data/weight_repository.dart';
import 'package:opennutritracker/features/weight/domain/weight_history.dart';
import 'package:opennutritracker/features/weight/presentation/trend_line.dart';
import 'package:opennutritracker/features/weight/presentation/weight_history_sheet.dart';

import '../household/fake_household_server.dart';

/// Apple Health, without Apple Health. What it holds is set by the test.
class StubHealth implements HealthDataSource {
  Map<DateTime, double> holds = {};
  DateTime? askedFrom;

  @override
  Future<Map<DateTime, double>> weightsSince(DateTime from) async {
    askedFrom = from;
    return Map.fromEntries(
        holds.entries.where((e) => !e.value.isNaN && !e.key.isBefore(from)));
  }

  @override
  Future<double> getActiveCaloriesToday() async => 0;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late StubHealth health;
  late WeightRepository weights;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    health = StubHealth();
    weights = WeightRepository(household, logger, health);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Widget sheet() => MaterialApp(
        home: Scaffold(body: WeightHistorySheet(repository: weights)),
      );

  group('the dated history', () {
    test('comes back oldest first, with the trend on every day', () async {
      mini.weighed('2026-08-17', 80.0);
      mini.weighed('2026-08-18', 90.0);
      final history = await weights.history();
      expect(history.readings.map((r) => r.day),
          ['2026-08-17', '2026-08-18']);
      expect(history.readings.map((r) => r.trend), [80.0, 81.0]);
    });

    test('a person with no weights has an empty history, not an error',
        () async {
      final history = await weights.history();
      expect(history.isEmpty, isTrue);
      expect(history.latest, isNull);
      expect(history.trend, isNull);
    });

    test('the latest reading is the last day', () async {
      mini.weighed('2026-08-18', 82.1);
      mini.weighed('2026-08-16', 82.9);
      expect((await weights.history()).latest!.day, '2026-08-18');
    });

    test('nobody has said whose phone this is, so there is nothing to show',
        () async {
      final fresh = HouseholdRepository(ConfigDao(db), api());
      final theirs = WeightRepository(fresh, logger, health);
      expect((await theirs.history()).isEmpty, isTrue);
    });
  });

  group('the line a person reads', () {
    WeightHistory made(num? trend, num? aWeek) => WeightHistory(
          readings: [
            WeightRecord(day: '2026-08-18', kg: trend ?? 0, trend: trend),
          ],
          trend: trend,
          aWeek: aWeek,
        );

    test('says nothing at all when there are no weights', () {
      expect(TrendLine.of(const WeightHistory()), isNull);
    });

    test('says which way it is going in words', () {
      expect(TrendLine.of(made(82.3, -0.4)), contains('Down 0.4 kg a week'));
      expect(TrendLine.of(made(82.3, 0.4)), contains('Up 0.4 kg a week'));
    });

    test('never puts a second weight figure next to the weight', () {
      // The fault of 20 August 2026: this line opened with the smoothed trend
      // — "Trending 82.4 kg" — and sat directly under a weight of 115 kg, so
      // the row carried two numbers that disagreed and nothing said which one
      // counted. A direction is the only thing this line is for.
      for (final week in [-0.4, 0.4, 0.05, null]) {
        final line = TrendLine.of(made(82.34, week));
        expect(line, isNot(contains('82.3')), reason: 'week=$week');
        expect(line, isNot(contains('Trending')), reason: 'week=$week');
      }
    });

    test('calls a week that barely moved steady rather than a direction', () {
      expect(TrendLine.of(made(82.3, 0.05)), contains(TrendLine.steady));
      expect(TrendLine.of(made(82.3, -0.05)), contains(TrendLine.steady));
    });

    test('admits when there is not yet enough to say which way', () {
      expect(TrendLine.of(made(82.3, null)), contains(TrendLine.notEnoughYet));
    });

    test('speaks in pounds to somebody who uses pounds', () {
      final line = TrendLine.of(made(80.0, -0.5), imperial: true)!;
      expect(line, contains('lbs'));
      expect(line, isNot(contains('kg')));
      expect(line, contains('Down 1.1 lbs a week'));
    });

    test('a small weekly change survives being put into pounds', () {
      // The app's usual converter rounds to whole pounds, which turns two
      // hundred grams a week into "down 0.0 lbs" — a person losing weight
      // steadily, told nothing is happening.
      final line = TrendLine.of(made(80.0, -0.2), imperial: true)!;
      expect(line, contains('Down 0.4 lbs a week'));
    });
  });

  group('bringing them in from Apple Health', () {
    test('each reading goes through the queue, one at a time', () async {
      health.holds = {
        DateTime(2026, 8, 16): 83.0,
        DateTime(2026, 8, 17): 82.6,
      };
      expect(await weights.bringInFromAppleHealth(), 2);
      expect(await outbox.pendingCount(), 2);
    });

    test('a reading is named after its day', () async {
      health.holds = {DateTime(2026, 8, 16): 83.0};
      await weights.bringInFromAppleHealth();
      await outbox.drain();
      expect(mini.weights.single['client_id'], 'health-2026-08-16');
    });

    test('it says where it came from', () async {
      health.holds = {DateTime(2026, 8, 16): 83.0};
      await weights.bringInFromAppleHealth();
      await outbox.drain();
      expect(mini.weights.single['source'], 'health');
    });

    test('the same stretch brought in twice stores it once', () async {
      health.holds = {DateTime(2026, 8, 16): 83.0};
      await weights.bringInFromAppleHealth();
      await outbox.drain();
      health.askedFrom = null;
      await weights.bringInFromAppleHealth();
      await outbox.drain();
      expect(mini.weights.length, 1);
    });

    test('it only asks for the days it has not already got', () async {
      mini.weighed('2026-08-16', 83.0);
      await weights.bringInFromAppleHealth();
      expect(health.askedFrom, DateTime(2026, 8, 17));
    });

    test('with nothing on record it reaches back a year, not forever',
        () async {
      await weights.bringInFromAppleHealth();
      final reach = DateTime.now().difference(health.askedFrom!);
      expect(reach.inDays, closeTo(WeightRepository.firstReach.inDays, 1));
    });

    test('nothing new in Apple Health queues nothing', () async {
      expect(await weights.bringInFromAppleHealth(), 0);
      expect(await outbox.pendingCount(), 0);
    });
  });

  group('a typed weight', () {
    test('typed twice in a day is a correction, and the correction wins',
        () async {
      await weights.typed(DateTime(2026, 8, 18), 82.0);
      await weights.typed(DateTime(2026, 8, 18), 81.5);
      await outbox.drain();

      // The day reads as the second number, which is the whole point of
      // calling it a correction. This assertion is the one that was missing on
      // 20 August: the test checked only that a day held a single reading, and
      // a *discarded* correction satisfies that just as well as an applied one
      // does. So it passed while Aidan typed 114.8 over 115.0 on his phone and
      // the house went on believing 115.0.
      expect((await weights.history()).latest!.kg, 81.5);
    });

    test('beats one imported for the same day, whichever arrived last',
        () async {
      mini.weighed('2026-08-18', 82.0);
      mini.weighed('2026-08-18', 99.0, source: 'health');
      final history = await weights.history();
      expect(history.latest!.kg, 82.0);
      expect(history.latest!.typed, isTrue);
    });

    test('and the reading it beat is still on record', () async {
      mini.weighed('2026-08-18', 82.0);
      mini.weighed('2026-08-18', 99.0, source: 'health');
      expect(mini.weights.length, 2);
    });
  });

  group('the history sheet', () {
    testWidgets('lists the days, newest first', (tester) async {
      mini.weighed('2026-08-17', 83.0);
      mini.weighed('2026-08-18', 82.4);
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(shown.indexOf('82.4 kg'), lessThan(shown.indexOf('83.0 kg')));
    });

    testWidgets('says where a reading came from when it was not the scales',
        (tester) async {
      mini.weighed('2026-08-17', 83.0, source: 'health');
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.fromHealth), findsOneWidget);
    });

    testWidgets('says nothing about where a typed reading came from',
        (tester) async {
      mini.weighed('2026-08-17', 83.0);
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.fromHealth), findsNothing);
    });

    testWidgets('an empty history says so rather than showing a blank list',
        (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.nothingYet), findsOneWidget);
    });

    testWidgets('offers to bring them in from Apple Health', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.bringIn), findsOneWidget);
    });

    testWidgets('says how many it brought in', (tester) async {
      health.holds = {
        DateTime(2026, 8, 16): 83.0,
        DateTime(2026, 8, 17): 82.6,
      };
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      await tester.tap(find.text(WeightHistorySheet.bringIn));
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.broughtIn(2)), findsOneWidget);
    });

    testWidgets('says so plainly when there was nothing new', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      await tester.tap(find.text(WeightHistorySheet.bringIn));
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.foundNothing), findsOneWidget);
    });

    testWidgets('one reading is a reading, not 1 readings', (tester) async {
      expect(WeightHistorySheet.broughtIn(1), contains('1 reading.'));
      expect(WeightHistorySheet.broughtIn(2), contains('2 readings.'));
    });

    testWidgets('an unreachable Mini is said out loud, not shown as empty',
        (tester) async {
      mini.reachable = false;
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.unreachable), findsOneWidget);
    });

    testWidgets('and it will not import blind while it cannot be reached',
        (tester) async {
      mini.reachable = false;
      health.holds = {DateTime(2026, 8, 16): 83.0};
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      await tester.tap(find.text(WeightHistorySheet.bringIn));
      await tester.pumpAndSettle();
      expect(find.text(WeightHistorySheet.cannotBringIn), findsOneWidget);
      expect(await outbox.pendingCount(), 0);
    });
  });

  group('how a day is written', () {
    test('short, and the way a person says it', () {
      expect(WeightHistorySheet.when('2026-08-18'), '18 Aug');
      expect(WeightHistorySheet.when('2026-01-01'), '1 Jan');
    });
  });
}
