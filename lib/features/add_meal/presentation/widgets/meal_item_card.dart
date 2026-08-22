import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

class MealItemCard extends StatelessWidget {
  final DateTime day;
  final AddMealType addMealType;
  final MealEntity mealEntity;
  final bool usesImperialUnits;
  final Function(MealEntity meal)? onToggleFavourite;
  final Function(MealEntity meal)? onQuickAdd;

  /// Hand this food back to whoever opened the picker, instead of going on to
  /// log it.
  ///
  /// Set when the picker was opened to replace the food behind a row that
  /// already exists. Everything after the choosing — how much, which meal,
  /// whose day — is already on the screen that opened it, so carrying on into
  /// the amount screen would ask all of it a second time and then log a second
  /// row.
  final bool handBackInstead;

  const MealItemCard(
      {super.key,
      required this.day,
      required this.mealEntity,
      required this.addMealType,
      required this.usesImperialUnits,
      this.onToggleFavourite,
      this.onQuickAdd,
      this.handBackInstead = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        child: SizedBox(
          height: 100,
          child: Center(
              child: ListTile(
            leading: mealEntity.thumbnailImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      cacheManager: locator<CacheManager>(),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      imageUrl: mealEntity.thumbnailImageUrl ?? "",
                    ))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.restaurant_outlined)),
                  ),
            title: AutoSizeText.rich(
                TextSpan(
                    text: mealEntity.name ?? "?",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                    children: [
                      TextSpan(
                          text: ' ${mealEntity.brands ?? ""}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8))),
                    ]),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            subtitle: _buildSubtitle(context),
            trailing: _buildTrailing(context),
          )),
        ),
        onTap: () => _onItemPressed(context),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    // Show last-used grams if available
    if (mealEntity.lastUsedGrams != null && mealEntity.lastUsedGrams! > 0) {
      final grams = mealEntity.lastUsedGrams!;
      final gramsText = grams == grams.roundToDouble()
          ? '${grams.toInt()}g'
          : '${grams.toStringAsFixed(1)}g';
      return Text(
        'last: $gramsText',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6)),
      );
    }
    if (mealEntity.mealQuantity != null) {
      return MealValueUnitText(
          value: double.parse(mealEntity.mealQuantity ?? "0"),
          meal: mealEntity,
          usesImperialUnits: usesImperialUnits);
    }
    return const SizedBox();
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggleFavourite != null)
          IconButton(
            icon: Icon(
              mealEntity.favourite ? Icons.star : Icons.star_border,
              color: mealEntity.favourite
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => onToggleFavourite!(mealEntity),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        // Quick-add is logging, so it is not offered to somebody who came
        // here to swap a food rather than to log one.
        if (!handBackInstead &&
            onQuickAdd != null &&
            mealEntity.lastUsedGrams != null &&
            mealEntity.lastUsedGrams! > 0)
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => onQuickAdd!(mealEntity),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        else
          IconButton(
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            icon: const Icon(Icons.add_outlined),
            onPressed: () => _onItemPressed(context),
          ),
      ],
    );
  }

  void _onItemPressed(BuildContext context) {
    if (handBackInstead) {
      Navigator.of(context).pop(mealEntity);
      return;
    }
    Navigator.of(context).pushNamed(NavigationOptions.mealDetailRoute,
        arguments: MealDetailScreenArguments(
            mealEntity, addMealType.getIntakeType(), day, usesImperialUnits));
  }
}
