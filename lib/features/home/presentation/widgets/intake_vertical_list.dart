import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_all_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeVerticalList extends StatefulWidget {
  final DateTime day;
  final String title;
  final IconData listIcon;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final bool usesImperialUnits;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity)
      onDeleteIntakeCallback;
  final Function(BuildContext, IntakeEntity)? onItemLongPressedCallback;
  final Function(bool)? onItemDragCallback;
  final Function(BuildContext, IntakeEntity, bool)? onItemTappedCallback;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity,
      AddMealType? type)? onCopyIntakeCallback;
  final TrackedDayEntity? trackedDayEntity;

  const IntakeVerticalList({
    super.key,
    required this.day,
    required this.title,
    required this.listIcon,
    required this.addMealType,
    required this.intakeList,
    required this.usesImperialUnits,
    required this.onDeleteIntakeCallback,
    this.onItemLongPressedCallback,
    this.onItemDragCallback,
    this.onItemTappedCallback,
    this.onCopyIntakeCallback,
    this.trackedDayEntity,
  });

  @override
  State<IntakeVerticalList> createState() => _IntakeVerticalListState();
}

class _IntakeVerticalListState extends State<IntakeVerticalList> {
  late MealDetailBloc _mealDetailBloc;
  late HomeBloc _homeBloc;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _homeBloc = locator<HomeBloc>();
    super.initState();
  }

  double get totalKcal {
    return widget.intakeList
        .fold(0, (previousValue, element) => previousValue + element.totalKcal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(widget.listIcon,
                  size: 24, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 4.0),
              Text(
                widget.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const Spacer(),
              if (totalKcal > 0) ...[
                Figures.kcalText(
                  context,
                  totalKcal,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                ),
                PopupMenuButton<VerticalListPopupMenuSelections>(
                    onSelected:
                        (VerticalListPopupMenuSelections selection) async {
                      switch (selection) {
                        case VerticalListPopupMenuSelections.onCopy:
                          const copyDialog = CopyDialog();
                          final selectedMealType =
                              await showDialog<AddMealType>(
                                  context: context,
                                  builder: (context) => copyDialog);
                          if (selectedMealType != null) {
                            for (IntakeEntity intake in widget.intakeList) {
                              widget.onCopyIntakeCallback!(
                                  intake, null, selectedMealType);
                            }
                          }
                          break;
                        case VerticalListPopupMenuSelections.onDelete:
                          final shouldDeleteIntakes = await showDialog<bool>(
                              context: context,
                              builder: (context) => const DeleteAllDialog());
                          if (shouldDeleteIntakes != null) {
                            for (IntakeEntity intake in widget.intakeList) {
                              widget.onDeleteIntakeCallback(
                                  intake, widget.trackedDayEntity);
                            }
                            break;
                          }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<VerticalListPopupMenuSelections>>[
                          if (widget.onCopyIntakeCallback != null)
                            PopupMenuItem<VerticalListPopupMenuSelections>(
                                value: VerticalListPopupMenuSelections.onCopy,
                                child: Text(S.of(context).dialogCopyLabel)),
                          PopupMenuItem<VerticalListPopupMenuSelections>(
                              value: VerticalListPopupMenuSelections.onDelete,
                              child: Text(S.of(context).deleteAllLabel)),
                        ]),
              ],
            ],
          ),
        ),
        DragTarget<IntakeEntity>(
          onAcceptWithDetails: (intake) {
            _onItemDropped(intake.data);
          },
          builder: (context, candidateData, rejectedData) {
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.intakeList.length + 1,
                // List length + placeholder card
                itemBuilder: (BuildContext context, int index) {
                  final firstListElement = index == 0 ? true : false;
                  if (index == widget.intakeList.length) {
                    return PlaceholderCard(
                        day: widget.day,
                        onTap: () => _onPlaceholderCardTapped(context),
                        firstListElement: firstListElement);
                  } else {
                    final intakeEntity = widget.intakeList[index];
                    return IntakeCard(
                      key: ValueKey(intakeEntity.id),
                      intake: intakeEntity,
                      onItemLongPressed: widget.onItemLongPressedCallback,
                      onItemTapped: widget.onItemTappedCallback,
                      onItemDismissed: (intake) =>
                          _onItemDismissed(context, intake),
                      firstListElement: firstListElement,
                      usesImperialUnits: widget.usesImperialUnits,
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _onPlaceholderCardTapped(BuildContext context) {
    Navigator.pushNamed(context, NavigationOptions.addMealRoute,
        arguments: AddMealScreenArguments(widget.addMealType, widget.day));
  }

  void _onItemDismissed(BuildContext context, IntakeEntity intake) {
    final messenger = ScaffoldMessenger.of(context);
    final deletedText = S.of(context).itemDeletedSnackbar;
    final undoText = S.of(context).undoLabel;

    widget.onDeleteIntakeCallback(intake, widget.trackedDayEntity);
    locator<HomeBloc>().add(const LoadItemsEvent());

    // SnackBar's internal animation timer doesn't fire after widget tree
    // rebuilds (Flutter 3.41 bug). Use Future.delayed as workaround.
    messenger.showSnackBar(
      SnackBar(
        // Set very long duration so the SnackBar doesn't try to auto-dismiss
        // via its broken internal timer — we handle dismissal ourselves.
        duration: const Duration(days: 1),
        content: Text(deletedText),
        action: SnackBarAction(
          label: undoText,
          onPressed: () {
            _mealDetailBloc.addIntake(
                context,
                intake.unit,
                intake.amount.toString(),
                widget.addMealType.getIntakeType(),
                intake.meal,
                intake.dateTime);
            locator<HomeBloc>().add(const LoadItemsEvent());
            locator<DiaryBloc>().add(const LoadDiaryYearEvent());
            locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () {
      messenger.hideCurrentSnackBar();
    });
  }

  void _onItemDropped(IntakeEntity entity) {
    _mealDetailBloc.addIntake(context, entity.unit, entity.amount.toString(),
        widget.addMealType.getIntakeType(), entity.meal, entity.dateTime);
    _homeBloc.deleteIntakeItem(entity);

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }
}
