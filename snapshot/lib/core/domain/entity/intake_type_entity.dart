import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum IntakeTypeEntity {
  breakfast,
  lunch,
  dinner,
  snack;

  factory IntakeTypeEntity.fromIntakeTypeDBO(IntakeTypeDBO intakeTypeDBO) {
    IntakeTypeEntity intakeTypeEntity;
    switch (intakeTypeDBO) {
      case IntakeTypeDBO.breakfast:
        intakeTypeEntity = IntakeTypeEntity.breakfast;
        break;
      case IntakeTypeDBO.lunch:
        intakeTypeEntity = IntakeTypeEntity.lunch;
        break;
      case IntakeTypeDBO.dinner:
        intakeTypeEntity = IntakeTypeEntity.dinner;
        break;
      case IntakeTypeDBO.snack:
        intakeTypeEntity = IntakeTypeEntity.snack;
        break;
    }
    return intakeTypeEntity;
  }

  IconData getIconData() {
    IconData icon;
    switch (this) {
      case IntakeTypeEntity.breakfast:
        icon = Icons.bakery_dining_outlined;
        break;
      case IntakeTypeEntity.lunch:
        icon = Icons.lunch_dining_outlined;
        break;
      case IntakeTypeEntity.dinner:
        icon = Icons.dinner_dining_outlined;
        break;
      case IntakeTypeEntity.snack:
        icon = CustomIcons.food_apple_outline;
    }
    return icon;
  }

  /// The [AddMealType] used when adding a new entry to this meal slot.
  AddMealType getAddMealType() {
    switch (this) {
      case IntakeTypeEntity.breakfast:
        return AddMealType.breakfastType;
      case IntakeTypeEntity.lunch:
        return AddMealType.lunchType;
      case IntakeTypeEntity.dinner:
        return AddMealType.dinnerType;
      case IntakeTypeEntity.snack:
        return AddMealType.snackType;
    }
  }

  /// The localized section title for this meal slot.
  String getLabel(BuildContext context) {
    switch (this) {
      case IntakeTypeEntity.breakfast:
        return S.of(context).breakfastLabel;
      case IntakeTypeEntity.lunch:
        return S.of(context).lunchLabel;
      case IntakeTypeEntity.dinner:
        return S.of(context).dinnerLabel;
      case IntakeTypeEntity.snack:
        return S.of(context).snackLabel;
    }
  }
}
