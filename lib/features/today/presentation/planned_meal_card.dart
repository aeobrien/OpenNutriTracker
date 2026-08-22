import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// Tonight's planned dinner, sitting in the day among the things already
/// eaten — as a card that looks like one of them, waiting to become one.
///
/// Aidan asked for this shape by name on 22 August 2026: *"a 'ghost' entry on
/// the home screen of the phone app which looks just like a regular food entry,
/// but says 'tap to confirm' - you tap to confirm you ate that thing and it
/// becomes a real entry."*
///
/// That is the opposite of what was built before, and deliberately so. The
/// earlier row went out of its way not to resemble an eaten one — outlined,
/// faded, and captioned "Planned" — on the reasoning that a planned meal must
/// never be mistaken for a real one. He looked at that and asked for the
/// mistake to be made impossible a different way: let it sit where the real
/// thing will sit, in the same shape, and let the words carry the difference.
/// One tap turns the card into the entry it is already standing in for.
///
/// So the visual distance is small on purpose — a dashed edge and a slight
/// fade — and the sentence does the work. Anything more emphatic and it stops
/// being the entry-in-waiting he described.
class PlannedMealCard extends StatelessWidget {
  /// The sentence that makes it a ghost rather than an entry. Named once so a
  /// test asserts on the same words the screen shows.
  static const tapToConfirm = 'Tap to confirm';

  /// What holding the card offers. Saying you did not have it is a real answer
  /// and not a dismissal, so it is reachable — but it is behind a hold rather
  /// than beside the tap, because the card is 120 points wide and two buttons
  /// on it would make both of them wrong to press.
  static const notEatenLabel = "Didn't have it";

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

  /// What the card says where a figure would go. A planned meal with no numbers
  /// says so rather than showing nothing, so an unworked meal is visible as a
  /// gap to fill instead of quietly reading as free.
  static String? gapText(PlannedItem item) {
    if (item.kcal != null) return null;
    if (!item.mealKcalKnown) return 'Awaiting calories';
    return 'Awaiting a portion';
  }

  /// How faded the ghost is. Close to solid: it is meant to read as the entry
  /// it is about to become, not as a different kind of thing.
  static const ghostOpacity = 0.75;

  final PlannedItem item;

  /// Tapped when they had it — the whole point of the card.
  final VoidCallback? onAte;

  /// Held, then chosen, when they did not.
  final VoidCallback? onNotEaten;

  final bool firstListElement;

  const PlannedMealCard({
    super.key,
    required this.item,
    required this.firstListElement,
    this.onAte,
    this.onNotEaten,
  });

  Future<void> _offerNotEaten(BuildContext context) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(item.title),
              subtitle: Text(portionText(item)),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text(notEatenLabel),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (chosen == true) onNotEaten?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = gapText(item);
    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 0),
        SizedBox(
          width: 120,
          height: 120,
          child: Opacity(
            opacity: ghostOpacity,
            child: Card(
              semanticContainer: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                // The one visual difference, and it is quiet: an edge where a
                // real card has none.
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              elevation: 0,
              child: InkWell(
                onTap: onAte,
                onLongPress: onNotEaten == null
                    ? null
                    : () => _offerNotEaten(context),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    if (!Figures.off(context))
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: gap != null
                            ? Text(
                                gap,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              )
                            : Figures.kcalText(
                                context,
                                item.kcal,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            tapToConfirm,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
