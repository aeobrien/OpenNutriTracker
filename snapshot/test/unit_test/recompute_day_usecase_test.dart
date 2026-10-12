import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/domain/usecase/recompute_day_usecase.dart';

@GenerateNiceMocks([MockSpec<LogEntryDao>(), MockSpec<DailyStatsDao>()])
import 'recompute_day_usecase_test.mocks.dart';

void main() {
  group('RecomputeDayUsecase', () {
    test('class can be instantiated with mocks', () {
      final mockLogEntryDao = MockLogEntryDao();
      final mockDailyStatsDao = MockDailyStatsDao();
      final usecase = RecomputeDayUsecase(mockLogEntryDao, mockDailyStatsDao);
      expect(usecase, isA<RecomputeDayUsecase>());
    });

    test('recomputeDay skips when no DailyStat exists', () async {
      final mockLogEntryDao = MockLogEntryDao();
      final mockDailyStatsDao = MockDailyStatsDao();
      final usecase = RecomputeDayUsecase(mockLogEntryDao, mockDailyStatsDao);

      final day = DateTime(2025, 3, 15);

      when(mockLogEntryDao.getByDate(day)).thenAnswer((_) async => []);
      when(mockDailyStatsDao.getByDate(day)).thenAnswer((_) async => null);

      await usecase.recomputeDay(day);

      // Should not call upsert when there's no existing DailyStat
      verifyNever(mockDailyStatsDao.upsert(any));
    });
  });
}
