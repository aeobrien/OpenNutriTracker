import 'package:opennutritracker/features/household/domain/weight_record.dart';

/// What somebody has weighed, and which way it is going.
///
/// Two separate questions, kept separate on purpose. [latest] is what the
/// scales said; [trend] is the answer to "am I actually going down", and they
/// routinely disagree for days at a time. A body moves a kilo either way on
/// water and dinner and what time you stood on the scales, so somebody reading
/// yesterday's number against today's concludes the wrong thing about half the
/// time. The trend is the number worth putting in front of a person.
class WeightHistory {
  final List<WeightRecord> readings;
  final num? trend;

  /// How much the trend has moved in the last seven days, in kilograms.
  ///
  /// Null until there is a reading a week old to measure against. A figure
  /// invented from four days would be read as fact, and four days cannot tell
  /// a change from a large dinner.
  final num? aWeek;

  const WeightHistory({
    this.readings = const [],
    this.trend,
    this.aWeek,
  });

  bool get isEmpty => readings.isEmpty;
  WeightRecord? get latest => readings.isEmpty ? null : readings.last;

  /// The most recent day with a reading, or null. Used to decide how far back
  /// to ask Apple Health for — there is no point asking for what is already
  /// here.
  DateTime? get lastDay =>
      readings.isEmpty ? null : DateTime.parse(readings.last.day);

  factory WeightHistory.fromJson(Map<String, dynamic> json) => WeightHistory(
        readings: ((json['weights'] ?? json['readings']) as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(WeightRecord.fromJson)
            .toList(),
        trend: json['trend'] as num?,
        aWeek: json['a_week'] as num?,
      );
}
