/// How the phone knows a row on the day is its own doing.
///
/// A sentence spoken into this phone goes to the household and comes back down
/// the pull. A sentence spoken at the kitchen panel goes to the household and
/// comes back down the same pull, in the same shape, through the same code.
/// From the arriving row alone the two are indistinguishable — which is why
/// asking "did it come from the house?" gave the wrong answer, and Aidan found
/// it from the outside on 21 August: *"Step 1 was on the phone — logging an
/// item here would come from the phone, not from the House."*
///
/// So the phone writes down what it does as it does it, and consults that
/// record once, as each row arrives. This file drives that whole path rather
/// than asserting the getter: a real queue mints a real id into a real
/// database, a stand-in household hands the row back, and the day is read
/// afterwards to see which rows Undo will speak for.
///
/// **Both directions are asserted deliberately.** A change that gave Undo to
/// everything would pass a one-sided test and lose the thing the rule exists
/// for — not being able to undo something somebody else said in the kitchen.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/own_row_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/intake/data/data_source/mantel_data_source.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';

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

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  late AppDatabase db;
  late IntakeRepository repo;
  late OwnRowDao own;
  late Outbox outbox;
  late AddTrackedDayUsecase trackedDays;

  setUp(() {
    db = AppDatabase.createInMemory();
    repo = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    own = OwnRowDao(db);
    trackedDays = AddTrackedDayUsecase(TrackedDayRepository(DailyStatsDao(db)));
    // A household that accepts everything. What it does with the sentence is
    // not what this file is about; that it is *this phone* that sent it is.
    final api = HouseholdApi(
        baseUrl: 'http://mini',
        client: MockClient((req) async =>
            http.Response(jsonEncode({'ok': true}), 200)));
    outbox = Outbox.of(db, api);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> arriving(String id, {String label = 'wholemeal toast'}) =>
      {
        'id': id,
        'actor': 'aidan',
        'label': label,
        'kcal': 175,
        'protein': 6,
        'carbs': 30,
        'fat': 2,
        'meal_slot': 'breakfast',
        'eaten_at': '2026-08-21T07:00:00Z',
        'tz': 'Europe/London',
        'source': 'estimate',
        'said': 'two slices of toast with butter',
      };

  MantelSyncService syncing(List<Map<String, dynamic>> pool) {
    final client = MockClient((req) async {
      if (req.url.path == '/intake/pending') {
        final after = req.url.queryParameters['after_id'];
        final items = pool
            .where((e) =>
                after == null || (e['id'] as String).compareTo(after) > 0)
            .toList()
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
        return http.Response(
            jsonEncode({
              'ok': true,
              'actor': 'aidan',
              'count': items.length,
              'pending': items,
            }),
            200);
      }
      if (req.url.path == '/intake/ack') {
        final ids =
            ((jsonDecode(req.body) as Map)['ids'] as List).cast<String>();
        pool.removeWhere((e) => ids.contains(e['id']));
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      return http.Response('not found', 404);
    });
    return MantelSyncService(
        repo,
        SecureAppStorageProvider(),
        trackedDays,
        _FixedKcalGoal(),
        _FixedMacroGoals(),
        dataSource: MantelDataSource(
            baseUrl: 'http://mini', actor: 'aidan', client: client),
        own: own);
  }

  Future<Map<String, IntakeEntity>> theDay() async {
    final rows = await repo.getIntakeByDateAndType(
        IntakeTypeEntity.breakfast, DateTime(2026, 8, 21));
    return {for (final r in rows) r.externalId ?? r.id: r};
  }

  /// Say something into this phone: the queue mints the name the house will
  /// know it by, which is the whole of what gets remembered.
  Future<String> saidIntoThisPhone() => outbox.enqueue(
        path: '/household/entry',
        body: const {'label': 'two slices of toast with butter'},
        ownerId: 1,
        authorId: 1,
      );

  test('a sentence spoken into this phone comes back as this phone\'s own', () async {
    final mine = await saidIntoThisPhone();

    await syncing([arriving(mine)]).syncPending();

    final day = await theDay();
    expect(day[mine], isNotNull, reason: 'the row should be on the day');
    expect(day[mine]!.isALocalAction, isTrue);
  });

  test('a sentence spoken at the kitchen panel does not', () async {
    // Nothing on this phone ever minted this name.
    await syncing([arriving('panel-77', label: 'lasagne')]).syncPending();

    final day = await theDay();
    expect(day['panel-77'], isNotNull);
    expect(day['panel-77']!.isALocalAction, isFalse);
  });

  test('both kinds on one day are told apart', () async {
    // The direction that matters: a change that simply offered Undo to
    // everything passes each single-sided test above and fails this one.
    final mine = await saidIntoThisPhone();

    await syncing([arriving(mine), arriving('panel-77', label: 'lasagne')])
        .syncPending();

    final day = await theDay();
    expect(day[mine]!.isALocalAction, isTrue);
    expect(day['panel-77']!.isALocalAction, isFalse);
  });

  test('the second food out of one sentence is this phone\'s too', () async {
    // One sentence becomes several rows at the house, and it names the extras
    // by adding #2 to the name the phone gave it. Those are the same action.
    final mine = await saidIntoThisPhone();

    await syncing([arriving(mine), arriving('$mine#2', label: 'butter')])
        .syncPending();

    final day = await theDay();
    expect(day[mine]!.isALocalAction, isTrue);
    expect(day['$mine#2']!.isALocalAction, isTrue);
  });

  test('a name is forgotten once it is old enough to be nobody\'s undo',
      () async {
    await own.remember('ancient',
        at: DateTime.now().subtract(const Duration(days: 40)));
    await own.remember('recent');

    await own.forgetOldOnes();

    expect(await own.didThisPhoneMint('ancient'), isFalse);
    expect(await own.didThisPhoneMint('recent'), isTrue);
  });
}
