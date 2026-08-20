import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserUsecase _getUserUsecase;
  final AddUserUsecase _addUserUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;

  ProfileBloc(
      this._getUserUsecase,
      this._addUserUsecase,
      this._addTrackedDayUsecase,
      this._getConfigUsecase,
      this._getKcalGoalUsecase)
      : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await _getUserUsecase.getUserData();
      final userConfig = await _getConfigUsecase.getConfig();

      emit(ProfileLoadedState(
          userEntity: user,
          usesImperialUnits: userConfig.usesImperialUnits));
    });
  }

  void updateUser(UserEntity userEntity) async {
    // Update user in DB
    await _addUserUsecase.addUser(userEntity);

    // Update Tracked Day
    await _updateTrackedDayCalorieGoal(userEntity, DateTime.now());

    // Refresh Profile
    add(LoadProfileEvent());
    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());
    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }

  Future<void> _updateTrackedDayCalorieGoal(
      UserEntity user, DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (hasTrackedDay) {
      final totalKcalGoal =
          await _getKcalGoalUsecase.getKcalGoal(userEntity: user);

      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
    }
  }

  /// Returns the user's height in cm or ft/in based on the user's config
  String getDisplayHeight(UserEntity user, bool usesImperialUnits) {
    if (usesImperialUnits) {
      // Convert cm to feet and inches
      return UnitCalc.cmToFeet(user.heightCM).toStringAsFixed(1);
    } else {
      return user.heightCM.roundToDouble().toStringAsFixed(0);
    }
  }

  /// Returns the user's weight in kg or lbs based on the user's config
  /// The weight as it appears on Profile — to one decimal place.
  ///
  /// It used to round to the whole unit, and that made a change of less than
  /// half a kilogram invisible: on 20 August 2026 Aidan set his weight to
  /// 114.8, saw "115" where "115" had been before, and reasonably concluded the
  /// app had not saved it. A weight is read off a scale to a tenth. Showing it
  /// to a tenth is what makes saving one visible, which is the only way a
  /// person can tell the difference between a change that worked and a control
  /// that quietly did nothing.
  String getDisplayWeight(UserEntity user, bool usesImperialUnits) {
    if (usesImperialUnits) {
      return UnitCalc.kgToLbs(user.weightKG).toStringAsFixed(1);
    } else {
      return user.weightKG.toStringAsFixed(1);
    }
  }
}
