import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/weekly_summary_card.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:table_calendar/table_calendar.dart';

enum _DiaryViewMode { week, month }

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with WidgetsBindingObserver {
  final log = Logger('DiaryPage');

  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;
  late MealDetailBloc _mealDetailBloc;

  static const _calendarDurationDays = Duration(days: 356);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();
  var _viewMode = _DiaryViewMode.month;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    _mealDetailBloc = locator<MealDetailBloc>();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      bloc: _diaryBloc,
      builder: (context, state) {
        if (state is DiaryInitial) {
          _diaryBloc.add(const LoadDiaryYearEvent());
        } else if (state is DiaryLoadingState) {
          return _getLoadingContent();
        } else if (state is DiaryLoadedState) {
          return _getLoadedContent(
              context, state.trackedDayMap, state.usesImperialUnits);
        }
        return const SizedBox();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() =>
      const Center(child: CircularProgressIndicator());

  Widget _getLoadedContent(BuildContext context,
      Map<String, TrackedDayEntity> trackedDaysMap, bool usesImperialUnits) {
    return ListView(
      children: [
        // View mode toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<_DiaryViewMode>(
            segments: [
              ButtonSegment(
                value: _DiaryViewMode.week,
                label: Text(S.of(context).weekViewLabel),
                icon: const Icon(Icons.view_week_outlined),
              ),
              ButtonSegment(
                value: _DiaryViewMode.month,
                label: Text(S.of(context).monthViewLabel),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selected) {
              setState(() {
                _viewMode = selected.first;
                if (_viewMode == _DiaryViewMode.week) {
                  _calendarDayBloc.add(
                      LoadCalendarWeekEvent(_weekStart(_selectedDate)));
                } else {
                  _calendarDayBloc
                      .add(LoadCalendarDayEvent(_selectedDate));
                }
              });
            },
          ),
        ),

        DiaryTableCalendar(
          trackedDaysMap: trackedDaysMap,
          onDateSelected: _onDateSelected,
          calendarDurationDays: _calendarDurationDays,
          currentDate: _currentDate,
          selectedDate: _selectedDate,
          focusedDate: _focusedDate,
          calendarFormat: _viewMode == _DiaryViewMode.week
              ? CalendarFormat.week
              : CalendarFormat.month,
        ),
        const SizedBox(height: 16.0),
        BlocBuilder<CalendarDayBloc, CalendarDayState>(
          bloc: _calendarDayBloc,
          builder: (context, state) {
            if (state is CalendarDayInitial) {
              if (_viewMode == _DiaryViewMode.week) {
                _calendarDayBloc.add(
                    LoadCalendarWeekEvent(_weekStart(_selectedDate)));
              } else {
                _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
              }
            } else if (state is CalendarDayLoading) {
              return _getLoadingContent();
            } else if (state is CalendarWeekLoaded) {
              return WeeklySummaryCard(
                summary: state.summary,
                dailyRows: state.dailyRows,
              );
            } else if (state is CalendarDayLoaded) {
              return DayInfoWidget(
                trackedDayEntity: state.trackedDayEntity,
                selectedDay: _selectedDate,
                userActivities: state.userActivityList,
                breakfastIntake: state.breakfastIntakeList,
                lunchIntake: state.lunchIntakeList,
                dinnerIntake: state.dinnerIntakeList,
                snackIntake: state.snackIntakeList,
                onDeleteIntake: _onDeleteIntakeItem,
                onDeleteActivity: _onDeleteActivityItem,
                onCopyIntake: _onCopyIntakeItem,
                onCopyActivity: _onCopyActivityItem,
                usesImperialUnits: usesImperialUnits,
                onIntakeItemTapped: _onIntakeItemTapped,
              );
            }
            return const SizedBox();
          },
        )
      ],
    );
  }

  /// Tapping a row on the day being looked at, to correct it.
  ///
  /// The same dialog the home screen opens, doing the same thing to the same
  /// row — the only difference is which day's totals the correction is taken
  /// off and put back on, which is this screen's selected day rather than
  /// today. Until 1 September 2026 this screen had no tap at all: the cards
  /// were built without one and swallowed being tapped, so an older meal could
  /// be read, deleted or copied, and never corrected.
  void _onIntakeItemTapped(
    BuildContext context,
    IntakeEntity intakeEntity,
    bool usesImperialUnits,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedText = S.of(context).itemUpdatedSnackbar;
    // Whose phone this is, so that putting an older version of a row back knows
    // whether that also means moving it to the other person's day.
    final owner = await locator<HouseholdRepository>().storedOwner();
    if (!context.mounted) return;

    final edit = await showDialog<IntakeEdit>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
        usesImperialUnits: usesImperialUnits,
        currentOwner: owner,
      ),
    );
    if (edit == null) return;
    if (edit.remove) {
      if (!context.mounted) return;
      _onDeleteIntakeItem(intakeEntity, null);
      return;
    }
    // A tap that changed nothing is not a correction and must not travel to the
    // household as one — an empty amend still bumps the row's version there and
    // discards anything still on the wire for it.
    if (edit.fields.isEmpty && edit.moveTo == null && edit.nowItIs == null) {
      return;
    }

    await _calendarDayBloc.updateIntakeItem(
      intakeEntity.id,
      edit.fields,
      _selectedDate,
      moveTo: edit.moveTo,
      nowItIs: edit.nowItIs,
    );
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    messenger.showSnackBar(SnackBar(
      content: Text(
          edit.moveTo != null ? 'Moved off your day.' : updatedText),
    ));
  }

  void _onDeleteIntakeItem(
      IntakeEntity intakeEntity, TrackedDayEntity? trackedDayEntity) async {
    await _calendarDayBloc.deleteIntakeItem(
        context, intakeEntity, trackedDayEntity?.day ?? DateTime.now());
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }

  void _onDeleteActivityItem(UserActivityEntity userActivityEntity,
      TrackedDayEntity? trackedDayEntity) async {
    await _calendarDayBloc.deleteUserActivityItem(
        context, userActivityEntity, trackedDayEntity?.day ?? DateTime.now());
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }

  void _onCopyIntakeItem(IntakeEntity intakeEntity,
      TrackedDayEntity? trackedDayEntity, AddMealType? type) async {
    IntakeTypeEntity finalType;
    if (type == null) {
      finalType = intakeEntity.type;
    } else {
      finalType = type.getIntakeType();
    }
    _mealDetailBloc.addIntake(
        context,
        intakeEntity.unit,
        intakeEntity.amount.toString(),
        finalType,
        intakeEntity.meal,
        DateTime.now());
    _diaryBloc.updateHomePage();
  }

  void _onCopyActivityItem(UserActivityEntity userActivityEntity,
      TrackedDayEntity? trackedDayEntity) async {
    log.info("Should copy activity");
  }

  void _onDateSelected(
      DateTime newDate, Map<String, TrackedDayEntity> trackedDaysMap) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = newDate;
      if (_viewMode == _DiaryViewMode.week) {
        _calendarDayBloc.add(LoadCalendarWeekEvent(_weekStart(newDate)));
      } else {
        _calendarDayBloc.add(LoadCalendarDayEvent(newDate));
      }
    });
  }

  void _refreshPageOnDayChange() {
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      if (_viewMode == _DiaryViewMode.week) {
        _calendarDayBloc
            .add(LoadCalendarWeekEvent(_weekStart(_selectedDate)));
      } else {
        _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
      }
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }

  /// Returns Monday of the week containing [date].
  DateTime _weekStart(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }
}
