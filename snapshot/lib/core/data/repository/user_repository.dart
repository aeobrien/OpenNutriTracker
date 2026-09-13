import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/user_profile_dao.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

class UserRepository {
  final UserProfileDao _userProfileDao;
  final _log = Logger('UserRepository');

  UserRepository(this._userProfileDao);

  Future<void> updateUserData(UserEntity userEntity) async {
    _log.fine('Updating user profile');
    await _userProfileDao.upsert(UserProfileCompanion(
      id: const Value(1),
      birthday: Value(userEntity.birthday.millisecondsSinceEpoch),
      heightCm: Value(userEntity.heightCM),
      weightKg: Value(userEntity.weightKG),
      gender: Value(userEntity.gender.name),
      goal: Value(userEntity.goal.name),
      pal: Value(userEntity.pal.name),
    ));
  }

  Future<bool> hasUserData() async => await _userProfileDao.hasProfile();

  Future<UserEntity> getUserData() async {
    final profile = await _userProfileDao.getProfile();
    if (profile != null) {
      return UserEntity.fromProfileRow(profile);
    }
    // Return dummy data if no user exists (matches original behavior)
    return UserEntity(
      birthday: DateTime(2000, 1, 1),
      heightCM: 170,
      weightKG: 70,
      gender: UserGenderEntity.male,
      goal: UserWeightGoalEntity.maintainWeight,
      pal: UserPALEntity.sedentary,
    );
  }
}
