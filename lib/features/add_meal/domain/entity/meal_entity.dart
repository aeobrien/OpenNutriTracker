import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart' as drift;
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';

class MealEntity extends Equatable {
  static const liquidUnits = {'ml', 'l', 'dl', 'cl', 'fl oz', 'fl.oz'};
  static const solidUnits = {
    'kg',
    'g',
    'mg',
    'µg',
    'oz',
  };

  final String? code;
  final String? name;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final String? url;

  final String? mealQuantity;
  final String? mealUnit;
  final double? servingQuantity;
  final String? servingUnit;
  final String? servingSize;

  get hasServingValues => servingQuantity != null && servingUnit != null;

  /// What one whole pack of this weighs, when the house has recorded it.
  final double? packGrams;

  /// How many of the thing are in a pack, when the thing is countable — six
  /// hobnobs, four pies. Null for anything sold by weight alone.
  final int? perPack;

  /// What one of them weighs. Worked out rather than stored: a pack weight, a
  /// count and a separately stored item weight are three numbers that can
  /// disagree, where two cannot.
  double? get itemGrams =>
      (packGrams != null && perPack != null && perPack! > 0)
          ? packGrams! / perPack!
          : null;

  bool get hasPackValues => packGrams != null && packGrams! > 0;

  bool get hasItemValues => itemGrams != null && itemGrams! > 0;

  final double? lastUsedGrams;
  final bool favourite;

  final MealSourceEntity source;

  final MealNutrimentsEntity nutriments;

  bool get isLiquid => liquidUnits.contains(mealUnit);

  bool get isSolid => solidUnits.contains(mealUnit);

  const MealEntity(
      {required this.code,
      required this.name,
      this.brands,
      this.thumbnailImageUrl,
      this.mainImageUrl,
      required this.url,
      required this.mealQuantity,
      required this.mealUnit,
      required this.servingQuantity,
      required this.servingUnit,
      required this.servingSize,
      required this.nutriments,
      required this.source,
      this.packGrams,
      this.perPack,
      this.lastUsedGrams,
      this.favourite = false});

  factory MealEntity.empty() => MealEntity(
      code: IdGenerator.getUniqueID(),
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'gml',
      servingQuantity: null,
      servingUnit: 'gml',
      servingSize: '',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom,
      lastUsedGrams: null,
      favourite: false);

  factory MealEntity.fromFoodItem(drift.FoodItem row) => MealEntity(
      code: row.barcode ?? row.id,
      name: row.name,
      brands: row.brand,
      thumbnailImageUrl: row.thumbnailImageUrl,
      mainImageUrl: row.mainImageUrl,
      url: row.url,
      mealQuantity: row.mealQuantity,
      mealUnit: row.mealUnit,
      servingQuantity: row.servingQuantity,
      servingUnit: row.servingUnit,
      servingSize: row.servingSize,
      nutriments: MealNutrimentsEntity.fromFoodItem(row),
      source: MealSourceEntity.values.firstWhere(
          (e) => e.name == row.source,
          orElse: () => MealSourceEntity.unknown),
      lastUsedGrams: row.lastUsedGrams,
      favourite: row.favourite);

  factory MealEntity.fromMealDBO(MealDBO mealDBO) => MealEntity(
      code: mealDBO.code,
      name: mealDBO.name,
      brands: mealDBO.brands,
      thumbnailImageUrl: mealDBO.thumbnailImageUrl,
      mainImageUrl: mealDBO.mainImageUrl,
      url: mealDBO.url,
      mealQuantity: mealDBO.mealQuantity,
      mealUnit: mealDBO.mealUnit,
      servingQuantity: mealDBO.servingQuantity,
      servingUnit: mealDBO.servingUnit,
      servingSize: mealDBO.servingSize,
      nutriments:
          MealNutrimentsEntity.fromMealNutrimentsDBO(mealDBO.nutriments),
      source: MealSourceEntity.fromMealSourceDBO(mealDBO.source));

  /// A food out of the household's own list, as the rest of the app sees any
  /// other food.
  ///
  /// Mapped rather than kept apart on purpose: the picker rows, the portion
  /// sheet and the adding all already work, and a household food that took a
  /// different path through them would be a second version of the screen that
  /// already exists — which is the mistake this whole project is undoing.
  ///
  /// The unit is grams because the household list does not record whether a
  /// food is a solid or a liquid. That is a real gap and it is left visible
  /// here rather than guessed at from the name.
  factory MealEntity.fromHouseholdFood(HouseholdFood food) => MealEntity(
        code: food.code,
        name: food.name,
        brands: food.brand,
        url: null,
        mealQuantity: food.packGrams?.toString(),
        mealUnit: 'g',
        servingQuantity: food.servingG?.toDouble(),
        servingUnit: food.servingG == null ? null : 'g',
        servingSize: null,
        // Carried through so the amount sheet can offer a whole pack or one of
        // them. The house records both; until now they stopped here and a
        // person picking a pie had to know what a pie weighs.
        packGrams: food.packGrams?.toDouble(),
        perPack: food.perPack,
        nutriments: MealNutrimentsEntity(
          energyKcal100: food.kcal100?.toDouble(),
          carbohydrates100: food.carbs100?.toDouble(),
          fat100: food.fat100?.toDouble(),
          proteins100: food.protein100?.toDouble(),
          sugars100: null,
          saturatedFat100: null,
          fiber100: null,
        ),
        source: MealSourceEntity.custom,
      );

