import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Say a row has gone, and offer to put it back when it was this phone's to
/// take away.
///
/// This is the one place the offer is made. It used to sit behind a sideways
/// swipe on the card, and the swipe had to go: a meal's items sit in a strip
/// that scrolls sideways, and one sideways drag cannot both scroll the strip
/// and delete the card under the thumb — with both wired up the delete always
/// won and the strip could not be read past its third item. Removing is now
/// something asked for by name, so the offer moved with it instead of leaving
/// with the gesture.
void sayTheRowIsGone(BuildContext context, IntakeEntity intake) {
  final messenger = ScaffoldMessenger.of(context);
  final gone = S.of(context).itemDeletedSnackbar;
  final undo = S.of(context).undoLabel;

  // SnackBar's internal animation timer doesn't fire after widget tree
  // rebuilds (Flutter 3.41 bug). Use Future.delayed as workaround.
  messenger.showSnackBar(
    SnackBar(
      // Set very long duration so the SnackBar doesn't try to auto-dismiss
      // via its broken internal timer — we handle dismissal ourselves.
      duration: const Duration(days: 1),
      content: Text(gone),
      // Undo only ever reverses what this phone did. A row the household put
      // on this day is somebody else's action, so the offer is not made for
      // it — see IntakeEntity.isALocalAction. Removing it stays possible the
      // ordinary way, which is the same thing that just removed it.
      action: intake.isALocalAction
          ? SnackBarAction(
              label: undo,
              onPressed: () async {
                await locator<MealDetailBloc>().putBack(intake);
                locator<HomeBloc>().add(const LoadItemsEvent());
                locator<DiaryBloc>().add(const LoadDiaryYearEvent());
                locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
              },
            )
          : null,
    ),
  );
  Future.delayed(const Duration(seconds: 5), () {
    messenger.hideCurrentSnackBar();
  });
}
