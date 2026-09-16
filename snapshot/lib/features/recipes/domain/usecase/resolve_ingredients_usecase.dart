import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/recipes/data/dto/llm_recipe_result.dart';

enum MatchStatus { matched, suggested, unresolved }

class ResolvedIngredient {
  final String name;
  final String originalText;
  final double grams;
  final String confidence;
  final MatchStatus matchStatus;
  final String? foodItemId;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  ResolvedIngredient({
    required this.name,
    required this.originalText,
    required this.grams,
    required this.confidence,
    required this.matchStatus,
    this.foodItemId,
    this.kcalPer100 = 0,
    this.proteinPer100 = 0,
    this.carbsPer100 = 0,
    this.fatPer100 = 0,
  });

  ResolvedIngredient copyWith({
    String? name,
    String? originalText,
    double? grams,
    String? confidence,
    MatchStatus? matchStatus,
    String? foodItemId,
    double? kcalPer100,
    double? proteinPer100,
    double? carbsPer100,
    double? fatPer100,
  }) {
    return ResolvedIngredient(
      name: name ?? this.name,
      originalText: originalText ?? this.originalText,
      grams: grams ?? this.grams,
      confidence: confidence ?? this.confidence,
      matchStatus: matchStatus ?? this.matchStatus,
      foodItemId: foodItemId ?? this.foodItemId,
      kcalPer100: kcalPer100 ?? this.kcalPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
    );
  }
}

class ResolveIngredientsUsecase {
  final FoodItemDao _foodItemDao;
  final OFFDataSource _offDataSource;
  final _log = Logger('ResolveIngredientsUsecase');

  ResolveIngredientsUsecase(this._foodItemDao, this._offDataSource);

  Future<List<ResolvedIngredient>> execute(
      List<LlmIngredientResult> llmIngredients) async {
    final results = <ResolvedIngredient>[];

    for (final llmIng in llmIngredients) {
      try {
        // Search local food items via FTS5
        final searchQuery = '${llmIng.name.trim()}*';
        final matches = await _foodItemDao.searchByName(searchQuery);

        if (matches.isNotEmpty) {
          final best = matches.first;
          results.add(ResolvedIngredient(
            name: best.name ?? llmIng.name,
            originalText: llmIng.originalText,
            grams: llmIng.grams,
            confidence: llmIng.confidence,
            matchStatus: MatchStatus.matched,
            foodItemId: best.id,
            kcalPer100: best.kcalPer100 ?? 0,
            proteinPer100: best.proteinPer100 ?? 0,
            carbsPer100: best.carbsPer100 ?? 0,
            fatPer100: best.fatPer100 ?? 0,
          ));
        } else {
          // No local match — try OFF API
          final offResult = await _searchOff(llmIng.name.trim());
          if (offResult != null) {
            results.add(offResult.copyWith(
              originalText: llmIng.originalText,
              grams: llmIng.grams,
              confidence: llmIng.confidence,
            ));
          } else {
            results.add(ResolvedIngredient(
              name: llmIng.name,
              originalText: llmIng.originalText,
              grams: llmIng.grams,
              confidence: llmIng.confidence,
              matchStatus: MatchStatus.unresolved,
            ));
          }
        }
      } catch (e, st) {
        _log.warning('Failed to resolve ingredient: ${llmIng.name}', e, st);
        results.add(ResolvedIngredient(
          name: llmIng.name,
          originalText: llmIng.originalText,
          grams: llmIng.grams,
          confidence: llmIng.confidence,
          matchStatus: MatchStatus.unresolved,
        ));
      }
    }

    return results;
  }

  Future<ResolvedIngredient?> _searchOff(String query) async {
    try {
      final response = await _offDataSource.fetchSearchWordResults(query);
      final products = response.products;
      if (products.isEmpty) return null;

      final product = products.first;
      return ResolvedIngredient(
        name: product.product_name ?? query,
        originalText: '',
        grams: 0,
        confidence: 'medium',
        matchStatus: MatchStatus.suggested,
        kcalPer100: _toDouble(product.nutriments.energy_kcal_100g),
        proteinPer100: _toDouble(product.nutriments.proteins_100g),
        carbsPer100: _toDouble(product.nutriments.carbohydrates_100g),
        fatPer100: _toDouble(product.nutriments.fat_100g),
      );
    } catch (e) {
      _log.fine('OFF search failed for "$query": $e');
      return null;
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
