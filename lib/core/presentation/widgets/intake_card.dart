import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class IntakeCard extends StatelessWidget {
  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final Function(IntakeEntity)? onItemDismissed;
  final bool firstListElement;
  final bool usesImperialUnits;

  const IntakeCard(
      {required super.key,
      required this.intake,
      this.onItemLongPressed,
      this.onItemTapped,
      this.onItemDismissed,
      required this.firstListElement,
      required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 0),
        SizedBox(
          width: 120,
          height: 120,
          child: Dismissible(
            key: ValueKey('dismiss_${intake.id}'),
            direction: DismissDirection.down,
            background: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Icon(Icons.delete_outline),
              ),
            ),
            onDismissed: (_) {
              onItemDismissed?.call(intake);
            },
            child: Card(
              semanticContainer: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 1,
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
                            child: Icon(Icons.bolt,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary))
                        : intake.isRecipe
                            ? Center(
                                child: Icon(Icons.restaurant_menu,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.primary))
                            : intake.meal.mainImageUrl != null
                            ? CachedNetworkImage(
                                cacheManager: locator<CacheManager>(),
                                imageUrl: intake.meal.mainImageUrl ?? "",
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  )),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.restaurant_outlined,
                                    color:
                                        Theme.of(context).colorScheme.secondary)),
                    Container(
                      // Add color shade
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${intake.totalKcal.toInt()} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer),
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
                                  ? (intake.quickAddLabel ?? (intake.isRecipe ? 'Recipe' : 'Quick add'))
                                  : (intake.meal.name ?? "?"),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!intake.isQuickAdd && !intake.isRecipe)
                              MealValueUnitText(
                                value: intake.amount,
                                meal: intake.meal,
                                usesImperialUnits: usesImperialUnits,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer
                                            .withValues(alpha: 0.7)),
                              ),
                          ],
                        ))
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
