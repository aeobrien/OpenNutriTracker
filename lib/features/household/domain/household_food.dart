/// A food as the household's own list holds it.
library;

/// One packet the house knows about.
///
/// This is the list the app reaches for before it goes anywhere near the
/// internet, and it is the only list where the numbers are ones this household
/// actually checked. [trust] says how they were come by — read off the packet,
/// off a photograph, off a barcode lookup, or guessed — and it travels with
/// the food rather than being re-decided by whoever shows it.
class HouseholdFood {
  final int id;
  final String name;
  final String? brand;
  final String? barcode;

  /// Per 100g or 100ml. Null is "nobody has told us", never zero.
  final num? kcal100;
  final num? protein100;
  final num? fat100;
  final num? carbs100;

  /// What the whole pack weighs, and what the pack calls one serving, when
  /// either is known.
  final num? packGrams;
  final num? servingG;
  final int? perPack;

  final String trust;
  final String source;

  const HouseholdFood({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    this.kcal100,
    this.protein100,
    this.fat100,
    this.carbs100,
    this.packGrams,
    this.servingG,
    this.perPack,
    this.trust = 'estimated',
    this.source = 'typed',
  });

  factory HouseholdFood.fromJson(Map<String, dynamic> json) => HouseholdFood(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        barcode: json['barcode'] as String?,
        kcal100: json['kcal_100'] as num?,
        protein100: json['protein_100'] as num?,
        fat100: json['fat_100'] as num?,
        carbs100: json['carbs_100'] as num?,
        packGrams: json['pack_grams'] as num?,
        servingG: json['serving_g'] as num?,
        perPack: json['per_pack'] as int?,
        trust: (json['trust'] as String?) ?? 'estimated',
        source: (json['source'] as String?) ?? 'typed',
      );

  /// How a household food is named among the app's own foods.
  ///
  /// The app identifies every food by a single string — a barcode for a
  /// supermarket product, an id for one typed in — and household foods need
  /// one too. It is built from the household's id rather than the barcode
  /// because plenty of things the house eats have no barcode at all, and a
  /// food that cannot be told apart from another is a food that gets logged as
  /// the wrong one.
  ///
  /// It is also how the ledger learns which food an entry was: [idFromCode]
  /// reads it back at the moment of logging, which is what makes "your own
  /// foods first" possible at all.
  static String codeFor(int id) => 'mantel:$id';

  /// The household food id inside an app food's code, or null if this food did
  /// not come from the household list.
  static int? idFromCode(String? code) {
    if (code == null || !code.startsWith('mantel:')) return null;
    return int.tryParse(code.substring('mantel:'.length));
  }

  String get code => codeFor(id);

  /// Whether this food is one the person meant when they typed [text].
  ///
  /// The kitchen computer does this match itself and is the authority on it.
  /// This is a second, identical check made on the phone, and it exists for one
  /// specific reason: an older kitchen computer does not understand being asked
  /// for a *search* and answers with the entire list. Without this the person
  /// types "banana", gets last week's curry back, and reasonably concludes the
  /// search is broken. Filtering here means the worst an out-of-date kitchen
  /// computer can do is show fewer of our own foods than it should — never the
  /// wrong ones.
  bool matches(String text) {
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        (brand ?? '').toLowerCase().contains(needle);
  }

  @override
  bool operator ==(Object other) => other is HouseholdFood && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HouseholdFood($id, $name)';
}
