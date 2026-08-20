/// One weigh-in, as the household server keeps it.
///
/// Deliberately its own small thing rather than a field on the person: weights
/// are a history, and the weight-tracking switch decides whether that history is
/// shown, never whether it is kept.
class WeightRecord {
  final String day;
  final num kg;

  /// Where the number came from: `typed` if somebody stood on the scales and
  /// put it in, `health` if it was brought in from Apple Health. Kept on the
  /// record because a day can have both and only one of them is the reading —
  /// and when the two disagree, "where did this come from" is the first thing
  /// anybody asks.
  final String source;

  /// The trend on this day: a line that lags the readings, so a heavy morning
  /// barely moves it. Worked out by the server so the phone and the kitchen
  /// panel cannot arrive at two different answers about the same body.
  final num? trend;

  const WeightRecord({
    required this.day,
    required this.kg,
    this.source = 'typed',
    this.trend,
  });

  bool get typed => source == 'typed';

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        day: json['day'] as String,
        kg: json['kg'] as num,
        source: json['source'] as String? ?? 'typed',
        trend: json['trend'] as num?,
      );

  @override
  bool operator ==(Object other) =>
      other is WeightRecord &&
      other.day == day &&
      other.kg == kg &&
      other.source == source &&
      other.trend == trend;

  @override
  int get hashCode => Object.hash(day, kg, source, trend);

  @override
  String toString() => 'WeightRecord($day, $kg, $source, trend $trend)';
}
