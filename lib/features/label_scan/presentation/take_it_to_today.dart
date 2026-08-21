/// Taking up the offer to put a just-saved packet on today.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/domain/putting_it_on_today.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

/// What happens when somebody presses "Put it on today".
///
/// Written once and handed to every screen that offers it, so that the offer
/// cannot come to mean different things on different routes.
///
/// It ends on the app's own portion screen rather than putting a figure on the
/// day by itself. A packet says what is in a hundred grams; it does not say how
/// much of it somebody ate, and choosing for them would be inventing the one
/// number this whole system exists to get right.
Future<void> takeItToToday(BuildContext context, FoodDraft saved) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final answer = await PuttingItOnToday(
    locator<Outbox>(),
    locator<FoodFinder>(),
  ).find(saved);
  if (!answer.found) {
    messenger.showSnackBar(SnackBar(content: Text(answer.why!)));
    return;
  }
  final config = await locator<ConfigRepository>().getConfig();
  navigator.pushNamed(
    NavigationOptions.mealDetailRoute,
    arguments: MealDetailScreenArguments(
      answer.food!,
      answer.meal,
      DateTime.now(),
      config.usesImperialUnits,
    ),
  );
}
