/// One pending intake as Mantel's `GET /intake/pending` returns it. Mantel is
/// the source of truth; FoodTracker mirrors these into the local food diary and
/// acks them back. The `id` is the idempotency key (a UUID) — it becomes the
/// local entry's `externalId`.
class MantelIntakeDto {
  /// Mantel's UUID for this intake. Idempotency key + local `externalId`.
  final String id;

  /// Tidy meal name shown in the diary, e.g. "Salmon & broccoli".
  final String label;

  /// The raw spoken/typed text. Kept, and shown to somebody correcting the
  /// row by hand: the label is the house's tidied-up name for it, and the only
  /// way to judge whether the house heard right is to see what was said.
  final String? description;

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// breakfast | lunch | dinner | snack — or null/empty when unspecified.
  final String? mealSlot;

  /// ISO-8601 UTC instant the meal was eaten.
  final String eatenAt;

  /// The actor's IANA zone (e.g. 'Europe/London'); informational.
  final String? tz;

  /// 'recipe' | 'estimate' — how Mantel resolved the nutrition.
  final String? source;

  /// 0–1 confidence in the nutrition estimate.
  final double? confidence;

  const MantelIntakeDto({
    required this.id,
    required this.label,
    required this.eatenAt,
    this.description,
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.mealSlot,
    this.tz,
    this.source,
    this.confidence,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory MantelIntakeDto.fromJson(Map<String, dynamic> json) {
    return MantelIntakeDto(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      description: json['description']?.toString(),
      kcal: _toDouble(json['kcal']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      mealSlot: json['meal_slot']?.toString(),
      eatenAt: (json['eaten_at'] ?? '').toString(),
      tz: json['tz']?.toString(),
      source: json['source']?.toString(),
      confidence:
          json['confidence'] == null ? null : _toDouble(json['confidence']),
    );
  }

  /// Maps Mantel's meal slot onto FoodTracker's intake-type name. Unknown or
  /// empty falls back to 'snack' (the diary requires a slot; the repository's
  /// own lookup also defaults there).
  String get foodTrackerMealSlot {
    switch ((mealSlot ?? '').trim().toLowerCase()) {
      case 'breakfast':
        return 'breakfast';
      case 'lunch':
        return 'lunch';
      case 'dinner':
        return 'dinner';
      case 'snack':
        return 'snack';
      default:
        return 'snack';
    }
  }

  /// The eaten-at instant as a *local* DateTime, so it lands on the correct
  /// local day/slot in the diary. Falls back to now if the timestamp is unusable.
  DateTime get eatenAtLocal {
    final parsed = DateTime.tryParse(eatenAt);
    if (parsed == null) return DateTime.now();
    return parsed.toLocal();
  }
}
