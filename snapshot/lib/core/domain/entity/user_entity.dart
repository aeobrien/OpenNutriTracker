import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

class UserEntity {
  DateTime birthday;
  double heightCM;
  double weightKG;
  UserGenderEntity gender;
  UserWeightGoalEntity goal;
  UserPALEntity pal;

  UserEntity(
      {required this.birthday,
      required this.heightCM,
      required this.weightKG,
      required this.gender,
      required this.goal,
      required this.pal});

  factory UserEntity.fromProfileRow(UserProfileData row) {
    return UserEntity(
        birthday: DateTime.fromMillisecondsSinceEpoch(row.birthday),
        heightCM: row.heightCm,
        weightKG: row.weightKg,
        gender: UserGenderEntity.values.firstWhere(
            (e) => e.name == row.gender,
            orElse: () => UserGenderEntity.male),
        goal: UserWeightGoalEntity.values.firstWhere(
            (e) => e.name == row.goal,
            orElse: () => UserWeightGoalEntity.maintainWeight),
        pal: UserPALEntity.values.firstWhere(
            (e) => e.name == row.pal,
            orElse: () => UserPALEntity.sedentary));
  }

  factory UserEntity.fromUserDBO(UserDBO userDBO) {
    return UserEntity(
        birthday: userDBO.birthday,
        heightCM: userDBO.heightCM,
        weightKG: userDBO.weightKG,
        gender: UserGenderEntity.fromUserGenderDBO(userDBO.gender),
        goal: UserWeightGoalEntity.fromUserWeightGoalDBO(userDBO.goal),
        pal: UserPALEntity.fromUserPALDBO(userDBO.pal));
  }

  int get age => DateTime.now().difference(birthday).inDays~/365;
}
