/// A food on its way into the household list, before anybody has confirmed it.
///
/// The numbers may have come off a photograph or been typed in; either way they
/// are a draft until a person has looked at them. [trust] records which, and is
/// never guessed — a figure that came off a blurry panel and a figure somebody
/// read off the packet themselves are worth different amounts, and the list has
/// to keep saying which is which long after everybody has forgotten.
class FoodDraft {
  final String name;
  final String? brand;
  final String? barcode;
  final num? kcal100;
  final num? protein100;
  final num? fat100;
  final num? carbs100;
  final num? packGrams;
  final num? servingG;

  /// 'photo' when the numbers arrived from a photograph and were accepted as
  /// they came; 'typed' once a person has entered or corrected them.
  final String trust;

  /// Where it came from, kept apart from trust: a hand-corrected photo read is
  /// still a photo capture, and knowing that is what makes it possible to tell
  /// later how well the reading actually works.
  final String source;

  /// The fields the photographs could not give up, named so the confirmation
  /// screen can point at them rather than leaving somebody to spot the blanks.
  final List<String> unreadable;

  const FoodDraft({
    required this.name,
    this.brand,
    this.barcode,
    this.kcal100,
    this.protein100,
    this.fat100,
    this.carbs100,
    this.packGrams,
    this.servingG,
    this.trust = 'typed',
    this.source = 'typed',
    this.unreadable = const [],
  });

  /// A draft from what the photographs were read as. Nothing here is saved: it
  /// is what the confirmation screen opens with.
  factory FoodDraft.fromReading(Map<String, dynamic> reading,
          {List<String> unreadable = const []}) =>
      FoodDraft(
        name: (reading['name'] as String?) ?? '',
        brand: reading['brand'] as String?,
        barcode: reading['barcode'] as String?,
        kcal100: reading['kcal_100'] as num?,
        protein100: reading['protein_100'] as num?,
        fat100: reading['fat_100'] as num?,
        carbs100: reading['carbs_100'] as num?,
        packGrams: reading['pack_grams'] as num?,
        servingG: reading['serving_g'] as num?,
        trust: 'photo',
        source: 'photo',
        unreadable: unreadable,
      );

  /// The same food after a person has changed something. The trust drops to
  /// what a person typed, because that is now what it is — and the source stays
  /// as it was, because the photograph still happened.
  FoodDraft edited({
    String? name,
    String? brand,
    String? barcode,
    num? kcal100,
    num? protein100,
    num? fat100,
    num? carbs100,
    num? packGrams,
    num? servingG,
  }) =>
      FoodDraft(
        name: name ?? this.name,
        brand: brand ?? this.brand,
        barcode: barcode ?? this.barcode,
        kcal100: kcal100 ?? this.kcal100,
        protein100: protein100 ?? this.protein100,
        fat100: fat100 ?? this.fat100,
        carbs100: carbs100 ?? this.carbs100,
        packGrams: packGrams ?? this.packGrams,
        servingG: servingG ?? this.servingG,
        trust: 'typed',
        source: source,
        unreadable: unreadable,
      );

  /// Whether this is worth saving. A name is the floor: a food with no name is
  /// not findable and so is not in the list in any useful sense.
  bool get isSaveable => name.trim().isNotEmpty;

  /// True when the numbers are missing. Allowed — a named food with no numbers
  /// is still better than nothing, and the list says so — but worth surfacing.
  bool get hasNoNumbers => kcal100 == null;
}
