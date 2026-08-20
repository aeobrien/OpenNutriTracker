import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

/// The six things setup asks, in a shape the Mac Mini can keep.
///
/// This exists because the phone forgets them. Reinstalling the app removes
/// the app, and everything it had written is inside it — so the six questions
/// come back every time, and during development that is most days. The
/// household already remembers who lives here; it can remember this too.
///
/// **Names on the wire are the enum's own names**, not numbers and not
/// translated words. A number would silently mean something different the day
/// somebody reorders the list; a translated word would mean the profile
/// stopped reading back when the phone's language changed.
///
/// **An unrecognised name is not a default.** Reading one back throws rather
/// than quietly picking `sedentary`, because the whole purpose of this is to
/// let setup be skipped — and a skipped setup that quietly guessed how much
/// somebody moves produces a calorie target that is wrong and looks right.
class RememberedProfile {
  static const fields = [
    'birthday', 'height_cm', 'weight_kg', 'gender', 'goal', 'activity',
  ];

  static Map<String, dynamic> of(UserEntity user) => {
        'birthday': _asDay(user.birthday),
        'height_cm': user.heightCM,
        'weight_kg': user.weightKG,
        'gender': user.gender.name,
        'goal': user.goal.name,
        'activity': user.pal.name,
      };

  /// The stored profile as the app's own record, or null when the household
  /// has nothing usable. Null is the honest answer for a profile that is
  /// missing anything at all — see the class comment.
  static UserEntity? from(Map<String, dynamic>? stored) {
    if (stored == null) return null;
    for (final f in fields) {
      final v = stored[f];
      if (v == null || (v is String && v.isEmpty)) return null;
    }
    return UserEntity(
      birthday: DateTime.parse(stored['birthday'] as String),
      heightCM: (stored['height_cm'] as num).toDouble(),
      weightKG: (stored['weight_kg'] as num).toDouble(),
      gender: _one(UserGenderEntity.values, stored['gender'] as String, 'gender'),
      goal: _one(UserWeightGoalEntity.values, stored['goal'] as String, 'goal'),
      pal: _one(UserPALEntity.values, stored['activity'] as String, 'activity'),
    );
  }

  static T _one<T extends Enum>(List<T> values, String name, String what) =>
      values.firstWhere((v) => v.name == name,
          orElse: () => throw FormatException(
              'the household has a $what of "$name", which this app does not '
              'recognise — better to ask again than to guess'));

  static String _asDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
