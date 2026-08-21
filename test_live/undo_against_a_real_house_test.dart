/// The Undo rule, run against a Mantel server that is actually listening.
///
/// The other tests for this stand a pretend household up in memory. This one
/// does not: it posts to a real Mantel over the network, lets that server store
/// the row, pulls it back down the real `/intake/pending` route, and then looks
/// at the day to see which rows Undo will speak for. Nothing about the answer
/// is arranged by the test — the server decides what comes back and in what
/// shape.
///
/// **Not part of `flutter test`.** It lives outside `test/` on purpose, because
/// it fails when nothing is listening, and a suite that needs a server running
/// to be green is a suite people learn to ignore. Run it deliberately:
///
///     MANTEL=http://127.0.0.1:8790 flutter test test_live/undo_against_a_real_house_test.dart
///
/// Both directions are checked in one run against the same server: a row this
/// phone sent, and a row put on the same person's day by something else — which
/// is what the kitchen panel is from here. A change that handed Undo to
/// everything passes the first check and fails the second.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
import 'package:opennutritracker/core/utils/id_generator.dart';
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

  final base = Platform.environment['MANTEL'] ?? 'http://127.0.0.1:8790';
  final actor = Platform.environment['MANTEL_ACTOR'] ?? 'Aidan';
  final ownerId = int.parse(Platform.environment['MANTEL_PERSON'] ?? '1');

  setUpAll(() async {
    // flutter_test hands every test a stub HttpClient that answers 400 to
    // everything, which is right for a suite that must not touch the network
    // and wrong for the one test whose whole point is that it does.
    HttpOverrides.global = null;
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    // Fail loudly and early rather than through six confusing timeouts.
    final health = await http
        .get(Uri.parse('$base/health'))
        .timeout(const Duration(seconds: 5));
    expect(health.statusCode, 200,
        reason: 'no Mantel answering at $base — start one first');
  });

  late AppDatabase db;
  late IntakeRepository repo;
  late OwnRowDao own;
  late Outbox outbox;
  late MantelSyncService sync;
  late http.Client client;

  setUp(() {
    client = http.Client();
    db = AppDatabase.createInMemory();
    repo = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    own = OwnRowDao(db);
    outbox = Outbox.of(db, HouseholdApi(baseUrl: base, client: client));
    sync = MantelSyncService(
        repo,
        SecureAppStorageProvider(),
        AddTrackedDayUsecase(TrackedDayRepository(DailyStatsDao(db))),
        _FixedKcalGoal(),
        _FixedMacroGoals(),
        dataSource:
            MantelDataSource(baseUrl: base, actor: actor, client: client),
        own: own);
  });

  tearDown(() async {
    client.close();
    await db.close();
  });

  final today = DateTime.now();
  final day = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  /// Everything on today, whichever meal the house filed it under.
  Future<Map<String, IntakeEntity>> theDay() async {
    final all = <String, IntakeEntity>{};
    for (final type in IntakeTypeEntity.values) {
      for (final row in await repo.getIntakeByDateAndType(type, today)) {
        all[row.externalId ?? row.id] = row;
      }
    }
    return all;
  }

  test('a row this phone sent, and a row it did not, off the same server',
      () async {
    // ---- what this phone did -------------------------------------------
    final mine = await outbox.enqueue(
      path: '/household/entry',
      body: {
        'day': day,
        'label': 'proof toast ${DateTime.now().millisecondsSinceEpoch}',
        'kcal': 175,
        'slot': 'breakfast',
      },
      ownerId: ownerId,
      authorId: ownerId,
    );
    final drained = await outbox.drain();
    expect(drained.unreachable, isFalse, reason: 'could not reach $base');
    expect(drained.sent, 1, reason: 'the house did not take the row');

    // ---- what something else did, on the same person's day --------------
    // No part of this goes through the phone's queue, so the phone has never
    // written this name down. That is exactly the kitchen panel's position.
    final theirs = IdGenerator.getUniqueID();
    final posted = await client.post(
      Uri.parse('$base/household/entry'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'client_id': theirs,
        'day': day,
        'owner_id': ownerId,
        'author_id': ownerId,
        'label': 'proof lasagne ${DateTime.now().millisecondsSinceEpoch}',
        'kcal': 610,
        'slot': 'dinner',
      }),
    );
    expect(posted.statusCode, 200, reason: posted.body);

    // ---- pull them both down the ordinary route -------------------------
    await sync.syncPending();

    final day_ = await theDay();
    expect(day_[mine], isNotNull,
        reason: 'the phone\'s own row never came back down');
    expect(day_[theirs], isNotNull,
        reason: 'the other row never came back down');

    expect(day_[mine]!.isALocalAction, isTrue,
        reason: 'this phone sent it, so Undo is offered');
    expect(day_[theirs]!.isALocalAction, isFalse,
        reason: 'this phone did not send it, so Undo is withheld');
  });
}
