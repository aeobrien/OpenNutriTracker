class NutritionValues {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionValues({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionValues &&
          kcal == other.kcal &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat;

  @override
  int get hashCode =>
      kcal.hashCode ^ protein.hashCode ^ carbs.hashCode ^ fat.hashCode;

  @override
  String toString() =>
      'NutritionValues(kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat)';
}

class RecipeIngredient {
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double grams;

  const RecipeIngredient({
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.grams,
  });
}

class RecipeCalc {
  /// Sums nutrition across all ingredients, scaling from per-100g values.
  static NutritionValues calculateTotal(List<RecipeIngredient> ingredients) {
    double kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final ing in ingredients) {
      final factor = ing.grams / 100;
      kcal += ing.kcalPer100g * factor;
      protein += ing.proteinPer100g * factor;
      carbs += ing.carbsPer100g * factor;
      fat += ing.fatPer100g * factor;
    }

    return NutritionValues(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Calculates nutrition per serving by dividing totals by [servings].
  static NutritionValues calculatePerServing(
      List<RecipeIngredient> ingredients, double servings) {
    final total = calculateTotal(ingredients);
    if (servings <= 0) return total;

    return NutritionValues(
      kcal: total.kcal / servings,
      protein: total.protein / servings,
      carbs: total.carbs / servings,
      fat: total.fat / servings,
    );
  }
}
