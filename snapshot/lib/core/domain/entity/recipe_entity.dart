import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart' as drift;
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';

class RecipeEntity extends Equatable {
  final String id;
  final String name;
  final double servings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final bool favourite;
  final double kcalPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final List<RecipeIngredientEntity> ingredients;

  const RecipeEntity({
    required this.id,
    required this.name,
    this.servings = 1.0,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.favourite = false,
    this.kcalPerServing = 0,
    this.proteinPerServing = 0,
    this.carbsPerServing = 0,
    this.fatPerServing = 0,
    this.ingredients = const [],
  });

  factory RecipeEntity.fromDbRow(
      drift.Recipe row, List<RecipeIngredientEntity> ingredients) {
    return RecipeEntity(
      id: row.id,
      name: row.name,
      servings: row.servings,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      lastUsedAt: row.lastUsedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastUsedAt!)
          : null,
      favourite: row.favourite,
      kcalPerServing: row.kcalPerServing,
      proteinPerServing: row.proteinPerServing,
      carbsPerServing: row.carbsPerServing,
      fatPerServing: row.fatPerServing,
      ingredients: ingredients,
    );
  }

  RecipeEntity copyWith({
    String? id,
    String? name,
    double? servings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    bool? favourite,
    double? kcalPerServing,
    double? proteinPerServing,
    double? carbsPerServing,
    double? fatPerServing,
    List<RecipeIngredientEntity>? ingredients,
  }) {
    return RecipeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      servings: servings ?? this.servings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      favourite: favourite ?? this.favourite,
      kcalPerServing: kcalPerServing ?? this.kcalPerServing,
      proteinPerServing: proteinPerServing ?? this.proteinPerServing,
      carbsPerServing: carbsPerServing ?? this.carbsPerServing,
      fatPerServing: fatPerServing ?? this.fatPerServing,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  @override
  List<Object?> get props => [id, name, servings, favourite, kcalPerServing,
      proteinPerServing, carbsPerServing, fatPerServing, ingredients];
}
