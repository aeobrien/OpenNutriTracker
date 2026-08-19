import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/exercise/presentation/type_exercise_screen.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/presentation/today_screen.dart';

/// Today, as the app mounts it.
///
/// [TodayScreen] takes everything it needs as arguments so it can be rendered
/// in a test without the app around it. This is the other half: the one place
/// that reaches into the locator, works out what day it is, and says what
/// "add exercise" opens.
class TodayPage extends StatelessWidget {
  /// The day to show. Left null in the running app, which means today.
  final String? day;

  const TodayPage({super.key, this.day});

  static String todayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return TodayScreen(
      repository: locator<DayRepository>(),
      day: day ?? todayKey(DateTime.now()),
      sync: locator<ExerciseSync>(),
      onAddExercise: (context, forDay) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TypeExerciseScreen(
              sync: locator<ExerciseSync>(),
              day: forDay,
            ),
          ),
        );
      },
    );
  }
}