  factory MealEntity.fromOFFProduct(OFFProductDTO offProduct) {
    return MealEntity(
        code: offProduct.code,
        name: offProduct
            .getLocaleName(SupportedLanguage.fromCode(Platform.localeName)),
        brands: offProduct.brands,
        thumbnailImageUrl: offProduct.image_front_thumb_url,
        mainImageUrl: offProduct.image_front_url,
        url: offProduct.url,
        mealQuantity: offProduct.product_quantity?.toString(),
        mealUnit: _tryGetUnit(offProduct.quantity),
        servingQuantity: _tryQuantityCast(offProduct.serving_quantity),
        servingUnit: _tryGetUnit(offProduct.quantity),
        servingSize: offProduct.serving_size,
        nutriments:
            MealNutrimentsEntity.fromOffNutriments(offProduct.nutriments),
        source: MealSourceEntity.off);
  }

  factory MealEntity.fromFDCFood(FDCFoodDTO fdcFood) {
    final fdcId = fdcFood.fdcId?.toInt().toString();

    return MealEntity(
        code: fdcId,
        name: fdcFood.description,
        brands: fdcFood.brandName,
        url: FDCConst.getFoodDetailUrlString(fdcId),
        mealQuantity: fdcFood.packageWeight,
        mealUnit: fdcFood.servingSizeUnit,
        servingQuantity: fdcFood.servingSize,
        servingUnit: fdcFood.servingSizeUnit,
        servingSize: fdcFood.servingSizeUnit,
        nutriments:
            MealNutrimentsEntity.fromFDCNutriments(fdcFood.foodNutrients),
        source: MealSourceEntity.fdc);
  }

  /// Value returned from OFF can either be String, int or double.
  /// Try casting it to a double value for calculation
  static double? _tryQuantityCast(dynamic value) {
    double? parsedValue;

    if (value == null) {
      parsedValue = null;
    } else if (value is double) {
      parsedValue = value;
    } else if (value is int) {
      parsedValue = value.toDouble();
    } else if (value is String) {
      value.replaceAll(RegExp("mg|g|kg|ml|cl|l| "), ""); // TODO extract
      final doubleParsed =
          double.tryParse(value) ?? int.tryParse(value)?.toDouble();
      parsedValue = doubleParsed;
    }
    return parsedValue;
  }

  /// TODO extract correct unit
  /// Unit can either be 100g or 100ml
  static String? _tryGetUnit(String? quantityString) {
    if (quantityString == null) return null;

    final isLiter = quantityString.toUpperCase().contains("L");

    if (isLiter) {
      return "ml";
    } else {
      return "g";
    }
  }

  /// The same food, now carrying what this phone last had of it.
  ///
  /// The two facts arrive from different places and only meet here. A pack
  /// weight and a count come off the household's list, which knows what the
  /// house buys; how much somebody last ate of it is in this phone's own log,
  /// which the house never sees. Before this, a food with a count could never
  /// carry a last amount, so the one order Aidan settled — his portion, then
  /// last time, then the pack — could never reach its second step for exactly
  /// the foods that count in items.
  MealEntity rememberingLastAmount(double? grams) => MealEntity(
      code: code,
      name: name,
      brands: brands,
      thumbnailImageUrl: thumbnailImageUrl,
      mainImageUrl: mainImageUrl,
      url: url,
      mealQuantity: mealQuantity,
      mealUnit: mealUnit,
      servingQuantity: servingQuantity,
      servingUnit: servingUnit,
      servingSize: servingSize,
      nutriments: nutriments,
      source: source,
      packGrams: packGrams,
      perPack: perPack,
      lastUsedGrams: grams,
      favourite: favourite);

  /// Returns a copy with the favourite flag toggled.
  MealEntity copyWithFavourite(bool value) => MealEntity(
      code: code,
      name: name,
      brands: brands,
      thumbnailImageUrl: thumbnailImageUrl,
      mainImageUrl: mainImageUrl,
      url: url,
      mealQuantity: mealQuantity,
      mealUnit: mealUnit,
      servingQuantity: servingQuantity,
      servingUnit: servingUnit,
      servingSize: servingSize,
      nutriments: nutriments,
      source: source,
      packGrams: packGrams,
      perPack: perPack,
      lastUsedGrams: lastUsedGrams,
      favourite: value);

  @override
  List<Object?> get props => [code, name];
}

enum MealSourceEntity {
  unknown,
  custom,
  off,
  fdc,
  llm;

  factory MealSourceEntity.fromMealSourceDBO(MealSourceDBO mealSourceDBO) {
    MealSourceEntity mealSourceEntity;
    switch (mealSourceDBO) {
      case MealSourceDBO.unknown:
        mealSourceEntity = MealSourceEntity.unknown;
        break;
      case MealSourceDBO.custom:
        mealSourceEntity = MealSourceEntity.custom;
        break;
      case MealSourceDBO.off:
        mealSourceEntity = MealSourceEntity.off;
        break;
      case MealSourceDBO.fdc:
        mealSourceEntity = MealSourceEntity.fdc;
        break;
      case MealSourceDBO.llm:
        mealSourceEntity = MealSourceEntity.llm;
        break;
    }
    return mealSourceEntity;
  }
}
