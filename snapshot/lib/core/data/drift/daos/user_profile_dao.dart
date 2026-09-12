import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/user_profile.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfile])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<void> upsert(UserProfileCompanion entry) async {
    await into(userProfile).insertOnConflictUpdate(
      entry.copyWith(id: const Value(1)),
    );
  }

  Future<UserProfileData?> getProfile() async {
    return (select(userProfile)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }
}
