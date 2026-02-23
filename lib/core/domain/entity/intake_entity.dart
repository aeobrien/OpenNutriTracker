import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart' as drift;
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class IntakeEntity extends Equatable {
  final String id;
  final String unit;
  final double amount;
  final IntakeTypeEntity type;
  final DateTime dateTime;
  final String entryType;
  final String? quickAddLabel;

  /// Snapshot values from the log entry row. For quick-add entries (amount=1),
  /// these are the user-provided totals. For food entries, these are computed
  /// from the food item nutriments at log time.
  final double snapshotKcal;
  final double snapshotProtein;
  final double snapshotCarbs;
  final double snapshotFat;

  final MealEntity meal;

  const IntakeEntity(
      {required this.id,
      required this.unit,
      required this.amount,
      required this.type,
      required this.meal,
      required this.dateTime,
      this.entryType = 'food',
      this.quickAddLabel,
      this.snapshotKcal = 0,
      this.snapshotProtein = 0,
      this.snapshotCarbs = 0,
      this.snapshotFat = 0});

  bool get isQuickAdd => entryType == 'quickAdd';

  factory IntakeEntity.fromLogEntry(LogEntryWithFoodItem row) {
    final entry = row.logEntry;
    final foodItem = row.foodItem;
    return IntakeEntity(
        id: entry.id,
        unit: entry.unit,
        amount: entry.amount,
        type: IntakeTypeEntity.values.firstWhere(
            (e) => e.name == entry.mealSlot,
            orElse: () => IntakeTypeEntity.snack),
        meal: foodItem != null
            ? MealEntity.fromFoodItem(foodItem)
            : MealEntity.empty(),
        dateTime:
            DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
        entryType: entry.entryType,
        quickAddLabel: entry.quickAddLabel,
        snapshotKcal: entry.snapshotKcal,
        snapshotProtein: entry.snapshotProtein,
        snapshotCarbs: entry.snapshotCarbs,
        snapshotFat: entry.snapshotFat);
  }

  factory IntakeEntity.fromIntakeDBO(IntakeDBO intakeDBO) {
    return IntakeEntity(
        id: intakeDBO.id,
        unit: intakeDBO.unit,
        amount: intakeDBO.amount,
        type: IntakeTypeEntity.fromIntakeTypeDBO(intakeDBO.type),
        meal: MealEntity.fromMealDBO(intakeDBO.meal),
        dateTime: intakeDBO.dateTime);
  }

  /// For quick-add entries, use snapshot values directly (amount is always 1).
  /// For food entries, compute from the meal's nutriments.
  double get totalKcal => isQuickAdd
      ? snapshotKcal
      : amount * (meal.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram => isQuickAdd
      ? snapshotCarbs
      : amount * (meal.nutriments.carbohydratesPerUnit ?? 0);

  double get totalFatsGram => isQuickAdd
      ? snapshotFat
      : amount * (meal.nutriments.fatPerUnit ?? 0);

  double get totalProteinsGram => isQuickAdd
      ? snapshotProtein
      : amount * (meal.nutriments.proteinsPerUnit ?? 0);

  @override
  List<Object?> get props => [id, unit, amount, type, dateTime, entryType];
}
