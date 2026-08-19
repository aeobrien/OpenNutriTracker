import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// A meal that is planned for today and has not been eaten.
///
/// It sits on the day among the things that *have* been eaten, so the one thing
/// this row must never do is look like one of them. Three separate signals say
/// so, because any one of them alone can be missed: it says the word "Planned",
/// it carries an outline rather than a filled row, and the whole thing is drawn
/// faded. Somebody glancing at their day should not have to read carefully to
/// know they have not had this yet.
///
/// The portion shown is this person's own share of the meal — not the meal's
/// standard portion and not the household's. Two people eating the same dinner
/// see different amounts here, which is the point of storing a portion per
/// person at all.
class PlannedMealRow extends StatelessWidget {
  /// The faded look, named once so the test can assert on the same number the
  /// screen uses rather than a copy of it.
  static const plannedOpacity = 0.6;

  final PlannedItem item;

  /// Tapped when they had it. Null on a screen that only shows the plan.
  final VoidCallback? onAte;

  /// Tapped when they didn't. A separate answer from doing nothing: a meal
  /// nobody decided about is still coming, and one that was skipped is not.
  final VoidCallback? onNotEaten;

  const PlannedMealRow({
    super.key,
    required this.item,
    this.onAte,
    this.onNotEaten,
  });

  /// This person's share, in words. Deliberately says nothing when nobody has
  /// said what the portion is: "1 portion" would be a guess, and a guess here
  /// becomes a calorie figure that looks exactly as solid as a real one.
  static String portionText(PlannedItem item) {
    final portions = item.portions;
    if (portions == null) return 'Portion not set';
    if (portions == 1) return 'Your portion: 1 portion';
    final asText = portions == portions.roundToDouble()
        ? portions.round().toString()
        : portions.toString();
    return 'Your portion: $asText portions';
  }

  /// What the row says where a figure would go. A planned meal with no numbers
  /// says so rather than showing nothing, so an unworked meal is visible as a
  /// gap to fill instead of quietly reading as free.
  static String? gapText(PlannedItem item) {
    if (item.kcal != null) return null;
    if (!item.mealKcalKnown) return 'Awaiting calories';
    return 'Awaiting a portion';
  }

  /// The two answers, named once so a test asserts on the same words the
  /// screen shows rather than a copy of them.
  static const ateLabel = 'Ate it';
  static const notEatenLabel = "Didn't have it";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = gapText(item);
    final row = Opacity(
      opacity: plannedOpacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Outlined, not filled — the eaten rows are the solid ones.
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(portionText(item), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Planned'),
                if (gap != null && !Figures.off(context))
                  Text(gap, style: theme.textTheme.bodySmall)
                else
                  Figures.kcalText(context, item.kcal,
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );

    if (onAte == null && onNotEaten == null) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Saying you did not have it is deliberately the quieter of the
              // two. Both are one tap, but the common answer is the solid one,
              // so the button under a thumb at dinner time is the right one.
              if (onNotEaten != null)
                TextButton(
                  onPressed: onNotEaten,
                  child: const Text(notEatenLabel),
                ),
              if (onAte != null) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAte,
                  child: const Text(ateLabel),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
