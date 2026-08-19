import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_shares.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';

part 'meal_detail_event.dart';

part 'meal_detail_state.dart';

class MealDetailBloc extends Bloc<MealDetailEvent, MealDetailState> {
  final log = Logger('MealDetailBloc');
  final AddIntakeUsecase _addIntakeUseCase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final FoodLedger _household;

  MealDetailBloc(this._addIntakeUseCase, this._addTrackedDayUsecase,
      this._getKcalGoalUsecase, this._getMacroGoalUsecase, this._household)
      : super(MealDetailInitial(
            totalQuantityConverted: '100',
            selectedUnit: UnitDropdownItem.gml.toString())) {
    on<UpdateKcalEvent>((event, emit) async {
      try {
        final selectedTotalQuantity =
            event.totalQuantity ?? state.totalQuantityConverted;
        final selectedUnit = event.selectedUnit ?? state.selectedUnit;

        if (selectedUnit.isEmpty || selectedTotalQuantity.isEmpty) {
          return;
        }

        final energyPerUnit = (event.meal.nutriments.energyPerUnit ?? 0);
        final carbsPerUnit = (event.meal.nutriments.carbohydratesPerUnit ?? 0);
        final fatPerUnit = (event.meal.nutriments.fatPerUnit ?? 0);
        final proteinPerUnit = (event.meal.nutriments.proteinsPerUnit ?? 0);

        final quantity =
            double.parse(selectedTotalQuantity.replaceAll(',', '.'));

        final convertedQuantity =
            convertQuantity(event.meal, quantity, selectedUnit);

        emit(state.copyWith(
            totalQuantityConverted: convertedQuantity.toString(),
            totalKcal: convertedQuantity * energyPerUnit,
            totalCarbs: convertedQuantity * carbsPerUnit,
            totalFat: convertedQuantity * fatPerUnit,
            totalProtein: convertedQuantity * proteinPerUnit,
            selectedUnit: selectedUnit));
      } catch (e) {
        log.severe('Error calculating kcal: $e');
      }
    });
  }

  /// Put a food on a day.
  ///
  /// Two writes, and deliberately not one. The phone's own diary is what the
  /// person holding this handset looks at; the household ledger is what the
  /// house holds and what the other phone reads. Both have always been needed
  /// and until now only the first happened, so nothing logged on a screen ever
  /// reached the Mac Mini at all.
  ///
  /// This is the one place worth putting it: five different screens — Home,
  /// Diary, the food search, the portion sheet — all add a food by calling
  /// this method, so the household write lands on every one of them at once
  /// rather than being remembered five times.
  ///
  /// [alsoFor] carries anybody else the same food was for: the "both of us"
  /// answer. Each of them gets their own row, worked out from their own
  /// amount, and every row is authored by whoever is holding the phone. Their
  /// share goes to the household ledger only — this phone's diary belongs to
  /// this phone's person.
  /// The typed amount in the unit the ledger keeps: grams, or millilitres.
  ///
  /// Pulled out of the calculation event so the "both of us" field can put the
  /// other person's amount through exactly the same arithmetic. Two copies of
  /// this would be two people's dinners disagreeing by an ounce.
  static double convertQuantity(MealEntity meal, double quantity, String unit) {
    if (unit == UnitDropdownItem.serving.toString()) {
      // For serving size, multiply by the product's serving quantity
      if (meal.servingQuantity != null) {
        return quantity * meal.servingQuantity!;
      }
      return quantity;
    }
    if (unit == UnitDropdownItem.oz.toString()) return UnitCalc.ozToG(quantity);
    if (unit == UnitDropdownItem.flOz.toString()) {
      return UnitCalc.flOzToMl(quantity);
    }
    return quantity;
  }

  void addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, MealEntity meal, DateTime day,
      {List<FoodShare> alsoFor = const []}) async {
    final quantity = double.parse(amountText.replaceAll(',', '.'));

    final intakeEntity = IntakeEntity(
        id: IdGenerator.getUniqueID(),
        unit: unit,
        amount: quantity,
        type: type,
        meal: meal,
        dateTime: day);
    await _addIntakeUseCase.addIntake(intakeEntity);
    _updateTrackedDay(intakeEntity, day);
    await _alsoTellTheHousehold(type, meal, day, quantity, alsoFor);
  }

  Future<void> _alsoTellTheHousehold(IntakeTypeEntity type, MealEntity meal,
      DateTime day, double mine, List<FoodShare> alsoFor) {
    final n = meal.nutriments;
    return _household.add(
      day: day,
      slot: type.name,
      label: meal.name ?? '',
      liquid: meal.isLiquid,
      mine: mine,
      alsoFor: alsoFor,
      foodId: HouseholdFood.idFromCode(meal.code),
      kcalPerUnit: n.energyPerUnit,
      proteinPerUnit: n.proteinsPerUnit,
      fatPerUnit: n.fatPerUnit,
      carbsPerUnit: n.carbohydratesPerUnit,
    );
  }

  Future<void> _updateTrackedDay(
      IntakeEntity intakeEntity, DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalCarbsGoal =
          await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
      final totalFatGoal =
          await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
      final totalProteinGoal =
          await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

      await _addTrackedDayUsecase.addNewTrackedDay(
          day, totalKcalGoal, totalCarbsGoal, totalFatGoal, totalProteinGoal);
    }

    _addTrackedDayUsecase.addDayCaloriesTracked(day, intakeEntity.totalKcal);
    _addTrackedDayUsecase.addDayMacrosTracked(day,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
  }
}

enum UnitDropdownItem {
  g,
  ml,
  gml,
  oz,
  flOz,
  serving;

  UnitDropdownItem fromString(String value) {
    switch (value) {
      case 'g':
        return UnitDropdownItem.g;
      case 'ml':
        return UnitDropdownItem.ml;
      case 'g/ml':
        return UnitDropdownItem.gml;
      case 'oz':
        return UnitDropdownItem.oz;
      case 'fl oz' || 'fl.oz':
        return UnitDropdownItem.flOz;
      case 'serving':
        return UnitDropdownItem.serving;
      default:
        return UnitDropdownItem.gml;
    }
  }

  @override
  String toString() {
    switch (this) {
      case UnitDropdownItem.g:
        return 'g';
      case UnitDropdownItem.ml:
        return 'ml';
      case UnitDropdownItem.gml:
        return 'g/ml';
      case UnitDropdownItem.oz:
        return 'oz';
      case UnitDropdownItem.flOz:
        return 'fl.oz';
      case UnitDropdownItem.serving:
        return 'serving';
    }
  }
}
