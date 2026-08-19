import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_height_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    _profileBloc = locator<ProfileBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      builder: (context, state) {
        if (state is ProfileInitial) {
          _profileBloc.add(LoadProfileEvent());
          return _getLoadingContent();
        } else if (state is ProfileLoadingState) {
          return _getLoadingContent();
        } else if (state is ProfileLoadedState) {
          return _getLoadedContent(
              context, state.userEntity, state.usesImperialUnits);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  Widget _getLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _getLoadedContent(
      BuildContext context, UserEntity user, bool usesImperialUnits) {
    return ListView(
      children: [
        const SizedBox(height: 32.0),
        ListTile(
          title: Text(
            S.of(context).activityLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            user.pal.getName(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.directions_walk_outlined),
          ),
          onTap: () => _showSetPALCategoryDialog(context, user),
        ),
        ListTile(
          title: Text(
            S.of(context).goalLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            user.goal.getName(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.flag_outlined),
          ),
          onTap: () => _showSetGoalDialog(context, user),
        ),
        // One weight row, and it is never hidden. There used to be two on this
        // screen — this one, and a household weight section directly above it,
        // which is what Aidan hit when he asked why the profile weight ignored
        // the tracking switch. The second one is gone; this one now reaches the
        // household when sharing is on.
        //
        // Deliberately not wrapped in the weight-tracking switch. Aidan ruled
        // on 19 August that the switch governs sharing only: this row is where
        // the app's own calorie calculation gets a weight, so hiding it would
        // leave a stored number that can never be corrected — and the setting
        // is off by default, so a fresh install would lose the row before
        // anybody had chosen anything.
        ListTile(
          title: Text(
            S.of(context).weightLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            '${_profileBloc.getDisplayWeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.monitor_weight_outlined),
          ),
          onTap: () {
            _showSetWeightDialog(context, user, usesImperialUnits);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).heightLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            '${_profileBloc.getDisplayHeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).ftLabel : S.of(context).cmLabel}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.height_outlined),
          ),
          onTap: () {
            _showSetHeightDialog(context, user, usesImperialUnits);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).ageLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).yearsLabel(user.age),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.cake_outlined),
          ),
          onTap: () {
            _showSetBirthdayDialog(context, user);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).genderLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            user.gender.getName(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: SizedBox(
            height: double.infinity,
            child: Icon(user.gender.getIcon()),
          ),
          onTap: () {
            _showSetGenderDialog(context, user);
          },
        ),
      ],
    );
  }

  Future<void> _showSetPALCategoryDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedPalCategory = await showDialog<UserPALEntity>(
        context: context,
        builder: (BuildContext context) => const SetPALCategoryDialog());
    if (selectedPalCategory != null) {
      userEntity.pal = selectedPalCategory;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGoalDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGoal = await showDialog<UserWeightGoalEntity>(
        context: context,
        builder: (BuildContext context) => const SetWeightGoalDialog());
    if (selectedGoal != null) {
      userEntity.goal = selectedGoal;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetHeightDialog(BuildContext context, UserEntity userEntity,
      bool usesImperialUnits) async {
    final selectedHeight = await showDialog<double>(
        context: context,
        builder: (context) => SetHeightDialog(
              userHeight: usesImperialUnits
                  ? UnitCalc.cmToFeet(userEntity.heightCM)
                  : userEntity.heightCM,
              usesImperialUnits: usesImperialUnits,
            ));
    if (selectedHeight != null) {
      if (usesImperialUnits) {
        userEntity.heightCM = UnitCalc.feetToCm(selectedHeight);
      } else {
        userEntity.heightCM = selectedHeight;
      }

      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetWeightDialog(BuildContext context, UserEntity userEntity,
      bool usesImperialSystem) async {
    final selectedWeight = await showDialog<double>(
        context: context,
        builder: (context) => SetWeightDialog(
              userWeight: usesImperialSystem
                  ? UnitCalc.kgToLbs(userEntity.weightKG)
                  : userEntity.weightKG,
              usesImperialUnits: usesImperialSystem,
            ));
    if (selectedWeight != null) {
      if (usesImperialSystem) {
        userEntity.weightKG = UnitCalc.lbsToKg(selectedWeight);
      } else {
        userEntity.weightKG = selectedWeight;
      }
      _profileBloc.updateUser(userEntity);
      if (context.mounted) {
        _alsoTellTheHousehold(context, userEntity.weightKG);
      }
    }
  }

  /// Put the weight he just typed on the household's ledger too — if this
  /// person shares their weight with the household.
  ///
  /// The app has always kept its own current weight and uses it to work out the
  /// daily target. The household keeps a dated record, which is what the other
  /// phone and the kitchen panel read. Before this those were two separate
  /// places a weight could be typed; now there is one row.
  ///
  /// **What the weight-tracking switch does, decided by Aidan on 19 August:**
  /// it governs the household side only — whether weights are shared and shown
  /// in the household's history. It never hides or disables this row. The plan
  /// originally said the switch should hide it, and that was put back to him
  /// because the row is where the app's own calorie calculation gets a weight:
  /// hiding it does not erase the stored number, it makes it impossible to
  /// correct, so the app would go on working from a weight that can no longer
  /// be updated. And since the setting is off by default in both the app and
  /// the household's records, a fresh install would have lost the row before
  /// anybody chose anything. His answer: the row always stays and always stays
  /// editable.
  ///
  /// Turning the switch off stops new weights being shared. It deletes nothing
  /// — the history is still there and comes back when it is turned on.
  ///
  /// Quiet on failure, and it cannot fail the app's own save: the weight is
  /// already stored by the time this runs, and the household write goes into
  /// the queue that holds and retries.
  void _alsoTellTheHousehold(BuildContext context, double kg) {
    if (!WeightTrackingScope.onIn(context)) {
      Logger('ProfilePage').info(
          '[WEIGHT] saved locally; not shared, because this person has weight '
          'sharing switched off');
      return;
    }
    final now = DateTime.now();
    locator<HouseholdLogger>()
        .logWeight(day: ExerciseSync.dayKey(now), kg: kg)
        .catchError((Object e) {
      Logger('ProfilePage')
          .warning('Weight saved locally but not put to the household: $e');
      return '';
    });
  }

  Future<void> _showSetBirthdayDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: userEntity.birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (selectedDate != null) {
      userEntity.birthday = selectedDate;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGenderDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGender = await showDialog<UserGenderEntity>(
        context: context,
        builder: (BuildContext context) => const SetGenderDialog());
    if (selectedGender != null) {
      userEntity.gender = selectedGender;

      _profileBloc.updateUser(userEntity);
    }
  }
}
