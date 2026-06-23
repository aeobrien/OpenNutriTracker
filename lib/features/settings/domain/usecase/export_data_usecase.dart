import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/recipe_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final FoodItemDao _foodItemDao;
  final RecipeDao _recipeDao;

  ExportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository, this._foodItemDao, this._recipeDao);

  /// Exports data to a zip of JSON files.
  Future<bool> exportData(
      String exportZipFileName,
      String userActivityJsonFileName,
      String userIntakeJsonFileName,
      String trackedDayJsonFileName) async {
    final archive = Archive();

    // Original 3 JSON files
    _addJsonFile(archive, userActivityJsonFileName,
        await _userActivityRepository.getAllUserActivityJson());
    _addJsonFile(archive, userIntakeJsonFileName,
        await _intakeRepository.getAllIntakesJson());
    _addJsonFile(archive, trackedDayJsonFileName,
        await _trackedDayRepository.getAllTrackedDaysJson());

    // Food items
    final foodItems = await _foodItemDao.getAll();
    final foodItemsJson = foodItems
        .map((fi) => {
              'id': fi.id,
              'source': fi.source,
              'barcode': fi.barcode,
              'name': fi.name,
              'brand': fi.brand,
              'mealQuantity': fi.mealQuantity,
              'mealUnit': fi.mealUnit,
              'servingQuantity': fi.servingQuantity,
              'servingUnit': fi.servingUnit,
              'servingSize': fi.servingSize,
              'kcalPer100': fi.kcalPer100,
              'proteinPer100': fi.proteinPer100,
              'carbsPer100': fi.carbsPer100,
              'fatPer100': fi.fatPer100,
              'fibrePer100': fi.fibrePer100,
              'sugarPer100': fi.sugarPer100,
              'saturatedFatPer100': fi.saturatedFatPer100,
              'thumbnailImageUrl': fi.thumbnailImageUrl,
              'mainImageUrl': fi.mainImageUrl,
              'url': fi.url,
              'lastUsedAt': fi.lastUsedAt,
              'lastUsedGrams': fi.lastUsedGrams,
              'favourite': fi.favourite,
            })
        .toList();
    _addJsonFile(archive, 'food_items.json', foodItemsJson);

    // Recipes with nested ingredients
    final recipes = await _recipeDao.getAll();
    final recipesJson = <Map<String, dynamic>>[];
    for (final r in recipes) {
      final ingredients = await _recipeDao.getIngredientsByRecipeId(r.id);
      recipesJson.add({
        'id': r.id,
        'name': r.name,
        'servings': r.servings,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
        'lastUsedAt': r.lastUsedAt,
        'favourite': r.favourite,
        'kcalPerServing': r.kcalPerServing,
        'proteinPerServing': r.proteinPerServing,
        'carbsPerServing': r.carbsPerServing,
        'fatPerServing': r.fatPerServing,
        'ingredients': ingredients
            .map((i) => {
                  'id': i.id,
                  'recipeId': i.recipeId,
                  'foodItemId': i.foodItemId,
                  'name': i.name,
                  'grams': i.grams,
                  'kcalPer100': i.kcalPer100,
                  'proteinPer100': i.proteinPer100,
                  'carbsPer100': i.carbsPer100,
                  'fatPer100': i.fatPer100,
                  'sortOrder': i.sortOrder,
                })
            .toList(),
      });
    }
    _addJsonFile(archive, 'recipes.json', recipesJson);

    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.platform.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }

  /// Exports data to a zip of CSV files.
  Future<bool> exportDataCsv(String exportZipFileName) async {
    final archive = Archive();

    // Food items CSV
    final foodItems = await _foodItemDao.getAll();
    final foodItemsCsv = StringBuffer();
    foodItemsCsv.writeln(
        'id,source,barcode,name,brand,mealQuantity,mealUnit,servingQuantity,servingUnit,servingSize,kcalPer100,proteinPer100,carbsPer100,fatPer100,fibrePer100,sugarPer100,saturatedFatPer100,lastUsedAt,lastUsedGrams,favourite');
    for (final fi in foodItems) {
      foodItemsCsv.writeln([
        _csvField(fi.id),
        _csvField(fi.source),
        _csvField(fi.barcode),
        _csvField(fi.name),
        _csvField(fi.brand),
        _csvField(fi.mealQuantity),
        _csvField(fi.mealUnit),
        fi.servingQuantity ?? '',
        _csvField(fi.servingUnit),
        _csvField(fi.servingSize),
        fi.kcalPer100 ?? '',
        fi.proteinPer100 ?? '',
        fi.carbsPer100 ?? '',
        fi.fatPer100 ?? '',
        fi.fibrePer100 ?? '',
        fi.sugarPer100 ?? '',
        fi.saturatedFatPer100 ?? '',
        fi.lastUsedAt ?? '',
        fi.lastUsedGrams ?? '',
        fi.favourite,
      ].join(','));
    }
    _addTextFile(archive, 'food_items.csv', foodItemsCsv.toString());

    // Log entries CSV
    final intakes = await _intakeRepository.getAllIntakesJson();
    final logCsv = StringBuffer();
    logCsv.writeln('id,unit,amount,type,dateTime,foodName');
    for (final entry in intakes) {
      final meal = entry['meal'] as Map<String, dynamic>?;
      logCsv.writeln([
        _csvField(entry['id']),
        _csvField(entry['unit']),
        entry['amount'] ?? '',
        _csvField(entry['type']),
        _csvField(entry['dateTime']),
        _csvField(meal?['name']),
      ].join(','));
    }
    _addTextFile(archive, 'log_entries.csv', logCsv.toString());

    // Daily stats CSV
    final trackedDays = await _trackedDayRepository.getAllTrackedDaysJson();
    final statsCsv = StringBuffer();
    statsCsv.writeln(
        'day,calorieGoal,caloriesTracked,carbsGoal,carbsTracked,fatGoal,fatTracked,proteinGoal,proteinTracked');
    for (final d in trackedDays) {
      statsCsv.writeln([
        _csvField(d['day']),
        d['calorieGoal'] ?? '',
        d['caloriesTracked'] ?? '',
        d['carbsGoal'] ?? '',
        d['carbsTracked'] ?? '',
        d['fatGoal'] ?? '',
        d['fatTracked'] ?? '',
        d['proteinGoal'] ?? '',
        d['proteinTracked'] ?? '',
      ].join(','));
    }
    _addTextFile(archive, 'daily_stats.csv', statsCsv.toString());

    // Recipes CSV
    final recipes = await _recipeDao.getAll();
    final recipesCsv = StringBuffer();
    recipesCsv.writeln(
        'id,name,servings,createdAt,updatedAt,lastUsedAt,favourite,kcalPerServing,proteinPerServing,carbsPerServing,fatPerServing');
    for (final r in recipes) {
      recipesCsv.writeln([
        _csvField(r.id),
        _csvField(r.name),
        r.servings,
        r.createdAt,
        r.updatedAt,
        r.lastUsedAt ?? '',
        r.favourite,
        r.kcalPerServing,
        r.proteinPerServing,
        r.carbsPerServing,
        r.fatPerServing,
      ].join(','));
    }
    _addTextFile(archive, 'recipes.csv', recipesCsv.toString());

    // Recipe ingredients CSV
    final ingredientsCsv = StringBuffer();
    ingredientsCsv.writeln(
        'id,recipeId,foodItemId,name,grams,kcalPer100,proteinPer100,carbsPer100,fatPer100,sortOrder');
    for (final r in recipes) {
      final ingredients = await _recipeDao.getIngredientsByRecipeId(r.id);
      for (final i in ingredients) {
        ingredientsCsv.writeln([
          _csvField(i.id),
          _csvField(i.recipeId),
          _csvField(i.foodItemId),
          _csvField(i.name),
          i.grams,
          i.kcalPer100,
          i.proteinPer100,
          i.carbsPer100,
          i.fatPer100,
          i.sortOrder,
        ].join(','));
      }
    }
    _addTextFile(
        archive, 'recipe_ingredients.csv', ingredientsCsv.toString());

    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.platform.saveFile(
      fileName: exportZipFileName.replaceAll('.zip', '-csv.zip'),
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }

  void _addJsonFile(Archive archive, String name, dynamic data) {
    final bytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  void _addTextFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  /// RFC 4180 CSV field quoting.
  String _csvField(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
