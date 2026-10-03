import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

@GenerateNiceMocks([
  MockSpec<GetConfigUsecase>(),
  MockSpec<AddConfigUsecase>(),
  MockSpec<GetIntakeUsecase>(),
  MockSpec<DeleteIntakeUsecase>(),
  MockSpec<UpdateIntakeUsecase>(),
  MockSpec<GetUserActivityUsecase>(),
  MockSpec<DeleteUserActivityUsecase>(),
  MockSpec<AddTrackedDayUsecase>(),
  MockSpec<GetKcalGoalUsecase>(),
  MockSpec<GetMacroGoalUsecase>(),
  MockSpec<GetTrackedDayUsecase>(),
  MockSpec<HealthRepository>(),
  MockSpec<ConfigRepository>(),
])
import 'home_bloc_refresh_test.mocks.dart';

void main() {
  group('HomeBloc RefreshActiveCaloriesEvent', () {
    late MockHealthRepository healthRepository;
    late MockGetKcalGoalUsecase getKcalGoalUsecase;
    late MockGetMacroGoalUsecase getMacroGoalUsecase;
    late HomeBloc bloc;

    HomeBloc buildBloc() => HomeBloc(
          MockGetConfigUsecase(),
          MockAddConfigUsecase(),
          MockGetIntakeUsecase(),
          MockDeleteIntakeUsecase(),
          MockUpdateIntakeUsecase(),
          MockGetUserActivityUsecase(),
          MockDeleteUserActivityUsecase(),
          MockAddTrackedDayUsecase(),
          getKcalGoalUsecase,
          getMacroGoalUsecase,
          MockGetTrackedDayUsecase(),
          healthRepository,
          MockConfigRepository(),
        );

    HomeLoadedState seedState() => const HomeLoadedState(
          showDisclaimerDialog: false,
          totalKcalDaily: 2000,
          totalKcalLeft: 1500,
          totalKcalSupplied: 500,
          totalKcalBurned: 0,
          totalCarbsIntake: 0,
          totalFatsIntake: 0,
          totalProteinsIntake: 0,
          totalCarbsGoal: 200,
          totalFatsGoal: 60,
          totalProteinsGoal: 150,
          userActivityList: [],
          breakfastIntakeList: [],
          lunchIntakeList: [],
          dinnerIntakeList: [],
          snackIntakeList: [],
          usesImperialUnits: false,
          totalKcalBase: 1800,
          totalKcalEarned: 200,
          activeCaloriesToday: 100,
          healthKitConnected: true,
        );

    setUp(() {
      healthRepository = MockHealthRepository();
      getKcalGoalUsecase = MockGetKcalGoalUsecase();
      getMacroGoalUsecase = MockGetMacroGoalUsecase();
      bloc = buildBloc();
    });

    tearDown(() => bloc.close());

    test('re-fetches HealthKit and emits updated active calories + allowance',
        () async {
      when(healthRepository.hasPermission()).thenAnswer((_) async => true);
      when(healthRepository.fetchAndCacheActiveCalories())
          .thenAnswer((_) async => 400.0);
      when(healthRepository.getCachedActiveCalories())
          .thenAnswer((_) async => (400.0, DateTime(2026, 3, 15, 12)));
      when(getKcalGoalUsecase.getKcalGoal()).thenAnswer((_) async => 2300.0);
      when(getKcalGoalUsecase.getKcalGoal(totalKcalActivitiesParam: 0))
          .thenAnswer((_) async => 1800.0);
      when(getMacroGoalUsecase.getCarbsGoal(any))
          .thenAnswer((_) async => 230.0);
      when(getMacroGoalUsecase.getFatsGoal(any)).thenAnswer((_) async => 70.0);
      when(getMacroGoalUsecase.getProteinsGoal(any))
          .thenAnswer((_) async => 170.0);

      bloc.emit(seedState());
      bloc.add(const RefreshActiveCaloriesEvent());

      final state = await bloc.stream.firstWhere((s) =>
          s is HomeLoadedState && s.activeCaloriesToday == 400.0);
      final loaded = state as HomeLoadedState;

      expect(loaded.activeCaloriesToday, 400.0);
      expect(loaded.activeCaloriesUpdatedAt, DateTime(2026, 3, 15, 12));
      expect(loaded.totalKcalDaily, 2300.0);
      expect(loaded.totalKcalEarned, 500.0); // 2300 - 1800
      expect(loaded.totalKcalLeft, 1800.0); // 2300 - 500 supplied
      expect(loaded.totalKcalSupplied, 500);
      verify(healthRepository.fetchAndCacheActiveCalories()).called(1);
    });

    test('no permission skips HealthKit read but still recomputes allowance',
        () async {
      when(healthRepository.hasPermission()).thenAnswer((_) async => false);
      when(getKcalGoalUsecase.getKcalGoal()).thenAnswer((_) async => 2000.0);
      when(getKcalGoalUsecase.getKcalGoal(totalKcalActivitiesParam: 0))
          .thenAnswer((_) async => 1800.0);
      when(getMacroGoalUsecase.getCarbsGoal(any))
          .thenAnswer((_) async => 200.0);
      when(getMacroGoalUsecase.getFatsGoal(any)).thenAnswer((_) async => 60.0);
      when(getMacroGoalUsecase.getProteinsGoal(any))
          .thenAnswer((_) async => 150.0);

      bloc.emit(seedState());
      bloc.add(const RefreshActiveCaloriesEvent());

      await bloc.stream.firstWhere((s) =>
          s is HomeLoadedState && s.healthKitConnected == false);

      verifyNever(healthRepository.fetchAndCacheActiveCalories());
    });
  });
}
