/// Mealie's per-recipe nutrition block.
///
/// Every field is a nullable string over the wire — Mealie stores nutrition as
/// strings (`coerce_numbers_to_str`). By Mealie convention the values are PER
/// SERVING (recipe scrapers fill them from schema.org NutritionInformation,
/// which is per-serving), but this is not enforced for manual entries — see
/// `MealieRecipeMapper` for the per-serving vs whole-recipe handling.
///
/// Field names match Mealie's camelCase API aliases exactly.
class MealieNutritionDto {
  final String? calories;
  final String? proteinContent;
  final String? carbohydrateContent;
  final String? fatContent;
  final String? fiberContent;
  final String? sugarContent;
  final String? sodiumContent;
  final String? saturatedFatContent;
  final String? transFatContent;
  final String? unsaturatedFatContent;
  final String? cholesterolContent;

  const MealieNutritionDto({
    this.calories,
    this.proteinContent,
    this.carbohydrateContent,
    this.fatContent,
    this.fiberContent,
    this.sugarContent,
    this.sodiumContent,
    this.saturatedFatContent,
    this.transFatContent,
    this.unsaturatedFatContent,
    this.cholesterolContent,
  });

  factory MealieNutritionDto.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) => v?.toString();
    return MealieNutritionDto(
      calories: str(json['calories']),
      proteinContent: str(json['proteinContent']),
      carbohydrateContent: str(json['carbohydrateContent']),
      fatContent: str(json['fatContent']),
      fiberContent: str(json['fiberContent']),
      sugarContent: str(json['sugarContent']),
      sodiumContent: str(json['sodiumContent']),
      saturatedFatContent: str(json['saturatedFatContent']),
      transFatContent: str(json['transFatContent']),
      unsaturatedFatContent: str(json['unsaturatedFatContent']),
      cholesterolContent: str(json['cholesterolContent']),
    );
  }
}
