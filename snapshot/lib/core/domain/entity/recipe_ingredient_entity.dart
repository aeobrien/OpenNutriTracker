import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart' as drift;
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart';

class RecipeIngredientEntity extends Equatable {
  final String id;
  final String recipeId;
  final String? foodItemId;
  final String name;
  final double grams;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;
  final int sortOrder;

  const RecipeIngredientEntity({
    required this.id,
    required this.recipeId,
    this.foodItemId,
    required this.name,
    required this.grams,
    this.kcalPer100 = 0,
    this.proteinPer100 = 0,
    this.carbsPer100 = 0,
    this.fatPer100 = 0,
    this.sortOrder = 0,
  });

  factory RecipeIngredientEntity.fromDbRow(drift.RecipeIngredient row) {
    return RecipeIngredientEntity(
      id: row.id,
      recipeId: row.recipeId,
      foodItemId: row.foodItemId,
      name: row.name,
      grams: row.grams,
      kcalPer100: row.kcalPer100,
      proteinPer100: row.proteinPer100,
      carbsPer100: row.carbsPer100,
      fatPer100: row.fatPer100,
      sortOrder: row.sortOrder,
    );
  }

  RecipeIngredient toRecipeIngredient() {
    return RecipeIngredient(
      kcalPer100g: kcalPer100,
      proteinPer100g: proteinPer100,
      carbsPer100g: carbsPer100,
      fatPer100g: fatPer100,
      grams: grams,
    );
  }

  RecipeIngredientEntity copyWith({
    String? id,
    String? recipeId,
    String? foodItemId,
    String? name,
    double? grams,
    double? kcalPer100,
    double? proteinPer100,
    double? carbsPer100,
    double? fatPer100,
    int? sortOrder,
  }) {
    return RecipeIngredientEntity(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcalPer100: kcalPer100 ?? this.kcalPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props =>
      [id, recipeId, foodItemId, name, grams, kcalPer100, proteinPer100, carbsPer100, fatPer100, sortOrder];
}
