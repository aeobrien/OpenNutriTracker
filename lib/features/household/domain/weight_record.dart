/// One weigh-in, as the household server keeps it.
///
/// Deliberately its own small thing rather than a field on the person: weights
/// are a history, and the weight-tracking switch decides whether that history is
/// shown, never whether it is kept.
class WeightRecord {
  final String day;
  final num kg;

  const WeightRecord({required this.day, required this.kg});

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        day: json['day'] as String,
        kg: json['kg'] as num,
      );

  @override
  bool operator ==(Object other) =>
      other is WeightRecord && other.day == day && other.kg == kg;

  @override
  int get hashCode => Object.hash(day, kg);

  @override
  String toString() => 'WeightRecord($day, $kg)';
}
