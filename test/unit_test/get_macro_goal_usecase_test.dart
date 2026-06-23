import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';

@GenerateMocks([ConfigRepository])
import 'get_macro_goal_usecase_test.mocks.dart';

void main() {
  late MockConfigRepository mockConfigRepo;
  late GetMacroGoalUsecase usecase;

  final defaultConfig = ConfigEntity(
    false, false, false, AppThemeEntity.system,
    usesImperialUnits: false,
  );

  setUp(() {
    mockConfigRepo = MockConfigRepository();
    usecase = GetMacroGoalUsecase(mockConfigRepo);
  });

  group('percentage mode', () {
    test('getCarbsGoal uses percentage when mode is percentage', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'percentage');
      when(mockConfigRepo.getConfig())
          .thenAnswer((_) async => defaultConfig);

      final result = await usecase.getCarbsGoal(2000);
      // Default 60% of 2000 = 1200 kcal / 4 = 300g
      expect(result, 300.0);
    });

    test('getProteinsGoal uses percentage when mode is percentage', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'percentage');
      when(mockConfigRepo.getConfig())
          .thenAnswer((_) async => defaultConfig);

      final result = await usecase.getProteinsGoal(2000);
      // Default 15% of 2000 = 300 kcal / 4 = 75g
      expect(result, 75.0);
    });

    test('getFatsGoal uses percentage when mode is percentage', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'percentage');
      when(mockConfigRepo.getConfig())
          .thenAnswer((_) async => defaultConfig);

      final result = await usecase.getFatsGoal(2000);
      // Default 25% of 2000 = 500 kcal / 9 ≈ 55.56g
      expect(result, closeTo(55.56, 0.1));
    });
  });

  group('grams mode', () {
    test('getCarbsGoal returns fixed grams when in grams mode', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'grams');
      when(mockConfigRepo.getFixedCarbsGrams())
          .thenAnswer((_) async => 250.0);

      final result = await usecase.getCarbsGoal(2000);
      expect(result, 250.0);
    });

    test('getProteinsGoal returns fixed grams when in grams mode', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'grams');
      when(mockConfigRepo.getFixedProteinGrams())
          .thenAnswer((_) async => 180.0);

      final result = await usecase.getProteinsGoal(2000);
      expect(result, 180.0);
    });

    test('getFatsGoal returns fixed grams when in grams mode', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'grams');
      when(mockConfigRepo.getFixedFatGrams())
          .thenAnswer((_) async => 70.0);

      final result = await usecase.getFatsGoal(2000);
      expect(result, 70.0);
    });

    test('falls back to percentage when fixed grams not set', () async {
      when(mockConfigRepo.getMacroMode())
          .thenAnswer((_) async => 'grams');
      when(mockConfigRepo.getFixedCarbsGrams())
          .thenAnswer((_) async => null);
      when(mockConfigRepo.getConfig())
          .thenAnswer((_) async => defaultConfig);

      final result = await usecase.getCarbsGoal(2000);
      expect(result, 300.0); // Falls back to 60%
    });
  });
}
