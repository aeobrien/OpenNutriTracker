import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/intake/data/data_source/mantel_data_source.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';

/// Fixed goals. What a new day's targets should be is decided and tested
/// elsewhere; here they only need to be a number so the day can be created.
class _FixedKcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal(
          {UserEntity? userEntity,
          double? totalKcalActivitiesParam,
          double? kcalUserAdjustment}) async =>
      2000;
}

class _FixedMacroGoals extends Fake implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double kcal) async => 250;
  @override
  Future<double> getFatsGoal(double kcal) async => 65;
  @override
  Future<double> getProteinsGoal(double kcal) async => 100;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage has no platform under unit tests — stub it so the
  // "not configured" path (which reads storage) returns null cleanly.
  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  late AppDatabase db;
  late LogEntryDao logEntryDao;
  late IntakeRepository repo;
  late AddTrackedDayUsecase trackedDays;
  late GetTrackedDayUsecase readTrackedDay;

  setUp(() {
    db = AppDatabase.createInMemory();
    logEntryDao = LogEntryDao(db);
    repo = IntakeRepository(logEntryDao, FoodItemDao(db));
    final trackedDayRepo = TrackedDayRepository(DailyStatsDao(db));
    trackedDays = AddTrackedDayUsecase(trackedDayRepo);
    readTrackedDay = GetTrackedDayUsecase(trackedDayRepo);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> intake(String id, String slot,
          {String label = 'Meal', double kcal = 100}) =>
      {
        'id': id,
        'actor': 'aidan',
        'label': label,
        'kcal': kcal,
        'protein': 5,
        'carbs': 10,
        'fat': 2,
        'meal_slot': slot,
        'eaten_at': '2026-06-25T18:00:00Z',
        'tz': 'Europe/London',
        'source': 'estimate',
        'confidence': 0.6,
      };

  /// A stateful fake of Mantel's intake endpoints. Serves [pool] from
  /// /intake/pending paginated by id; on /intake/ack records the ids and, when
  /// [honourAcks], removes them from the pool (the real server marks them
  /// consumed). When [honourAcks] is false, the same items keep coming back —
  /// which is exactly the "dropped ack" scenario the externalId dedup must
  /// survive without double-logging.
  MantelDataSource dataSource(
    List<Map<String, dynamic>> pool, {
    bool honourAcks = true,
    List<String>? acked,
  }) {
    final client = MockClient((req) async {
      if (req.url.path == '/intake/pending') {
        final after = req.url.queryParameters['after_id'];
        final limit = int.parse(req.url.queryParameters['limit'] ?? '50');
        final items = pool
            .where((e) =>
                after == null || (e['id'] as String).compareTo(after) > 0)
            .toList()
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
        final page = items.take(limit).toList();
        return http.Response(
            jsonEncode({
              'ok': true,
              'actor': 'aidan',
              'count': page.length,
              'pending': page,
            }),
            200);
      }
      if (req.url.path == '/intake/ack') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final ids = (body['ids'] as List).cast<String>();
        acked?.addAll(ids);
        if (honourAcks) {
          pool.removeWhere((e) => ids.contains(e['id']));
        }
        return http.Response(
            jsonEncode({'ok': true, 'acked': ids.length}), 200);
      }
      return http.Response('not found', 404);
    });
    return MantelDataSource(
        baseUrl: 'http://h:8770', actor: 'aidan', client: client);
  }

  MantelSyncService service(MantelDataSource ds) =>
      MantelSyncService(repo, SecureAppStorageProvider(), trackedDays,
          _FixedKcalGoal(), _FixedMacroGoals(), dataSource: ds);

  test('not configured returns a no-op result', () async {
    // No injected data source + no stored config -> notConfigured.
    final svc = MantelSyncService(repo, SecureAppStorageProvider(),
        trackedDays, _FixedKcalGoal(), _FixedMacroGoals());
    final result = await svc.syncPending();
    expect(result.configured, isFalse);
    expect(result.synced, 0);
  });

  test('pulls pending meals into the diary and acks them', () async {
    final acked = <String>[];
    final ds = dataSource([
      intake('i1', 'breakfast', label: 'Porridge', kcal: 250),
      intake('i2', 'dinner', label: 'Salmon', kcal: 400),
    ], acked: acked);

    final result = await service(ds).syncPending();

    expect(result.synced, 2);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    expect(result.hasNewEntries, isTrue);

    // Both acked back to Mantel.
    expect(acked, containsAll(['i1', 'i2']));

    // Provenance recorded so a re-pull would dedup.
    expect(await repo.hasExternalIntake('i1'), isTrue);
    expect(await repo.hasExternalIntake('i2'), isTrue);

    // Landed in the correct diary slots on the correct local day.
    final day = DateTime.parse('2026-06-25T18:00:00Z').toLocal();
    final breakfast =
        await repo.getIntakeByDateAndType(IntakeTypeEntity.breakfast, day);
    final dinner =
        await repo.getIntakeByDateAndType(IntakeTypeEntity.dinner, day);
    expect(breakfast.map((e) => e.quickAddLabel), contains('Porridge'));
    expect(dinner.map((e) => e.quickAddLabel), contains('Salmon'));
  });

  test('re-pull of the same items is idempotent — never double-logs', () async {
    // honourAcks:false -> the server keeps returning the same two items even
    // after they were acked (simulates a dropped ack). The externalId dedup
    // must skip them on the second pull, not insert duplicates.
    final pool = [
      intake('i1', 'lunch'),
      intake('i2', 'snack'),
    ];
    final ds = dataSource(pool, honourAcks: false);
    final svc = service(ds);

    final first = await svc.syncPending();
    expect(first.synced, 2);

    final second = await svc.syncPending();
    expect(second.synced, 0);
    expect(second.skipped, 2);

    // Exactly two log entries total — no duplicates.
    final all = await logEntryDao.getAllRaw();
    expect(all.length, 2);
  });

  test('paginates across multiple pages (page size 50)', () async {
    final pool = List.generate(
      60,
      // ids i00..i59 sort lexicographically in insert order.
      (i) => intake('i${i.toString().padLeft(2, '0')}', 'lunch'),
    );
    final ds = dataSource(pool); // honourAcks:true

    final result = await service(ds).syncPending();

    expect(result.synced, 60);
    final all = await logEntryDao.getAllRaw();
    expect(all.length, 60);
    // Server pool drained (all acked + removed).
    expect(pool, isEmpty);
  });

  test('a synced meal counts towards the day, not just onto its list', () async {
    // The defect this covers: on 20 August a spoken meal moved the ring on Home
    // and appeared under Snack, while the Diary's summary for the same day read
    // "Nothing added" and the week's table read zero — because Home sums the
    // meals themselves and those two read the day's stored totals, which
    // nothing was writing.
    final ds = dataSource([
      intake('i1', 'breakfast', label: 'Porridge', kcal: 250),
      intake('i2', 'dinner', label: 'Salmon', kcal: 400),
    ]);

    await service(ds).syncPending();

    final day = DateTime.parse('2026-06-25T18:00:00Z').toLocal();
    final tracked = await readTrackedDay.getTrackedDay(day);
    expect(tracked, isNotNull, reason: 'the day itself was never created');
    expect(tracked!.caloriesTracked, 650);
    expect(tracked.carbsTracked, 20);
    expect(tracked.fatTracked, 4);
    expect(tracked.proteinTracked, 10);
  });

  test('a second sync of the same meal does not count it twice', () async {
    final ds = dataSource(
        [intake('i1', 'breakfast', label: 'Porridge', kcal: 250)],
        honourAcks: false);

    final svc = service(ds);
    await svc.syncPending();
    await svc.syncPending();

    final day = DateTime.parse('2026-06-25T18:00:00Z').toLocal();
    expect((await readTrackedDay.getTrackedDay(day))!.caloriesTracked, 250);
  });
}
