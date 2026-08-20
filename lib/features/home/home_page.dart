import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/today/presentation/planned_meals_section.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/week/presentation/week_ahead_section.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final log = Logger('HomePage');

  late HomeBloc _homeBloc;

  /// The planned-meals section lives below Home in the tree, so Home cannot
  /// find it by looking up. It is held by key instead, and told to reload
  /// whenever Home reloads — see [_reload].
  final _planned = GlobalKey<PlannedMealsSectionState>();

  /// The week, held the same way and for the same reason. Logging a meal
  /// changes today's figure on it, so it has to be told when Home reloads or
  /// it would sit there showing the week as it was when the app opened.
  final _week = GlobalKey<WeekAheadSectionState>();

  /// Reload the day. Everything on Home that can go stale goes through here so
  /// that no future call site can reload half of it.
  void _reload() {
    _homeBloc.add(const LoadItemsEvent());
    _planned.currentState?.reload();
    _week.currentState?.reload();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _homeBloc = locator<HomeBloc>();
    super.initState();
    _syncMantel(); // pull voice/chat-logged meals on cold open
    _readTheWatch(); // and put today's active calories on the household's day
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: _homeBloc,
      builder: (context, state) {
        if (state is HomeInitial) {
          _homeBloc.add(const LoadItemsEvent());
          return _getLoadingContent();
        } else if (state is HomeLoadingState) {
          return _getLoadingContent();
        } else if (state is HomeLoadedState) {
          return _getLoadedContent(
              context,
              state.showDisclaimerDialog,
              state.totalKcalDaily,
              state.totalKcalLeft,
              state.totalKcalSupplied,
              state.totalKcalBurned,
              state.totalCarbsIntake,
              state.totalFatsIntake,
              state.totalProteinsIntake,
              state.totalCarbsGoal,
              state.totalFatsGoal,
              state.totalProteinsGoal,
              state.breakfastIntakeList,
              state.lunchIntakeList,
              state.dinnerIntakeList,
              state.snackIntakeList,
              state.userActivityList,
              state.usesImperialUnits,
              state.totalKcalBase,
              state.totalKcalEarned,
              state.weeklyRemaining,
              state.activeCaloriesToday,
              state.activeCaloriesUpdatedAt,
              state.healthKitConnected);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
      _syncMantel(); // pull any meals logged via Mantel while we were away
      _readTheWatch();
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _getLoadedContent(
      BuildContext context,
      bool showDisclaimerDialog,
      double totalKcalDaily,
      double totalKcalLeft,
      double totalKcalSupplied,
      double totalKcalBurned,
      double totalCarbsIntake,
      double totalFatsIntake,
      double totalProteinsIntake,
      double totalCarbsGoal,
      double totalFatsGoal,
      double totalProteinsGoal,
      List<IntakeEntity> breakfastIntakeList,
      List<IntakeEntity> lunchIntakeList,
      List<IntakeEntity> dinnerIntakeList,
      List<IntakeEntity> snackIntakeList,
      List<UserActivityEntity> userActivities,
      bool usesImperialUnits,
      double totalKcalBase,
      double totalKcalEarned,
      double? weeklyRemaining,
      double activeCaloriesToday,
      DateTime? activeCaloriesUpdatedAt,
      bool healthKitConnected) {
    if (showDisclaimerDialog) {
      _showDisclaimerDialog(context);
    }
    return Stack(children: [
      ListView(key: const PageStorageKey('home_list'), children: [
        DashboardWidget(
          totalKcalDaily: totalKcalDaily,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalSupplied,
          totalKcalBurned: totalKcalBurned,
          totalCarbsIntake: totalCarbsIntake,
          totalFatsIntake: totalFatsIntake,
          totalProteinsIntake: totalProteinsIntake,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
          totalKcalBase: totalKcalBase,
          totalKcalEarned: totalKcalEarned,
          weeklyRemaining: weeklyRemaining,
          activeCaloriesToday: activeCaloriesToday,
          activeCaloriesUpdatedAt: activeCaloriesUpdatedAt,
          healthKitConnected: healthKitConnected,
        ),
        // What the household has planned, on the day list that already
        // exists. Nothing is drawn here on a day with no plan.
        PlannedMealsSection(
          key: _planned,
          repository: locator<DayRepository>(),
          day: PlannedMealsSection.dayKey(DateTime.now()),
          logger: locator<HouseholdLogger>(),
          // Confirming a planned dinner changes what is left of the day, so
          // the ring above has to be redrawn — not just the list it came from.
          onDecided: () => _homeBloc.add(const LoadItemsEvent()),
        ),
        // The week, on the same screen — and the way into the plan. Tapping a
        // day opens that day's planning, which writes into the same plan the
        // kitchen panel keeps rather than a second one held on the phone.
        WeekAheadSection(
          key: _week,
          repository: locator<WeekRepository>(),
          planner: locator<PlanRepository>(),
          onPlanned: _reload,
        ),
        ActivityVerticalList(
          day: DateTime.now(),
          title: S.of(context).activityLabel,
          userActivityList: userActivities,
          onItemLongPressedCallback: onActivityItemLongPressed,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).breakfastLabel,
          listIcon: IntakeTypeEntity.breakfast.getIconData(),
          addMealType: AddMealType.breakfastType,
          intakeList: breakfastIntakeList,
          onDeleteIntakeCallback: onDeleteIntake,
          onItemLongPressedCallback: onIntakeItemLongPressed,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).lunchLabel,
          listIcon: IntakeTypeEntity.lunch.getIconData(),
          addMealType: AddMealType.lunchType,
          intakeList: lunchIntakeList,
          onDeleteIntakeCallback: onDeleteIntake,
          onItemLongPressedCallback: onIntakeItemLongPressed,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).dinnerLabel,
          addMealType: AddMealType.dinnerType,
          listIcon: IntakeTypeEntity.dinner.getIconData(),
          intakeList: dinnerIntakeList,
          onDeleteIntakeCallback: onDeleteIntake,
          onItemLongPressedCallback: onIntakeItemLongPressed,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).snackLabel,
          listIcon: IntakeTypeEntity.snack.getIconData(),
          addMealType: AddMealType.snackType,
          intakeList: snackIntakeList,
          onDeleteIntakeCallback: onDeleteIntake,
          onItemLongPressedCallback: onIntakeItemLongPressed,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        const SizedBox(height: 48.0)
      ]),
    ]);
  }

  void onActivityItemLongPressed(
      BuildContext context, UserActivityEntity activityEntity) async {
    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      _homeBloc.deleteUserActivityItem(activityEntity);
      _reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
      }
    }
  }

  void onIntakeItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    final messenger = ScaffoldMessenger.of(context);
    final deletedText = S.of(context).itemDeletedSnackbar;

    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      _homeBloc.deleteIntakeItem(intakeEntity);
      _reload();
      messenger.showSnackBar(
          SnackBar(
            duration: const Duration(days: 1),
            content: Text(deletedText),
          ));
      Future.delayed(const Duration(seconds: 4), () {
        messenger.hideCurrentSnackBar();
      });
    }
  }

  void onIntakeItemTapped(BuildContext context, IntakeEntity intakeEntity,
      bool usesImperialUnits) async {
    // Quick-add entries cannot be edited via amount dialog
    if (intakeEntity.isQuickAdd) return;

    final messenger = ScaffoldMessenger.of(context);
    final updatedText = S.of(context).itemUpdatedSnackbar;

    final edit = await showDialog<IntakeEdit>(
        context: context,
        builder: (context) => EditDialog(
            intakeEntity: intakeEntity, usesImperialUnits: usesImperialUnits));
    if (edit != null) {
      _homeBloc.updateIntakeItem(intakeEntity.id, {'amount': edit.amount},
          moveTo: edit.moveTo);
      _reload();
      messenger.showSnackBar(
          SnackBar(
            duration: const Duration(days: 1),
            content: Text(updatedText),
          ));
      Future.delayed(const Duration(seconds: 4), () {
        messenger.hideCurrentSnackBar();
      });
    }
  }

  void onDeleteIntake(IntakeEntity intake, TrackedDayEntity? trackedDayEntity) {
    _homeBloc.deleteIntakeItem(intake);
    _reload();
  }

  /// Show disclaimer dialog after build method
  void _showDisclaimerDialog(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dialogConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return const DisclaimerDialog();
          });
      if (dialogConfirmed != null) {
        _homeBloc.saveConfigData(dialogConfirmed);
        _reload();
      }
    });
  }

  /// Refresh page on resume (picks up HealthKit updates + day changes)
  void _refreshPageOnDayChange() {
    _reload();
  }

  /// Pull meals logged via Mantel (voice/chat) into the diary, off the UI
  /// thread. Reloads the page only if something new was actually added. Silent
  /// on failure / when Mantel isn't configured — the manual button in Settings
  /// surfaces any errors.
  /// Put what the watch recorded today on the household's day.
  ///
  /// This used to happen when the second tab was opened, and went with it. It
  /// belongs here: the watch's figure should reach the household because the
  /// app was opened, not because somebody visited a particular screen.
  ///
  /// Safe to call as often as it likes — the row's id is worked out from the
  /// person and the day, so a day's exercise cannot multiply by being opened
  /// twice. Quiet on failure on purpose: a watch with nothing to say, a refused
  /// permission and a sleeping Mini are all ordinary, and none of them should
  /// put an error in front of somebody who just opened their day.
  void _readTheWatch() {
    locator<ExerciseSync>()
        .syncFromHealth(day: ExerciseSync.dayKey(DateTime.now()))
        .catchError((Object e) {
      log.info('Watch sync skipped: $e');
      return null;
    });
  }

  void _syncMantel() {
    locator<MantelSyncService>().syncPending().then((result) {
      if (!mounted) return;
      if (result.hasNewEntries) {
        log.info('Mantel sync added ${result.synced} meal(s); refreshing');
        _reload();
      }
    }).catchError((Object e) {
      log.warning('Mantel sync failed: $e');
    });
  }
}
