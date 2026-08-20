import 'package:opennutritracker/features/weight/domain/weight_history.dart';

/// The one line of weight trend that sits under the weight on Profile.
///
/// Pulled out of the page so the wording can be tested without building a
/// screen, because the wording is the whole feature. A trend is only useful if
/// the sentence a person reads is the sentence they would have said
/// themselves: "down about 0.4 kg a week" is an answer, "trend: 82.31" is a
/// number they have to interpret and will interpret wrongly.
class TrendLine {
  /// Below this a week's movement is noise, not a direction. A hundred grams a
  /// week is smaller than the difference a large dinner makes to the scales,
  /// and calling it "going down" would have somebody believe a fortnight of
  /// nothing was progress.
  static const steadyWithin = 0.1;

  /// Pounds in a kilogram.
  ///
  /// Converted here rather than through the app's usual unit helper, which
  /// rounds to whole pounds. That is sensible for a body weight and wrong for
  /// a week's movement: four hundred grams a week is nine tenths of a pound
  /// and rounds to one, and two hundred grams rounds to *nought* — so a person
  /// steadily losing weight would read "down 0.0 lbs a week" and conclude
  /// nothing was happening. The rounding that keeps a weight tidy destroys the
  /// number this line exists to show.
  static const perKg = 2.20462;

  static const steady = 'Holding steady';
  static const notEnoughYet = 'Not enough weigh-ins yet to say which way.';

  /// Null when there is nothing to say. The line is left off entirely rather
  /// than showing an empty one — and, since 20 August 2026, rather than showing
  /// a bare smoothed figure.
  ///
  /// The rule this file already stated at the top and then broke: a trend is a
  /// *direction*, not a number. It used to open every line with "Trending 82.4
  /// kg", including in the case where the very next clause admitted it could
  /// not yet say which way anything was going. Aidan read that under a weight
  /// of 115 kg and asked, exactly reasonably, where 82.4 had come from. It was
  /// a smoothed average across two readings — one of them a leftover test entry
  /// that was not his — and so it matched neither the scale nor the app, which
  /// is the one thing a number sitting under a weight must never do. Two
  /// figures that disagree on one row make a person distrust both, and they are
  /// right to.
  ///
  /// So the figure is gone. What is left is what a person would actually say
  /// about their own weight: which way it is going and how fast, or that it is
  /// holding steady, or nothing at all until there is enough to know.
  static String? of(WeightHistory history, {bool imperial = false}) {
    if (history.isEmpty || history.trend == null) return null;
    final unit = imperial ? 'lbs' : 'kg';

    final week = history.aWeek;
    if (week == null) return notEnoughYet;
    if (week.abs() < steadyWithin) return steady;

    final moved = imperial
        ? week.abs().toDouble() * perKg
        : week.abs().toDouble();
    final way = week < 0 ? 'Down' : 'Up';
    return '$way ${moved.toStringAsFixed(1)} $unit a week';
  }
}
