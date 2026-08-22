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

  /// How many separate things are in a pack, when the pack says so — six fish
  /// cakes, twelve biscuits. Null for anything sold by weight alone, which is
  /// most food, and null is not a gap in the reading: it is what most packets
  /// are like.
  ///
  /// It is only useful beside [packGrams]. The two together are what let
  /// somebody add one of something later without knowing what one weighs.
  final int? perPack;

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
    this.perPack,
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
        perPack: reading['per_pack'] as int?,
        servingG: reading['serving_g'] as num?,
        trust: 'photo',
        source: 'photo',
        unreadable: unreadable,
      );

  /// A draft from what a hunt around the web turned up.
  ///
  /// The trust is `web` and it is set here rather than taken from the answer,
  /// because what a page said about itself is not evidence of anything. `web`
  /// sits below `photo` in the household's ordering on purpose: a photograph is
  /// of the packet in this kitchen, and a shop's listing is of a packet
  /// somewhere, once, possibly a different size.
  ///
  /// [source] carries the page it was read off rather than the word "web", so
  /// that months later the list can still say *which* page — that is the only
  /// thing that makes a wrong figure traceable.
  ///
  /// Anything the page did not state is left empty and named in [unreadable],
  /// so the confirmation screen points at the gap rather than leaving somebody
  /// to notice a blank box and wonder whether it means zero.
  factory FoodDraft.fromWebCandidate(Map<String, dynamic> candidate) {
    num? at(String key) => candidate[key] as num?;
    String? text(String key) {
      final value = candidate[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    const figures = [
      'kcal_100',
      'protein_100',
      'fat_100',
      'carbs_100',
      'serving_g',
    ];
    return FoodDraft(
      name: text('name') ?? '',
      brand: text('brand'),
      barcode: text('barcode'),
      kcal100: at('kcal_100'),
      protein100: at('protein_100'),
      fat100: at('fat_100'),
      carbs100: at('carbs_100'),
      packGrams: at('pack_grams'),
      perPack: at('per_pack')?.toInt(),
      servingG: at('serving_g'),
      trust: 'web',
      source: text('source') ?? 'web',
      unreadable: [for (final f in figures) if (candidate[f] == null) f],
    );
  }

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
    int? perPack,
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
        perPack: perPack ?? this.perPack,
        servingG: servingG ?? this.servingG,
        trust: 'typed',
        source: source,
        unreadable: unreadable,
      );

  /// Whether this is worth saving. A name is the floor: a food with no name is
  /// not findable and so is not in the list in any useful sense.
  bool get isSaveable => name.trim().isNotEmpty;

  /// What one of them weighs, when both numbers are there.
  ///
  /// Shown back on the confirmation screen rather than only stored, because a
  /// pack weight and a count are each easy to mistype and neither looks wrong
  /// on its own. 400g and 6 is a 67g fish cake; 400g and 60 is a 6.7g one, and
  /// only the third number says which of those somebody meant.
  double? get itemGrams =>
      (packGrams != null && perPack != null && perPack! > 0)
          ? packGrams!.toDouble() / perPack!
          : null;

  /// True when the numbers are missing. Allowed — a named food with no numbers
  /// is still better than nothing, and the list says so — but worth surfacing.
  bool get hasNoNumbers => kcal100 == null;
}
