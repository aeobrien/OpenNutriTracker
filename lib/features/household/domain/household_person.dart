/// The two people in the household, and one person's own settings.
///
/// There are exactly two of them and there is no notion of an account: the
/// server seeds them and the phone is told who they are. What the phone decides
/// is only *which one this handset belongs to*.
class HouseholdPerson {
  final int id;
  final String name;

  const HouseholdPerson({required this.id, required this.name});

  factory HouseholdPerson.fromJson(Map<String, dynamic> json) =>
      HouseholdPerson(id: json['id'] as int, name: json['name'] as String);

  @override
  bool operator ==(Object other) =>
      other is HouseholdPerson && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'HouseholdPerson($id, $name)';
}

/// One person's own preferences. Every field belongs to one person; there is
/// deliberately no household-wide fallback, because a fallback is how one
/// person's change ends up moving the other's.
class PersonSettings {
  final int personId;

  /// The daily calorie target. Null means they have not set one yet — which is
  /// different from zero and must stay different.
  final int? dailyTargetKcal;

  final bool weightTrackingOn;

  /// When true, no calorie figure is shown to this person anywhere. The ledger
  /// underneath carries on exactly as before.
  final bool figuresOff;

  const PersonSettings({
    required this.personId,
    this.dailyTargetKcal,
    this.weightTrackingOn = false,
    this.figuresOff = false,
  });

  factory PersonSettings.fromJson(Map<String, dynamic> json) => PersonSettings(
        personId: json['person_id'] as int,
        dailyTargetKcal: json['daily_target_kcal'] as int?,
        weightTrackingOn: (json['weight_tracking_on'] ?? 0) == 1,
        figuresOff: (json['figures_off'] ?? 0) == 1,
      );

  PersonSettings copyWith({
    int? dailyTargetKcal,
    bool? clearTarget,
    bool? weightTrackingOn,
    bool? figuresOff,
  }) =>
      PersonSettings(
        personId: personId,
        dailyTargetKcal:
            (clearTarget ?? false) ? null : (dailyTargetKcal ?? this.dailyTargetKcal),
        weightTrackingOn: weightTrackingOn ?? this.weightTrackingOn,
        figuresOff: figuresOff ?? this.figuresOff,
      );

  @override
  bool operator ==(Object other) =>
      other is PersonSettings &&
      other.personId == personId &&
      other.dailyTargetKcal == dailyTargetKcal &&
      other.weightTrackingOn == weightTrackingOn &&
      other.figuresOff == figuresOff;

  @override
  int get hashCode =>
      Object.hash(personId, dailyTargetKcal, weightTrackingOn, figuresOff);
}
