import 'dart:convert';

import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class LlmNutritionResult {
  final String? name;
  final String? brand;
  final double? servingSizeG;
  final double? caloriesPerServing;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;
  final double? servingQuantity;
  final String? servingUnit;
  final String confidence;
  final String? error;

  const LlmNutritionResult({
    this.name,
    this.brand,
    this.servingSizeG,
    this.caloriesPerServing,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
    this.servingQuantity,
    this.servingUnit,
    this.confidence = 'medium',
    this.error,
  });

  factory LlmNutritionResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return LlmNutritionResult(
        caloriesPer100g: 0,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        error: json['error'] as String?,
      );
    }

    return LlmNutritionResult(
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      servingSizeG: _toDouble(json['servingSizeG']),
      caloriesPerServing: _toDouble(json['caloriesPerServing']),
      caloriesPer100g: _toDouble(json['caloriesPer100g']) ?? 0,
      proteinPer100g: _toDouble(json['proteinPer100g']) ?? 0,
      carbsPer100g: _toDouble(json['carbsPer100g']) ?? 0,
      fatPer100g: _toDouble(json['fatPer100g']) ?? 0,
      fiberPer100g: _toDouble(json['fiberPer100g']),
      sugarPer100g: _toDouble(json['sugarPer100g']),
      saturatedFatPer100g: _toDouble(json['saturatedFatPer100g']),
      servingQuantity: _toDouble(json['servingQuantity']),
      servingUnit: json['servingUnit'] as String?,
      confidence: json['confidence'] as String? ?? 'medium',
    );
  }

  /// Parses raw LLM response text, stripping markdown code fences if present.
  static LlmNutritionResult parse(String rawText) {
    var text = rawText.trim();

    // Strip markdown code fences (```json ... ``` or ``` ... ```)
    final fencePattern = RegExp(r'^```(?:json)?\s*\n?', multiLine: true);
    if (fencePattern.hasMatch(text)) {
      text = text.replaceAll(RegExp(r'^```(?:json)?\s*\n?'), '');
      text = text.replaceAll(RegExp(r'\n?```\s*$'), '');
      text = text.trim();
    }

    final json = jsonDecode(text) as Map<String, dynamic>;
    return LlmNutritionResult.fromJson(json);
  }

  bool get hasError => error != null;

  MealEntity toMealEntity() {
    return MealEntity(
      code: IdGenerator.getUniqueID(),
      name: name,
      brands: brand,
      url: null,
      mealQuantity: servingSizeG?.toString(),
      mealUnit: 'g',
      servingQuantity: servingQuantity ?? servingSizeG,
      servingUnit: servingUnit ?? 'g',
      servingSize: servingSizeG != null ? '${servingSizeG!.round()}g' : null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: caloriesPer100g,
        carbohydrates100: carbsPer100g,
        fat100: fatPer100g,
        proteins100: proteinPer100g,
        sugars100: sugarPer100g,
        saturatedFat100: saturatedFatPer100g,
        fiber100: fiberPer100g,
      ),
      source: MealSourceEntity.llm,
    );
  }

  LlmNutritionResult copyWith({
    String? name,
    String? brand,
    double? servingSizeG,
    double? caloriesPerServing,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? sugarPer100g,
    double? saturatedFatPer100g,
    double? servingQuantity,
    String? servingUnit,
    String? confidence,
  }) {
    return LlmNutritionResult(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingSizeG: servingSizeG ?? this.servingSizeG,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarPer100g: sugarPer100g ?? this.sugarPer100g,
      saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      confidence: confidence ?? this.confidence,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
