import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class IntakeRepository {
  final LogEntryDao _logEntryDao;
  final FoodItemDao _foodItemDao;
  final _log = Logger('IntakeRepository');

  IntakeRepository(this._logEntryDao, this._foodItemDao);

  /// Save a food item to the local database without creating a log entry.
  /// Used by label scan in ingredient mode so scanned items are available
  /// for future searches.
  Future<String> saveFoodItemOnly(MealEntity meal) async {
    final foodItemId = meal.code ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
    await _foodItemDao.upsertFoodItem(FoodItemsCompanion(
      id: Value(foodItemId),
      source: Value(meal.source.name),
      barcode: Value(meal.code),
      name: Value(meal.name),
      brand: Value(meal.brands),
      mealQuantity: Value(meal.mealQuantity),
      mealUnit: Value(meal.mealUnit),
      servingQuantity: Value(meal.servingQuantity),
      servingUnit: Value(meal.servingUnit),
      servingSize: Value(meal.servingSize),
      kcalPer100: Value(meal.nutriments.energyKcal100),
      proteinPer100: Value(meal.nutriments.proteins100),
      carbsPer100: Value(meal.nutriments.carbohydrates100),
      fatPer100: Value(meal.nutriments.fat100),
      fibrePer100: Value(meal.nutriments.fiber100),
      sugarPer100: Value(meal.nutriments.sugars100),
      saturatedFatPer100: Value(meal.nutriments.saturatedFat100),
      thumbnailImageUrl: Value(meal.thumbnailImageUrl),
      mainImageUrl: Value(meal.mainImageUrl),
      url: Value(meal.url),
      lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    _log.fine('Saved food item only: $foodItemId (${meal.name})');
    return foodItemId;
  }

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    _log.fine('Adding intake: ${intakeEntity.id}');
    final meal = intakeEntity.meal;

    // Upsert food item first
    final foodItemId = meal.code ?? 'custom_${intakeEntity.id}';
    await _foodItemDao.upsertFoodItem(FoodItemsCompanion(
      id: Value(foodItemId),
      source: Value(meal.source.name),
      barcode: Value(meal.code),
      name: Value(meal.name),
      brand: Value(meal.brands),
      mealQuantity: Value(meal.mealQuantity),
      mealUnit: Value(meal.mealUnit),
      servingQuantity: Value(meal.servingQuantity),
      servingUnit: Value(meal.servingUnit),
      servingSize: Value(meal.servingSize),
      kcalPer100: Value(meal.nutriments.energyKcal100),
      proteinPer100: Value(meal.nutriments.proteins100),
      carbsPer100: Value(meal.nutriments.carbohydrates100),
      fatPer100: Value(meal.nutriments.fat100),
      fibrePer100: Value(meal.nutriments.fiber100),
      sugarPer100: Value(meal.nutriments.sugars100),
      saturatedFatPer100: Value(meal.nutriments.saturatedFat100),
      thumbnailImageUrl: Value(meal.thumbnailImageUrl),
      mainImageUrl: Value(meal.mainImageUrl),
      url: Value(meal.url),
      lastUsedAt: Value(intakeEntity.dateTime.millisecondsSinceEpoch),
      lastUsedGrams: Value(intakeEntity.amount),
    ));

    // Insert log entry with snapshot values
    await _logEntryDao.insertEntry(LogEntriesCompanion(
      id: Value(intakeEntity.id),
      timestamp: Value(intakeEntity.dateTime.millisecondsSinceEpoch),
      mealSlot: Value(intakeEntity.type.name),
      foodItemId: Value(foodItemId),
      amount: Value(intakeEntity.amount),
      unit: Value(intakeEntity.unit),
      snapshotKcal: Value(intakeEntity.totalKcal),
      snapshotProtein: Value(intakeEntity.totalProteinsGram),
      snapshotCarbs: Value(intakeEntity.totalCarbsGram),
      snapshotFat: Value(intakeEntity.totalFatsGram),
    ));
  }

  Future<IntakeEntity> addQuickAddIntake({
    required String id,
    required double kcal,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String? label,
    required String mealSlot,
    required DateTime dateTime,
  }) async {
    _log.fine('Adding quick-add intake: $id, kcal=$kcal, label=$label');

    await _logEntryDao.insertEntry(LogEntriesCompanion(
      id: Value(id),
      timestamp: Value(dateTime.millisecondsSinceEpoch),
      mealSlot: Value(mealSlot),
      foodItemId: const Value(null),
      amount: const Value(1.0),
      unit: const Value('serving'),
      snapshotKcal: Value(kcal),
      snapshotProtein: Value(protein),
      snapshotCarbs: Value(carbs),
      snapshotFat: Value(fat),
      entryType: const Value('quickAdd'),
      quickAddLabel: Value(label),
    ));

    return IntakeEntity(
      id: id,
      unit: 'serving',
      amount: 1.0,
      type: IntakeTypeEntity.values.firstWhere(
          (e) => e.name == mealSlot,
          orElse: () => IntakeTypeEntity.snack),
      meal: MealEntity.empty(),
      dateTime: dateTime,
      entryType: 'quickAdd',
      quickAddLabel: label,
      snapshotKcal: kcal,
      snapshotProtein: protein,
      snapshotCarbs: carbs,
      snapshotFat: fat,
    );
  }

  Future<IntakeEntity> addRecipeIntake({
    required String id,
    required String recipeId,
    required String recipeName,
    required double multiplier,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
    required String mealSlot,
    required DateTime dateTime,
  }) async {
    _log.fine('Adding recipe intake: $id, recipe=$recipeId, multiplier=$multiplier');

    await _logEntryDao.insertEntry(LogEntriesCompanion(
      id: Value(id),
      timestamp: Value(dateTime.millisecondsSinceEpoch),
      mealSlot: Value(mealSlot),
      foodItemId: const Value(null),
      amount: Value(multiplier),
      unit: const Value('serving'),
      snapshotKcal: Value(kcal),
      snapshotProtein: Value(protein),
      snapshotCarbs: Value(carbs),
      snapshotFat: Value(fat),
      entryType: const Value('recipe'),
      quickAddLabel: Value(recipeName),
      recipeId: Value(recipeId),
    ));

    return IntakeEntity(
      id: id,
      unit: 'serving',
      amount: multiplier,
      type: IntakeTypeEntity.values.firstWhere(
          (e) => e.name == mealSlot,
          orElse: () => IntakeTypeEntity.snack),
      meal: MealEntity.empty(),
      dateTime: dateTime,
      entryType: 'recipe',
      quickAddLabel: recipeName,
      recipeId: recipeId,
      snapshotKcal: kcal,
      snapshotProtein: protein,
      snapshotCarbs: carbs,
      snapshotFat: fat,
    );
  }

  Future<void> addAllIntakeDBOs(List<IntakeDBO> intakeDBOs) async {
    for (final dbo in intakeDBOs) {
      final entity = IntakeEntity.fromIntakeDBO(dbo);
      await addIntake(entity);
    }
  }

  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    _log.fine('Deleting intake: ${intakeEntity.id}');
    await _logEntryDao.deleteById(intakeEntity.id);
  }

  Future<IntakeEntity?> updateIntake(
      String intakeId, Map<String, dynamic> fields) async {
    _log.fine('Updating intake: $intakeId');
    if (fields.containsKey('amount')) {
      final row = await _logEntryDao.getById(intakeId);
      if (row == null) return null;

      // Quick-add entries cannot be updated via amount change
      if (row.logEntry.entryType == 'quickAdd') return null;

      final newAmount = fields['amount'] as double;
      final foodItem = row.foodItem;
      final energyPerUnit = (foodItem?.kcalPer100 ?? 0) / 100;
      final proteinPerUnit = (foodItem?.proteinPer100 ?? 0) / 100;
      final carbsPerUnit = (foodItem?.carbsPer100 ?? 0) / 100;
      final fatPerUnit = (foodItem?.fatPer100 ?? 0) / 100;

      await _logEntryDao.updateEntry(intakeId, LogEntriesCompanion(
        amount: Value(newAmount),
        snapshotKcal: Value(newAmount * energyPerUnit),
        snapshotProtein: Value(newAmount * proteinPerUnit),
        snapshotCarbs: Value(newAmount * carbsPerUnit),
        snapshotFat: Value(newAmount * fatPerUnit),
      ));

      final updated = await _logEntryDao.getById(intakeId);
      return updated != null ? IntakeEntity.fromLogEntry(updated) : null;
    }
    return null;
  }

  Future<List<IntakeEntity>> getIntakeByDateAndType(
      IntakeTypeEntity intakeType, DateTime date) async {
    final rows =
        await _logEntryDao.getByDateAndSlot(date, intakeType.name);
    return rows.map((row) => IntakeEntity.fromLogEntry(row)).toList();
  }

  Future<List<IntakeEntity>> getRecentIntake() async {
    final rows = await _logEntryDao.getRecentlyAdded();
    return rows.map((row) => IntakeEntity.fromLogEntry(row)).toList();
  }

  Future<IntakeEntity?> getIntakeById(String intakeId) async {
    final row = await _logEntryDao.getById(intakeId);
    return row != null ? IntakeEntity.fromLogEntry(row) : null;
  }

  Future<void> toggleFavourite(String foodItemId, bool value) async {
    await _foodItemDao.toggleFavourite(foodItemId, value);
  }

  Future<List<MealEntity>> getFavouriteMeals() async {
    final rows = await _foodItemDao.getFavourites();
    return rows.map((row) => MealEntity.fromFoodItem(row)).toList();
  }

  // Export support: returns all log entries as IntakeDBO-compatible JSON
  Future<List<Map<String, dynamic>>> getAllIntakesJson() async {
    final rows = await _logEntryDao.getAll();
    return rows.map((row) {
      final entry = row.logEntry;
      final food = row.foodItem;
      return {
        'id': entry.id,
        'unit': entry.unit,
        'amount': entry.amount,
        'type': entry.mealSlot,
        'dateTime': DateTime.fromMillisecondsSinceEpoch(entry.timestamp)
            .toIso8601String(),
        'meal': {
          'code': food?.barcode ?? food?.id,
          'name': food?.name,
          'brands': food?.brand,
          'thumbnailImageUrl': food?.thumbnailImageUrl,
          'mainImageUrl': food?.mainImageUrl,
          'url': food?.url,
          'mealQuantity': food?.mealQuantity,
          'mealUnit': food?.mealUnit,
          'servingQuantity': food?.servingQuantity,
          'servingUnit': food?.servingUnit,
          'servingSize': food?.servingSize,
          'source': food?.source ?? 'unknown',
          'nutriments': {
            'energyKcal100': food?.kcalPer100,
            'carbohydrates100': food?.carbsPer100,
            'fat100': food?.fatPer100,
            'proteins100': food?.proteinPer100,
            'sugars100': food?.sugarPer100,
            'saturatedFat100': food?.saturatedFatPer100,
            'fiber100': food?.fibrePer100,
          },
        },
      };
    }).toList();
  }
}
