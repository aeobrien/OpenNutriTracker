import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';

@GenerateMocks([ConfigDao])
import 'config_repository_test.mocks.dart';

void main() {
  late MockConfigDao mockDao;
  late ConfigRepository repo;

  setUp(() {
    mockDao = MockConfigDao();
    repo = ConfigRepository(mockDao);
  });

  group('day boundary', () {
    test('getDayBoundaryHour returns default 2 when not set', () async {
      when(mockDao.getDouble('dayBoundaryHour')).thenAnswer((_) async => null);
      expect(await repo.getDayBoundaryHour(), 2);
    });

    test('getDayBoundaryHour returns stored value', () async {
      when(mockDao.getDouble('dayBoundaryHour'))
          .thenAnswer((_) async => 4.0);
      expect(await repo.getDayBoundaryHour(), 4);
    });

    test('setDayBoundaryHour writes to dao', () async {
      when(mockDao.setDouble('dayBoundaryHour', 5.0))
          .thenAnswer((_) async {});
      await repo.setDayBoundaryHour(5);
      verify(mockDao.setDouble('dayBoundaryHour', 5.0)).called(1);
    });
  });

  group('macro mode', () {
    test('getMacroMode returns percentage by default', () async {
      when(mockDao.getValue('macroMode')).thenAnswer((_) async => null);
      expect(await repo.getMacroMode(), 'percentage');
    });

    test('getMacroMode returns stored value', () async {
      when(mockDao.getValue('macroMode')).thenAnswer((_) async => 'grams');
      expect(await repo.getMacroMode(), 'grams');
    });

    test('setMacroMode writes to dao', () async {
      when(mockDao.setValue('macroMode', 'grams')).thenAnswer((_) async {});
      await repo.setMacroMode('grams');
      verify(mockDao.setValue('macroMode', 'grams')).called(1);
    });
  });

  group('fixed macro grams', () {
    test('getFixedProteinGrams returns null when not set', () async {
      when(mockDao.getDouble('fixedProteinGrams'))
          .thenAnswer((_) async => null);
      expect(await repo.getFixedProteinGrams(), isNull);
    });

    test('setFixedProteinGrams writes value', () async {
      when(mockDao.setDouble('fixedProteinGrams', 150.0))
          .thenAnswer((_) async {});
      await repo.setFixedProteinGrams(150.0);
      verify(mockDao.setDouble('fixedProteinGrams', 150.0)).called(1);
    });

    test('setFixedProteinGrams with null deletes key', () async {
      when(mockDao.deleteKey('fixedProteinGrams'))
          .thenAnswer((_) async {});
      await repo.setFixedProteinGrams(null);
      verify(mockDao.deleteKey('fixedProteinGrams')).called(1);
    });

    test('getFixedCarbsGrams returns stored value', () async {
      when(mockDao.getDouble('fixedCarbsGrams'))
          .thenAnswer((_) async => 200.0);
      expect(await repo.getFixedCarbsGrams(), 200.0);
    });

    test('getFixedFatGrams returns stored value', () async {
      when(mockDao.getDouble('fixedFatGrams'))
          .thenAnswer((_) async => 65.0);
      expect(await repo.getFixedFatGrams(), 65.0);
    });
  });

  group('exercise multiplier', () {
    test('returns default 0.75 when not set', () async {
      when(mockDao.getDouble('exerciseMultiplier'))
          .thenAnswer((_) async => null);
      expect(await repo.getExerciseMultiplier(), 0.75);
    });

    test('returns stored value', () async {
      when(mockDao.getDouble('exerciseMultiplier'))
          .thenAnswer((_) async => 0.5);
      expect(await repo.getExerciseMultiplier(), 0.5);
    });
  });
}
