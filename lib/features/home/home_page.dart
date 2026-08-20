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
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/said/presentation/say_what_you_ate_section.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final log = Logger('HomePage');

  late HomeBloc _homeBloc;

  final _said = GlobalKey<SayWhatYouAteSectionState>();

  /// Reload the day. Everything on Home that can go stale goes through here so
  /// that no future call site can reload half of it.
  void _reload() {
    _homeBloc.add(const LoadItemsEvent());
  }

  /// Somebody has just said what they ate, and the household has understood it.
  ///
  /// The meal is on the ledger by now but not yet in this phone's diary, so the
  /// mirror is run before the screen is redrawn. Without this the food would
  /// appear the *next* time the app was opened, which from where a person is
  /// standing is indistinguishable from it not having worked.
  void _afterSaying() {
    _syncMantel();
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
        // Saying what you ate, above the day it lands on. The button is here
        // rather than behind a tab because the whole promise is that it takes
        // one motion — a screen you have to find first is a screen people go
        // back to typing instead of.
        //
        // What it no longer has under it is a list of its own. On 20 August
        // 2026 this screen showed spoken food in one place and the four meal
        // slots below in another, with nothing joining them and the ring at the
        // top counting only the second. Aidan's words: "it seems like despite
        // the issues we had yesterday you are still building a separate system
        // inside the existing system." Spoken food now goes where all the other
        // food goes — into the slots below, through the mirror the app has had
        // all along — so there is one day on this screen and not two.
        //
        // The planned-meals list and the week that used to sit here went with
        // it, at his instruction: planning is what the kitchen panel is for,
        // and a second copy of it on the phone was a second thing to keep in
        // step for no gain.
        SayWhatYouAteSection(
          key: _said,
          said: locator<SaidRepository>(),
          microphone: locator<Microphone>(),
          day: SayWhatYouAteSection.dayKey(DateTime.now()),
          // Understanding a sentence takes seconds, and the meal it turns into
          // has to be fetched from the household before it is in the diary. So
          // the pull runs here rather than only on open — otherwise you would
          // say something, watch nothing happen, and put the phone down.
          onChanged: _afterSaying,
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
