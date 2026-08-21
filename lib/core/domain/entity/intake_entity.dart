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
  final String? recipeId;

  /// The name the household's own row for this is known by, when this row came
  /// from the house rather than from this phone. A correction has to reach the
  /// house by the name the house knows, not the name this phone minted for its
  /// own copy — see [householdName].
  final String? externalId;

  /// What was actually said, when this row came from a spoken capture. Null
  /// for anything nobody spoke.
  final String? said;

  /// Whether this phone is the thing that did it — see LogEntries.thisPhoneDidIt.
  final bool thisPhoneDidIt;

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
      this.recipeId,
      this.externalId,
      this.said,
      this.thisPhoneDidIt = false,
      this.snapshotKcal = 0,
      this.snapshotProtein = 0,
      this.snapshotCarbs = 0,
      this.snapshotFat = 0});

  bool get isQuickAdd => entryType == 'quickAdd';

  /// The name to correct or retire this row by at the household end.
  ///
  /// A row this phone logged carries the id the phone minted, because that is
  /// the name it gave the house at the time. A row that arrived *from* the
  /// house was given a fresh local id on the way in, so its own id means
  /// nothing there — the house knows it by [externalId]. Getting this wrong is
  /// silent: the house answers "no row called that has reached here yet" and
  /// the correction never lands.
  String get householdName => externalId ?? id;

  /// Whether this row is something this phone did.
  ///
  /// Undo is scoped to this phone's own actions. If two people are editing the
  /// same document and one adds a word, the other cannot undo it away — they
  /// can still delete it the ordinary way, but undo never reaches across. A row
  /// somebody put on this day at the kitchen panel is the same: it is not this
  /// phone's action to reverse, and un-retiring it at the house is not
  /// something undo gets to decide. The row stays removable by the ordinary
  /// path like any other.
  ///
  /// Two ways a row is this phone's. It never left — nothing from the household
  /// is attached to it. Or it did leave and came back, and the phone's own
  /// record says the phone is what sent it. Before 21 August 2026 only the
  /// first counted, so a sentence Aidan spoke into his own phone went to the
  /// house, came back, and arrived looking exactly like something his wife had
  /// said in the kitchen — and lost its Undo. His words: "Step 1 was on the
  /// phone — logging an item here would come from the phone, not from the
  /// House."
  bool get isALocalAction => externalId == null || thisPhoneDidIt;

  bool get isRecipe => entryType == 'recipe';

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
        recipeId: entry.recipeId,
        externalId: entry.externalId,
        said: entry.said,
        thisPhoneDidIt: entry.thisPhoneDidIt,
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
  bool get _usesSnapshot => isQuickAdd || isRecipe;

  double get totalKcal => _usesSnapshot
      ? snapshotKcal
      : amount * (meal.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram => _usesSnapshot
      ? snapshotCarbs
      : amount * (meal.nutriments.carbohydratesPerUnit ?? 0);

  double get totalFatsGram => _usesSnapshot
      ? snapshotFat
      : amount * (meal.nutriments.fatPerUnit ?? 0);

  double get totalProteinsGram => _usesSnapshot
      ? snapshotProtein
      : amount * (meal.nutriments.proteinsPerUnit ?? 0);

  @override
  List<Object?> get props => [id, unit, amount, type, dateTime, entryType, recipeId];
}
