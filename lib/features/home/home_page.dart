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
import 'package:opennutritracker/core/presentation/widgets/say_the_row_is_gone.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/said/presentation/say_what_you_ate_section.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/features/today/domain/planned_today.dart';
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

  /// A question asked on an earlier opening that nobody answered. Held here
  /// because the section that asks it has not been built yet when the day's
  /// catch-up finds it.
  AQuestionStillWaiting? _stillWaiting;

  /// What the household has planned for today that nobody has answered about.
  /// Drawn as ghost cards in the dinner strip — see [PlannedMealCard].
  late final PlannedToday _planned = PlannedToday(locator<HouseholdLogger>());

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
            state.healthKitConnected,
          );
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
    return const Center(child: CircularProgressIndicator());
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
    bool healthKitConnected,
  ) {
    if (showDisclaimerDialog) {
      _showDisclaimerDialog(context);
    }
    return Stack(
      children: [
        ListView(
          key: const PageStorageKey('home_list'),
          children: [
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
            // The week that used to sit here went with it, at his instruction:
            // planning is what the kitchen panel is for, and a second copy of it
            // on the phone was a second thing to keep in step for no gain.
            //
            // A planned meal is the one thing that did come back, on 22 August,
            // and it came back as the opposite of a section. It is a ghost card
            // inside the diary's own list — see the dinner slot below — because
            // when he was asked where confirming a dinner should live he said:
            // "a 'ghost' entry on the home screen of the phone app which looks
            // just like a regular food entry, but says 'tap to confirm'.
            SayWhatYouAteSection(
              key: _said,
              said: locator<SaidRepository>(),
              microphone: locator<Microphone>(),
              day: SayWhatYouAteSection.dayKey(DateTime.now()),
              waiting: _stillWaiting,
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
              // The plan does not record which meal of the day it is for — it
              // is one meal against a date — and every meal ever planned on
              // this household's panel has been the evening one. So the ghosts
              // sit in dinner. If breakfasts are ever planned, this is the line
              // that has to learn about it.
              planned: _planned.items,
              onAtePlanned: (item) => _decidePlanned(item, true),
              onPlannedNotEaten: (item) => _decidePlanned(item, false),
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
            const SizedBox(height: 48.0),
          ],
        ),
      ],
    );
  }

  void onActivityItemLongPressed(
    BuildContext context,
    UserActivityEntity activityEntity,
  ) async {
    final deleteIntake = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (deleteIntake != null) {
      // Awaited before redrawing, for the same reason as a correction: the day
      // is read back out of the database, so a redraw that overtakes the write
      // puts the exercise's allowance back on the ring it just came off.
      await _homeBloc.deleteUserActivityItem(activityEntity);
      _reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
        );
      }
    }
  }

  void onIntakeItemLongPressed(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    final deleteIntake = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (deleteIntake != null) {
      if (!context.mounted) return;
      await _removeTheRow(context, intakeEntity);
    }
  }

  /// Take a row off the day, and say so in a way that can be taken back.
  ///
  /// Both ways of removing a row come through here — holding the card, and
  /// asking for it inside the card's own dialog — so the offer to undo is made
  /// the same way whichever one was used, and cannot be lost by changing one
  /// of them.
  Future<void> _removeTheRow(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    // Awaited before redrawing: the day is read back out of the database, so a
    // redraw that overtakes the write puts the row's figures back on the ring
    // it just came off.
    await _homeBloc.deleteIntakeItem(intakeEntity);
    _reload();
    if (!context.mounted) return;
    sayTheRowIsGone(context, intakeEntity);
  }

  void onIntakeItemTapped(
    BuildContext context,
    IntakeEntity intakeEntity,
    bool usesImperialUnits,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedText = S.of(context).itemUpdatedSnackbar;

    final edit = await showDialog<IntakeEdit>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
        usesImperialUnits: usesImperialUnits,
      ),
    );
    if (edit != null && edit.remove) {
      if (!context.mounted) return;
      await _removeTheRow(context, intakeEntity);
      return;
    }
    // A tap that changed nothing is not a correction, and must not travel to
    // the household as one — an amend with an empty body still bumps the row's
    // version there and discards anything still on the wire for it.
    if (edit != null && (edit.fields.isNotEmpty || edit.moveTo != null)) {
      // Awaited, then redrawn. Redrawing without waiting reads the day back
      // out of the database before the correction has been written to it, and
      // the ring keeps showing the figure the person just changed.
      await _homeBloc.updateIntakeItem(
        intakeEntity.id,
        edit.fields,
        moveTo: edit.moveTo,
      );
      _reload();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(days: 1),
          content: Text(
            edit.moveTo != null ? 'Moved off your day.' : updatedText,
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 4), () {
        messenger.hideCurrentSnackBar();
      });
    }
  }

  void onDeleteIntake(
    IntakeEntity intake,
    TrackedDayEntity? trackedDayEntity,
  ) async {
    // Awaited before redrawing, for the same reason as a correction: the day
    // is read back out of the database, so a redraw that overtakes the write
    // puts the row's figures back on the ring it just came off.
    await _homeBloc.deleteIntakeItem(intake);
    _reload();
  }

  /// Show disclaimer dialog after build method
  void _showDisclaimerDialog(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dialogConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return const DisclaimerDialog();
        },
      );
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

  /// Have another go at anything spoken that never got worked out.
  ///
  /// A sentence is asked about once, straight after it is said. If that single
  /// attempt does not land — the Mac Mini asleep, the address wrong, the phone
  /// put down mid-answer — nothing ever asked again, and the row stayed on the
  /// day reading "Something you said" with no calories against it for good.
  /// Aidan ended up with three of them.
  ///
  /// [SaidRepository.catchUp] was written for exactly this and had no caller
  /// anywhere in the app. Its own comment says it runs "when the day is read",
  /// and the screen that read the day was the second tab — which was removed at
  /// Aidan's instruction, taking the only moment the retry could have happened
  /// with it. Nobody noticed, because a retry that never runs and a retry that
  /// has not run yet look identical from the day.
  ///
  /// It runs before the pull rather than after: settling a row at the house is
  /// what turns it into food the pull can bring down, so doing it the other way
  /// round would leave the food waiting until the next time the app opened.
  ///
  /// Quiet on failure, like the rest of opening the app. A sleeping Mini means
  /// the rows wait for next time, which is what they were doing anyway.
  Future<void> _catchUpOnWhatWasSaid() async {
    try {
      final day = await locator<DayRepository>().today(
        SayWhatYouAteSection.dayKey(DateTime.now()),
      );
      final caught = await locator<SaidRepository>().catchUp(day.logged);
      if (caught.settled > 0) {
        log.info(
          '[SAID] ${caught.settled} row(s) that had been left unfinished '
          'were worked out on opening',
        );
      }
      // A row can be unfinished because it is waiting on an answer, not because
      // anything failed. Nothing goes on a day until somebody says which meal
      // it was, so an unanswered question is food that never arrives — it gets
      // asked again here rather than being left on the Mac Mini in silence.
      //
      // Set even when there is nothing waiting, so a question that has since
      // been answered stops being handed down. The screen below has its own
      // guard against asking twice; this is the same fact kept true in the one
      // place that knows it, rather than only where it is noticed.
      if (mounted && caught.waiting != _stillWaiting) {
        setState(() => _stillWaiting = caught.waiting);
      }
      // The same read already carries what is planned, so the ghost cards cost
      // no extra journey to the Mac Mini.
      if (mounted) setState(() => _planned.takeFrom(day));
    } catch (e) {
      log.info('[SAID] nothing could be caught up this time: $e');
    }
  }

  /// Record what they did about a planned meal.
  ///
  /// The card goes as soon as they tap, before the Mac Mini has heard. The
  /// answer is on the queue, which is where every other write on this phone
  /// waits too. What would be dishonest is the opposite: leaving a meal on the
  /// day looking undecided when the person has decided.
  Future<void> _decidePlanned(PlannedItem item, bool ate) async {
    setState(() {}); // the card goes now; PlannedToday decides what is left
    final queued = await _planned.decide(item, ate: ate);
    if (!mounted) return;
    setState(() {});
    if (!queued) {
      await _catchUpOnWhatWasSaid();
      return;
    }
    // Confirming a dinner puts it on the ledger, so the diary and the ring both
    // have to catch up with what just happened.
    _syncMantel();
  }

  void _syncMantel() {
    _catchUpOnWhatWasSaid()
        .then((_) => locator<MantelSyncService>().syncPending())
        .then((result) {
          if (!mounted) return;
          if (result.hasNewEntries) {
            log.info('Mantel sync added ${result.synced} meal(s); refreshing');
            _reload();
          }
        })
        .catchError((Object e) {
          log.warning('Mantel sync failed: $e');
        });
  }
}
