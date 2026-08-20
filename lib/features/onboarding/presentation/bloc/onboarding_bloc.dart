import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/profile_handover.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_data_mask_entity.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final userSelection = UserDataMaskEntity();
  final AddUserUsecase _addUserUsecase;
  final AddConfigUsecase _addConfigUsecase;

  /// The three below are what makes setting the app up a once-ever thing
  /// rather than a once-per-reinstall thing. All optional, so a test can build
  /// this bloc with nothing but the two above and get the old behaviour.
  final GetUserUsecase? _existing;
  final ProfileHandover? _handover;
  final HouseholdRepository? _household;

  OnboardingBloc(this._addUserUsecase, this._addConfigUsecase,
      [this._existing, this._handover, this._household])
      : super(OnboardingInitialState()) {
    on<LoadOnboardingEvent>((event, emit) async {
      emit(OnboardingLoadingState());

      // Somebody may have said whose phone this is a moment ago, and the
      // household may have handed back everything this screen was going to
      // ask. Checked here rather than before the app starts because on a fresh
      // install nobody knows whose phone it is yet, and without that there is
      // nobody to ask about.
      if (_existing != null && await _existing.hasUserData()) {
        emit(OnboardingNotNeededState());
        return;
      }

      emit(OnboardingLoadedState());
    });
  }

  void saveOnboardingData(BuildContext context, UserEntity userEntity,
      bool hasAcceptedDataCollection, bool usesImperialUnits) async {
    _addUserUsecase.addUser(userEntity);
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedDataCollection);
    _addConfigUsecase.setConfigUsesImperialUnits(usesImperialUnits);
    _tellTheHousehold(userEntity);
  }

  /// Hand the answers to the kitchen computer so the next reinstall does not
  /// ask for them. Deliberately not awaited by the caller: setup is finished on
  /// this phone either way, and a slow or sleeping Mini must not hold somebody
  /// on the last page of a form they have completed.
  Future<void> _tellTheHousehold(UserEntity user) async {
    final handover = _handover;
    final household = _household;
    if (handover == null || household == null) return;
    final owner = await household.storedOwner();
    if (owner == null) return;
    await handover.remember(owner, user);
  }

  double? getOverviewCalorieGoal() {
    final userEntity = userSelection.toUserEntity();
    double? calorieGoal;
    if (userEntity != null) {
      calorieGoal = CalorieGoalCalc.getTotalKcalGoal(userEntity, 0);
    }
    return calorieGoal;
  }

  double? getOverviewCarbsGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? carbsGoal;
    if (userEntity != null && calorieGoal != null) {
      carbsGoal = MacroCalc.getTotalCarbsGoal(calorieGoal);
    }
    return carbsGoal;
  }

  double? getOverviewFatGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? fatGoal;
    if (userEntity != null && calorieGoal != null) {
      fatGoal = MacroCalc.getTotalFatsGoal(calorieGoal);
    }
    return fatGoal;
  }

  double? getOverviewProteinGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? proteinGoal;
    if (userEntity != null && calorieGoal != null) {
      proteinGoal = MacroCalc.getTotalProteinsGoal(calorieGoal);
    }
    return proteinGoal;
  }
}
