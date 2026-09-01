class OFFConst {
  static const offWebsiteUrl = "https://world.openfoodfacts.org/";
  static const _offBaseUrl = "world.openfoodfacts.org";
  static const _offSearchTag = "/cgi/search.pl";
  static const _offProductSearchTag = "/api/v2/product";

  static const offHttpSuccessCode = 200;
  static const offHttpDownCodes = [502, 503, 500];
  static const offProductNotFoundCode = 404;

  static const _offProductSearchTermsTag = "search_terms";
  static const _offFieldsTag = "fields";
  static const _offJsonTag = "json";
  static const _offJsonValue = "true";

  static const _offProductNameTag = "product_name";
  static const _offProductNameENTag = "product_name_en";
  static const _offProductNameDETag = "product_name_de";
  static const _offProductNameFRTag = "product_name_fr";
  static const _offCodeTag = "code";
  static const _offBrandsTag = "brands";

  static const _offUrlTag = "url";
  static const _offImageUrlTag = "image_url";
  static const _offImageThumbUrlTag = "image_front_thumb_url";
  static const _offImageFrontUrlTag = "image_front_url";
  // static const _offImageNutritionUrlTag = "image_nutrition_url";
  // static const _offImageIngredientsUrlTag = "image_ingredients_url";

  static const _offProductQuantityTag = "product_quantity";
  static const _offQuantityTag = "quantity";
  static const _offServingQuantityTag = "serving_quantity";
  static const _offServingSizeTag = "serving_size";
  static const _offNutrimentsTag = "nutriments";

  static const _returnFields = [
    _offCodeTag,
    _offBrandsTag,
    _offProductNameTag,
    _offProductNameENTag,
    _offProductNameDETag,
    _offProductNameFRTag,
    _offUrlTag,
    _offImageUrlTag,
    _offImageThumbUrlTag,
    _offImageFrontUrlTag,
    _offProductQuantityTag,
    _offQuantityTag,
    _offServingQuantityTag,
    _offServingSizeTag,
    _offNutrimentsTag
  ];

  static String _getReturnFields() => _returnFields.join(",");

  /// The newer search service, used only when the old one has refused every
  /// ask.
  ///
  /// A separate host running different software, which is why it is worth
  /// asking when the other will not answer: measured 1 September 2026, twenty
  /// requests at human pace in the same window, the old address answered 7 and
  /// this one 20. It is not better, only reachable — its answers carry fewer
  /// calorie figures and rank worse — so nothing asks it first.
  static const _offFallbackBaseUrl = "search.openfoodfacts.org";
  static const _offFallbackSearchTag = "/search";
  static const _offFallbackQueryTag = "q";
  static const _offFallbackPageSizeTag = "page_size";

  /// Fifty, to match what the old service hands back unasked. A shorter list
  /// from the fallback would read as the app finding less rather than the
  /// source being different.
  static const _offFallbackPageSize = "50";

  static Uri getOffFallbackSearchUrl(String searchString) => Uri.https(
        _offFallbackBaseUrl,
        _offFallbackSearchTag,
        {
          _offFallbackQueryTag: searchString,
          _offFallbackPageSizeTag: _offFallbackPageSize,
        },
      );

  static Uri getOffWordSearchUrl(String searchString) {
    final queryParameters = {
      _offProductSearchTermsTag: searchString,
      _offFieldsTag: _getReturnFields(),
      _offJsonTag: _offJsonValue,
    };

    return Uri.https(_offBaseUrl, _offSearchTag, queryParameters);
  }

  static Uri getOffBarcodeSearchUri(String barcode) {
    final queryParameters = {
      _offFieldsTag: _getReturnFields(),
      _offJsonTag: _offJsonValue
    };

    return Uri.https(
        _offBaseUrl, '$_offProductSearchTag/$barcode', queryParameters);
  }
}
