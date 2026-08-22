import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class IntakeCard extends StatelessWidget {
  /// What the two rotor actions are called. Named here so the tests that hold
  /// them and the card that offers them cannot drift apart — a rotor action
  /// whose label changed is a rotor action nobody can find.
  static const deleteAction = 'Delete';
  static const editAction = 'Edit';

  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final bool firstListElement;
  final bool usesImperialUnits;

  const IntakeCard({
    required super.key,
    required this.intake,
    this.onItemLongPressed,
    this.onItemTapped,
    required this.firstListElement,
    required this.usesImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 0),
        SizedBox(
          width: 120,
          height: 120,
          // No sideways swipe here on purpose. The strip these cards sit in
          // scrolls sideways, and a card that also answered a sideways drag
          // took every one of them: past three items a meal could not be read
          // at all. Removing a row is asked for by name now — tap the card, or
          // hold it — and the undo offer went with it, see sayTheRowIsGone.
          //
          // Removing by name is also why the actions rotor matters here.
          // Release 7, BC-0025: the non-touch route to deleting is VoiceOver
          // offering Delete on the row. Holding a card is not a gesture
          // somebody navigating by rotor can make, and until this the only
          // ways in were a tap and a hold — so for that person the row could
          // be read and not removed. The action does exactly what holding it
          // does, confirmation dialog and all: one behaviour, two ways to
          // reach it.
          child: Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 1,
            // Inside the Card, not around it. The Card is this row's semantics
            // container, so actions declared outside it merge into whatever
            // encloses the list rather than into the row — where a rotor would
            // never find them.
            child: Semantics(
              customSemanticsActions: {
                if (onItemLongPressed != null)
                  const CustomSemanticsAction(label: deleteAction): () =>
                      onLongPressedItem(context),
                if (onItemTapped != null)
                  const CustomSemanticsAction(label: editAction): () =>
                      onTappedItem(context, usesImperialUnits),
              },
              child: InkWell(
                onLongPress: onItemLongPressed != null
                    ? () => onLongPressedItem(context)
                    : null,
                onTap: onItemTapped != null
                    ? () => onTappedItem(context, usesImperialUnits)
                    : null,
                child: Stack(
                  children: [
                    intake.isQuickAdd
                        ? Center(
                            child: Icon(
                              Icons.bolt,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : intake.isRecipe
                        ? Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : intake.meal.mainImageUrl != null
                        ? CachedNetworkImage(
                            cacheManager: locator<CacheManager>(),
                            imageUrl: intake.meal.mainImageUrl ?? "",
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.restaurant_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                    Container(
                      // Add color shade
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      ),
                    ),
                    if (!Figures.off(context))
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Figures.kcalText(
                          context,
                          intake.totalKcal,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
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
                            intake.isQuickAdd || intake.isRecipe
                                ? (intake.quickAddLabel ??
                                      (intake.isRecipe
                                          ? 'Recipe'
                                          : 'Quick add'))
                                : (intake.meal.name ?? "?"),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!intake.isQuickAdd && !intake.isRecipe)
                            MealValueUnitText(
                              value: intake.amount,
                              meal: intake.meal,
                              usesImperialUnits: usesImperialUnits,
                              textStyle: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer
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
      ],
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed?.call(context, intake);
  }

  void onTappedItem(BuildContext context, bool usesImperialUnits) {
    onItemTapped?.call(context, intake, usesImperialUnits);
  }
}
