import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

/// Pure grouping logic for the meal-grouped log on the Today dashboard.
///
/// Takes a flat list of intake entities (any order) and groups them by meal
/// slot, preserving display order breakfast -> lunch -> dinner -> snack and
/// preserving the relative order of entries within each slot. Every slot is
/// always present in the result, even when empty, so the dashboard can render
/// a stable set of sections without recomputing which slots exist.
class MealGrouping {
  const MealGrouping._();

  /// Slots in the fixed display order used by the Today dashboard.
  static const List<IntakeTypeEntity> displayOrder = [
    IntakeTypeEntity.breakfast,
    IntakeTypeEntity.lunch,
    IntakeTypeEntity.dinner,
    IntakeTypeEntity.snack,
  ];

  /// Groups [intakeList] by [IntakeTypeEntity]. The returned map always
  /// contains every slot (empty list when nothing logged for it) and iterates
  /// in [displayOrder].
  static Map<IntakeTypeEntity, List<IntakeEntity>> groupByMeal(
      List<IntakeEntity> intakeList) {
    final grouped = <IntakeTypeEntity, List<IntakeEntity>>{
      for (final slot in displayOrder) slot: <IntakeEntity>[],
    };
    for (final intake in intakeList) {
      grouped[intake.type]!.add(intake);
    }
    return grouped;
  }
}
