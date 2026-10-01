import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/daily_stats.dart';

part 'daily_stats_dao.g.dart';

@DriftAccessor(tables: [DailyStats])
class DailyStatsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyStatsDaoMixin {
  DailyStatsDao(super.db);

  String _dateKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> upsert(DailyStatsCompanion entry) async {
    await into(dailyStats).insertOnConflictUpdate(entry);
  }

  Future<DailyStat?> getByDate(DateTime day) async {
    return (select(dailyStats)..where((t) => t.date.equals(_dateKey(day))))
        .getSingleOrNull();
  }

  Future<bool> hasDate(DateTime day) async {
    final row = await getByDate(day);
    return row != null;
  }

  Future<List<DailyStat>> getInRange(DateTime start, DateTime end) async {
    return (select(dailyStats)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(_dateKey(start)) &
              t.date.isSmallerOrEqualValue(_dateKey(end))))
        .get();
  }

  Future<List<DailyStat>> getAll() async {
    return select(dailyStats).get();
  }

  Future<void> addTrackedValues(
    DateTime day, {
    double? kcal,
    double? carbs,
    double? fat,
    double? protein,
  }) async {
    final dateKey = _dateKey(day);
    final updates = <String>[];
    final variables = <Variable>[];

    if (kcal != null) {
      updates.add('calories_tracked = calories_tracked + ?');
      variables.add(Variable.withReal(kcal));
    }
    if (carbs != null) {
      updates.add('carbs_tracked = COALESCE(carbs_tracked, 0) + ?');
      variables.add(Variable.withReal(carbs));
    }
    if (fat != null) {
      updates.add('fat_tracked = COALESCE(fat_tracked, 0) + ?');
      variables.add(Variable.withReal(fat));
    }
    if (protein != null) {
      updates.add('protein_tracked = COALESCE(protein_tracked, 0) + ?');
      variables.add(Variable.withReal(protein));
    }

    if (updates.isEmpty) return;

    variables.add(Variable.withString(dateKey));
    await customStatement(
      'UPDATE daily_stats SET ${updates.join(', ')} WHERE date = ?',
      variables.map((v) => v.value).toList(),
    );
  }

  Future<void> subtractTrackedValues(
    DateTime day, {
    double? kcal,
    double? carbs,
    double? fat,
    double? protein,
  }) async {
    final dateKey = _dateKey(day);
    final updates = <String>[];
    final variables = <Variable>[];

    if (kcal != null) {
      updates.add('calories_tracked = calories_tracked - ?');
      variables.add(Variable.withReal(kcal));
    }
    if (carbs != null) {
      updates.add('carbs_tracked = COALESCE(carbs_tracked, 0) - ?');
      variables.add(Variable.withReal(carbs));
    }
    if (fat != null) {
      updates.add('fat_tracked = COALESCE(fat_tracked, 0) - ?');
      variables.add(Variable.withReal(fat));
    }
    if (protein != null) {
      updates.add('protein_tracked = COALESCE(protein_tracked, 0) - ?');
      variables.add(Variable.withReal(protein));
    }

    if (updates.isEmpty) return;

    variables.add(Variable.withString(dateKey));
    await customStatement(
      'UPDATE daily_stats SET ${updates.join(', ')} WHERE date = ?',
      variables.map((v) => v.value).toList(),
    );
  }

  Future<void> updateGoals(
    DateTime day, {
    double? calorieGoal,
    double? carbsGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    final companion = DailyStatsCompanion(
      date: Value(_dateKey(day)),
      calorieGoal: calorieGoal != null ? Value(calorieGoal) : const Value.absent(),
      carbsGoal: carbsGoal != null ? Value(carbsGoal) : const Value.absent(),
      fatGoal: fatGoal != null ? Value(fatGoal) : const Value.absent(),
      proteinGoal:
          proteinGoal != null ? Value(proteinGoal) : const Value.absent(),
    );
    await (update(dailyStats)..where((t) => t.date.equals(_dateKey(day))))
        .write(companion);
  }

  Future<void> addToGoals(
    DateTime day, {
    double? calorieAmount,
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
    final dateKey = _dateKey(day);
    final updates = <String>[];
    final variables = <Variable>[];

    if (calorieAmount != null) {
      updates.add('calorie_goal = calorie_goal + ?');
      variables.add(Variable.withReal(calorieAmount));
    }
    if (carbsAmount != null) {
      updates.add('carbs_goal = COALESCE(carbs_goal, 0) + ?');
      variables.add(Variable.withReal(carbsAmount));
    }
    if (fatAmount != null) {
      updates.add('fat_goal = COALESCE(fat_goal, 0) + ?');
      variables.add(Variable.withReal(fatAmount));
    }
    if (proteinAmount != null) {
      updates.add('protein_goal = COALESCE(protein_goal, 0) + ?');
      variables.add(Variable.withReal(proteinAmount));
    }

    if (updates.isEmpty) return;

    variables.add(Variable.withString(dateKey));
    await customStatement(
      'UPDATE daily_stats SET ${updates.join(', ')} WHERE date = ?',
      variables.map((v) => v.value).toList(),
    );
  }

  Future<void> deleteByDate(DateTime day) async {
    await (delete(dailyStats)..where((t) => t.date.equals(_dateKey(day)))).go();
  }

  Future<void> updateActiveCalories(String date, double calories) async {
    final updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final affected = await customUpdate(
      'UPDATE daily_stats SET active_calories_burned = ?, active_calories_updated_at = ? WHERE date = ?',
      variables: [
        Variable.withReal(calories),
        Variable.withInt(updatedAt),
        Variable.withString(date),
      ],
      updates: {dailyStats},
    );
    // No tracked day exists yet (user hasn't logged anything today). Insert a
    // placeholder so the cached HealthKit value survives. calorieGoal is a
    // placeholder (0); addNewTrackedDay/updateGoals set the real goal
    // later via upsert without clobbering these active-calorie columns.
    if (affected == 0) {
      await into(dailyStats).insert(
        DailyStatsCompanion.insert(
          date: date,
          calorieGoal: 0,
          activeCaloriesBurned: Value(calories),
          activeCaloriesUpdatedAt:
              Value(DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000)),
        ),
      );
    }
  }

  Future<(double, DateTime?)> getActiveCalories(String date) async {
    final result = await customSelect(
      'SELECT active_calories_burned, active_calories_updated_at FROM daily_stats WHERE date = ?',
      variables: [Variable.withString(date)],
    ).getSingleOrNull();
    if (result == null) return (0.0, null);
    final calories = result.read<double>('active_calories_burned');
    final updatedAtEpoch = result.readNullable<int>('active_calories_updated_at');
    final updatedAt = updatedAtEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtEpoch * 1000)
        : null;
    return (calories, updatedAt);
  }

  Future<void> subtractFromGoals(
    DateTime day, {
    double? calorieAmount,
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
    final dateKey = _dateKey(day);
    final updates = <String>[];
    final variables = <Variable>[];

    if (calorieAmount != null) {
      updates.add('calorie_goal = calorie_goal - ?');
      variables.add(Variable.withReal(calorieAmount));
    }
    if (carbsAmount != null) {
      updates.add('carbs_goal = COALESCE(carbs_goal, 0) - ?');
      variables.add(Variable.withReal(carbsAmount));
    }
    if (fatAmount != null) {
      updates.add('fat_goal = COALESCE(fat_goal, 0) - ?');
      variables.add(Variable.withReal(fatAmount));
    }
    if (proteinAmount != null) {
      updates.add('protein_goal = COALESCE(protein_goal, 0) - ?');
      variables.add(Variable.withReal(proteinAmount));
    }

    if (updates.isEmpty) return;

    variables.add(Variable.withString(dateKey));
    await customStatement(
      'UPDATE daily_stats SET ${updates.join(', ')} WHERE date = ?',
      variables.map((v) => v.value).toList(),
    );
  }
}
