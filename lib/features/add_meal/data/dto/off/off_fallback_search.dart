import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';

/// Reading the newer search service's answer as if it were the old one's.
///
/// The two services return different shapes for the same job. The old one
/// answers `{count, products: [...]}` with a brand as one string; the newer one
/// answers `{count, hits: [...]}` with a brand as a list of names. Everything
/// downstream of the search — the product object, the meal it becomes, the row
/// on the screen — already knows the old shape, and none of it should have to
/// learn a second one for a path it reaches one time in ten.
///
/// So the translation happens here, once, at the edge.
///
/// What genuinely is not there, rather than named differently: pack quantity,
/// serving quantity and serving size. The newer service does not carry them for
/// any product. That is why a fallback list says so on screen — a food with no
/// serving size is never offered "per serving", and that difference would
/// otherwise arrive silently.
class OFFFallbackSearch {
  /// The nutrition figures need no translation at all: this service writes
  /// `energy-kcal_100g`, `proteins_100g`, `carbohydrates_100g` and `fat_100g`,
  /// which are the four keys the app already reads.
  static OFFWordResponseDTO read(Map<String, dynamic> json) {
    final hits = (json['hits'] as List?) ?? const [];
    return OFFWordResponseDTO(
      count: json['count'],
      page: json['page'],
      page_count: null,
      page_size: json['page_size'] is int ? json['page_size'] as int : null,
      products: hits
          .whereType<Map<String, dynamic>>()
          .map((hit) => OFFProductDTO.fromJson(_asOldShape(hit)))
          .toList(),
    );
  }

  static Map<String, dynamic> _asOldShape(Map<String, dynamic> hit) => {
        'code': hit['code'],
        'product_name': hit['product_name'],
        'product_name_en': hit['product_name_en'],
        'brands': _oneBrand(hit['brands']),
        'image_front_thumb_url': hit['image_front_thumb_url'],
        'image_front_url': hit['image_front_url'],
        'image_url': hit['image_url'],
        'nutriments': hit['nutriments'] ?? const <String, dynamic>{},
      };

  /// A list of brand names where the rest of the app expects one string. Joined
  /// rather than truncated to the first: "Essential Waitrose" and "Waitrose"
  /// are both true of the same tin, and dropping one loses the half somebody
  /// searched by.
  static String? _oneBrand(dynamic brands) {
    if (brands == null) return null;
    if (brands is String) return brands.isEmpty ? null : brands;
    if (brands is List) {
      final names = brands.whereType<String>().where((b) => b.isNotEmpty);
      return names.isEmpty ? null : names.join(', ');
    }
    return null;
  }
}
