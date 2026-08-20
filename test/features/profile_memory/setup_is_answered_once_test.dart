/// Setting the app up is a once-ever job, not a once-per-reinstall job.
///
/// Aidan, on 20 August, halfway through a walkthrough: *"Every time I open this
/// after a re-install I need to do a re-onboarding, where I give my weight, age,
/// activity level etc. And most of this is to calculate a target calorie figure,
/// which is then ignored in favour of the manual figure that we're applying
/// anyway."*
///
/// The obvious fix — skip the questions and fill the answers in with something
/// plausible — is the wrong one, and these tests are written to stop anybody
/// doing it later. The app falls back to working a calorie target out of height,
/// age and activity whenever the household has not been given one, and a target
/// worked out from invented numbers is wrong in a way nothing downstream can
/// see. So nothing here invents anything. The household remembers the real
/// answers, and where it cannot, the questions get asked.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/profile_handover.dart';
import 'package:opennutritracker/features/household/domain/remembered_profile.dart';

import '../../fixture/user_entity_fixtures.dart';
import '../household/fake_household_server.dart';

/// A phone's own store of who the person is. Starts empty, the way a phone
/// does the moment the app has been reinstalled.
class _PhoneProfile extends Fake implements UserRepository {
  UserEntity? held;
  int writes = 0;

  @override
  Future<bool> hasUserData() async => held != null;

  @override
  Future<UserEntity> getUserData() async => held!;

  @override
  Future<void> updateUserData(UserEntity user) async {
    held = user;
    writes += 1;
  }
}

void main() {
  final him = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;

  group('what travels between the phone and the house', () {
    test('all six answers go up, and the words are the app\'s own', () {
      final sent = RememberedProfile.of(him);
      expect(sent.keys.toSet(), RememberedProfile.fields.toSet());
      expect(sent['gender'], 'male');
      expect(sent['goal'], 'maintainWeight');
      expect(sent['activity'], 'sedentary');
      expect(sent['height_cm'], 180.0);
    });

    test('a birthday goes up as a plain date, not a moment in time', () {
      final sent = RememberedProfile.of(UserEntity(
          birthday: DateTime(1988, 4, 2, 13, 45),
          heightCM: 178,
          weightKG: 82.4,
          gender: UserGenderEntity.male,
          goal: UserWeightGoalEntity.loseWeight,
          pal: UserPALEntity.active));
      expect(sent['birthday'], '1988-04-02');
    });

    test('and comes back as the same person', () {
      final back = RememberedProfile.from(RememberedProfile.of(him))!;
      expect(back.heightCM, him.heightCM);
      expect(back.weightKG, him.weightKG);
      expect(back.gender, him.gender);
      expect(back.goal, him.goal);
      expect(back.pal, him.pal);
      expect(back.age, him.age);
    });
  });

  group('a profile is all of it or none of it', () {
    test('nothing stored is nothing to use', () {
      expect(RememberedProfile.from(null), isNull);
    });

    for (final field in RememberedProfile.fields) {
      test('missing $field means the questions get asked', () {
        final holed = RememberedProfile.of(him)..remove(field);
        expect(RememberedProfile.from(holed), isNull,
            reason: 'five real numbers and one missing is the dangerous '
                'answer: setup would be skipped and the target worked out '
                'from what was there');
      });
    }

    test('an empty string counts as missing, not as an answer', () {
      final holed = RememberedProfile.of(him)..['gender'] = '';
      expect(RememberedProfile.from(holed), isNull);
    });

    test('a word this app does not know throws rather than guessing', () {
      final odd = RememberedProfile.of(him)..['activity'] = 'quiteActive';
      expect(() => RememberedProfile.from(odd), throwsFormatException,
          reason: 'defaulting to sedentary would skip setup AND get the '
              'answer wrong, which is the worst of both');
    });
  });

  group('coming back to a phone the app was just reinstalled on', () {
    late FakeHouseholdServer mini;
    late _PhoneProfile phone;
    late ProfileHandover handover;

    setUp(() {
      mini = FakeHouseholdServer();
      phone = _PhoneProfile();
      handover = ProfileHandover(
          HouseholdApi(baseUrl: 'http://mini', client: mini.client), phone);
    });

    test('the household knows him, so the questions never appear', () async {
      mini.profiles[mini.aidan] = RememberedProfile.of(him);

      expect(await handover.bringBack(mini.aidan), isTrue);
      expect(phone.held, isNotNull);
      expect(phone.held!.weightKG, him.weightKG);
    });

    test('the household has never been told, so they do appear', () async {
      expect(await handover.bringBack(mini.aidan), isFalse);
      expect(phone.held, isNull);
    });

    test('the household knows only half of him, so they appear', () async {
      mini.profiles[mini.aidan] = RememberedProfile.of(him)..remove('activity');

      expect(await handover.bringBack(mini.aidan), isFalse);
      expect(phone.held, isNull);
    });

    test('it knows the other one, not him', () async {
      mini.profiles[mini.emily] = RememberedProfile.of(him);

      expect(await handover.bringBack(mini.aidan), isFalse);
      expect(phone.held, isNull);
    });

    test('answers already on this phone are never written over', () async {
      phone.held = him;
      mini.profiles[mini.aidan] = RememberedProfile.of(
          UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight);

      expect(await handover.bringBack(mini.aidan), isFalse);
      expect(phone.held, same(him),
          reason: 'somebody who has just answered on this phone has said '
              'something more current than whatever the house last heard');
      expect(phone.writes, 0);
    });

    test('a kitchen computer that is asleep asks the questions rather than '
        'refusing to start', () async {
      final asleep = ProfileHandover(
          HouseholdApi(baseUrl: 'http://mini', client: mini.unreachable()),
          phone);

      expect(await asleep.bringBack(mini.aidan), isFalse);
      expect(phone.held, isNull);
    });
  });

  group('finishing setup tells the house', () {
    late FakeHouseholdServer mini;
    late ProfileHandover handover;

    setUp(() {
      mini = FakeHouseholdServer();
      handover = ProfileHandover(
          HouseholdApi(baseUrl: 'http://mini', client: mini.client),
          _PhoneProfile());
    });

    test('so the next reinstall does not ask again', () async {
      await handover.remember(mini.aidan, him);

      expect(mini.profilesPosted, hasLength(1));
      expect(mini.profileFor(mini.aidan), isNotNull);

      final freshPhone = _PhoneProfile();
      final afterReinstall = ProfileHandover(
          HouseholdApi(baseUrl: 'http://mini', client: mini.client), freshPhone);
      expect(await afterReinstall.bringBack(mini.aidan), isTrue);
      expect(freshPhone.held!.pal, him.pal);
    });

    test('and a sleeping kitchen computer does not fail the last page of a '
        'form somebody has just filled in', () async {
      final asleep = ProfileHandover(
          HouseholdApi(baseUrl: 'http://mini', client: mini.unreachable()),
          _PhoneProfile());

      await expectLater(asleep.remember(mini.aidan, him), completes);
    });
  });
}
