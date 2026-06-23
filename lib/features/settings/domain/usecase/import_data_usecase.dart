import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/recipe_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';

class ImportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final FoodItemDao _foodItemDao;
  final RecipeDao _recipeDao;

  final _log = Logger('ImportDataUsecase');

  ImportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository, this._foodItemDao, this._recipeDao);

  /// Imports user activity, intake, and tracked day data from a zip file
  /// containing JSON files. Also handles food_items.json and recipes.json
  /// if present (backward-compatible with older exports).
  Future<bool> importData(String userActivityJsonFileName,
      String userIntakeJsonFileName, String trackedDayJsonFileName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('No file selected');
    }

    final file = File(result.files.single.path!);
    final zipBytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Import user activity data
    final userActivityFile = archive.findFile(userActivityJsonFileName);
    if (userActivityFile != null) {
      final userActivityJsonString =
          utf8.decode(userActivityFile.content as List<int>);
      final userActivityList = (jsonDecode(userActivityJsonString) as List)
          .cast<Map<String, dynamic>>();

      final userActivityDBOs = userActivityList
          .map((json) => UserActivityDBO.fromJson(json))
          .toList();

      await _userActivityRepository.addAllUserActivityDBOs(userActivityDBOs);
    } else {
      throw Exception('User activity file not found in the archive');
    }

    // Import intake data
    final intakeFile = archive.findFile(userIntakeJsonFileName);
    if (intakeFile != null) {
      final intakeJsonString = utf8.decode(intakeFile.content as List<int>);
      final intakeList =
          (jsonDecode(intakeJsonString) as List).cast<Map<String, dynamic>>();

      final intakeDBOs =
          intakeList.map((json) => IntakeDBO.fromJson(json)).toList();

      await _intakeRepository.addAllIntakeDBOs(intakeDBOs);
    } else {
      throw Exception('Intake file not found in the archive');
    }

    // Import tracked day data
    final trackedDayFile = archive.findFile(trackedDayJsonFileName);
    if (trackedDayFile != null) {
      final trackedDayJsonString =
          utf8.decode(trackedDayFile.content as List<int>);
      final trackedDayList = (jsonDecode(trackedDayJsonString) as List)
          .cast<Map<String, dynamic>>();

      final trackedDayDBOs =
          trackedDayList.map((json) => TrackedDayDBO.fromJson(json)).toList();

      await _trackedDayRepository.addAllTrackedDays(trackedDayDBOs);
    } else {
      throw Exception('Tracked day file not found in the archive');
    }

    // Import food_items.json (optional, backward-compatible)
    final foodItemsFile = archive.findFile('food_items.json');
    if (foodItemsFile != null) {
      try {
        final jsonString = utf8.decode(foodItemsFile.content as List<int>);
        final list =
            (jsonDecode(jsonString) as List).cast<Map<String, dynamic>>();
        for (final fi in list) {
          await _foodItemDao.upsertFoodItem(FoodItemsCompanion(
            id: Value(fi['id'] as String),
            source: Value(fi['source'] as String? ?? 'unknown'),
            barcode: Value(fi['barcode'] as String?),
            name: Value(fi['name'] as String?),
            brand: Value(fi['brand'] as String?),
            mealQuantity: Value(fi['mealQuantity'] as String?),
            mealUnit: Value(fi['mealUnit'] as String?),
            servingQuantity:
                Value((fi['servingQuantity'] as num?)?.toDouble()),
            servingUnit: Value(fi['servingUnit'] as String?),
            servingSize: Value(fi['servingSize'] as String?),
            kcalPer100: Value((fi['kcalPer100'] as num?)?.toDouble()),
            proteinPer100:
                Value((fi['proteinPer100'] as num?)?.toDouble()),
            carbsPer100: Value((fi['carbsPer100'] as num?)?.toDouble()),
            fatPer100: Value((fi['fatPer100'] as num?)?.toDouble()),
            fibrePer100: Value((fi['fibrePer100'] as num?)?.toDouble()),
            sugarPer100: Value((fi['sugarPer100'] as num?)?.toDouble()),
            saturatedFatPer100:
                Value((fi['saturatedFatPer100'] as num?)?.toDouble()),
            thumbnailImageUrl:
                Value(fi['thumbnailImageUrl'] as String?),
            mainImageUrl: Value(fi['mainImageUrl'] as String?),
            url: Value(fi['url'] as String?),
            lastUsedAt: Value(fi['lastUsedAt'] as int?),
            lastUsedGrams:
                Value((fi['lastUsedGrams'] as num?)?.toDouble()),
            favourite: Value(fi['favourite'] as bool? ?? false),
          ));
        }
        _log.fine('Imported ${list.length} food items');
      } catch (e) {
        _log.warning('Failed to import food_items.json', e);
      }
    }

    // Import recipes.json (optional, backward-compatible)
    final recipesFile = archive.findFile('recipes.json');
    if (recipesFile != null) {
      try {
        final jsonString = utf8.decode(recipesFile.content as List<int>);
        final list =
            (jsonDecode(jsonString) as List).cast<Map<String, dynamic>>();
        for (final r in list) {
          await _recipeDao.insertRecipe(RecipesCompanion(
            id: Value(r['id'] as String),
            name: Value(r['name'] as String),
            servings: Value((r['servings'] as num).toDouble()),
            createdAt: Value(r['createdAt'] as int),
            updatedAt: Value(r['updatedAt'] as int),
            lastUsedAt: Value(r['lastUsedAt'] as int?),
            favourite: Value(r['favourite'] as bool? ?? false),
            kcalPerServing:
                Value((r['kcalPerServing'] as num?)?.toDouble() ?? 0),
            proteinPerServing:
                Value((r['proteinPerServing'] as num?)?.toDouble() ?? 0),
            carbsPerServing:
                Value((r['carbsPerServing'] as num?)?.toDouble() ?? 0),
            fatPerServing:
                Value((r['fatPerServing'] as num?)?.toDouble() ?? 0),
          ));

          final ingredients = (r['ingredients'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          for (final i in ingredients) {
            await _recipeDao.insertIngredient(RecipeIngredientsCompanion(
              id: Value(i['id'] as String),
              recipeId: Value(i['recipeId'] as String),
              foodItemId: Value(i['foodItemId'] as String?),
              name: Value(i['name'] as String),
              grams: Value((i['grams'] as num).toDouble()),
              kcalPer100:
                  Value((i['kcalPer100'] as num?)?.toDouble() ?? 0),
              proteinPer100:
                  Value((i['proteinPer100'] as num?)?.toDouble() ?? 0),
              carbsPer100:
                  Value((i['carbsPer100'] as num?)?.toDouble() ?? 0),
              fatPer100:
                  Value((i['fatPer100'] as num?)?.toDouble() ?? 0),
              sortOrder: Value(i['sortOrder'] as int? ?? 0),
            ));
          }
        }
        _log.fine('Imported ${list.length} recipes');
      } catch (e) {
        _log.warning('Failed to import recipes.json', e);
      }
    }

    return true;
  }
}
