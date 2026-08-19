import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/domain/weight_record.dart';

/// Who this handset belongs to, and what that person's settings are.
///
/// The phone stores the answer so it does not have to ask the person again, and
/// the *server* is told, so that the server can answer "whose phone is this"
/// from its own records rather than trusting whatever the phone sends with each
/// request. Those are two separate facts kept deliberately in step: the local
/// copy is a convenience, the server's copy is the truth.
class HouseholdRepository {
  static const _deviceIdKey = 'householdDeviceId';
  static const _ownerKey = 'householdOwnerPersonId';
  static const _settingsKeyPrefix = 'householdSettings_';

  final ConfigDao _config;
  final HouseholdApi _api;
  final _log = Logger('HouseholdRepository');

  HouseholdRepository(this._config, this._api);

  /// This handset's own id, minted once and then kept for good. Two phones must
  /// never share one, or the server cannot tell them apart.
  Future<String> deviceId() async {
    final existing = await _config.getValue(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final minted = IdGenerator.getUniqueID();
    await _config.setValue(_deviceIdKey, minted);
    _log.info('[HOUSE] minted device id $minted');
    return minted;
  }

  /// Null until somebody has said who this phone belongs to. The onboarding
  /// flow asks exactly when this is null, which is what makes a fresh install
  /// prompt and a returning one not.
  Future<int?> storedOwner() async {
    final raw = await _config.getValue(_ownerKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<bool> needsOwnerPrompt() async => (await storedOwner()) == null;

  Future<List<HouseholdPerson>> people() => _api.people();

  /// Say who this phone belongs to — on first run, or later when it changes
  /// hands.
  ///
  /// The server is told first. If it cannot be told, nothing is stored locally
  /// either: a phone that believes it belongs to Emily while the server still
  /// thinks Aidan is the one situation this whole arrangement exists to avoid.
  Future<void> setOwner(int personId) async {
    final id = await deviceId();
    await _api.registerDevice(id, personId);
    await _config.setValue(_ownerKey, personId.toString());
    _log.info('[HOUSE] this phone now belongs to person $personId');
  }

  /// Whose phone the server says this is. Used to check the two copies agree.
  Future<int> ownerAccordingToServer() async {
    return _api.deviceOwner(await deviceId());
  }

  /// True when the phone and the server give the same answer.
  Future<bool> ownerAgrees() async {
    final local = await storedOwner();
    if (local == null) return false;
    return (await ownerAccordingToServer()) == local;
  }

  // --- settings ---------------------------------------------------------

  String _settingsKey(int personId) => '$_settingsKeyPrefix$personId';

  /// One person's settings, from the server, kept locally so the app still
  /// knows the target when the Mini is unreachable.
  Future<PersonSettings> settings(int personId) async {
    try {
      final fresh = await _api.settings(personId);
      await _cache(fresh);
      return fresh;
    } on HouseholdUnreachable {
      return cachedSettings(personId);
    }
  }

  Future<PersonSettings> cachedSettings(int personId) async {
    final raw = await _config.getValue(_settingsKey(personId));
    if (raw == null) return PersonSettings(personId: personId);
    return PersonSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _cache(PersonSettings s) async {
    await _config.setValue(
        _settingsKey(s.personId),
        jsonEncode({
          'person_id': s.personId,
          'daily_target_kcal': s.dailyTargetKcal,
          'weight_tracking_on': s.weightTrackingOn ? 1 : 0,
          'figures_off': s.figuresOff ? 1 : 0,
        }));
  }

  // --- weights ----------------------------------------------------------

  /// Everything this person has weighed in at, oldest first.
  ///
  /// Asked for without consulting the weight-tracking switch on purpose. The
  /// switch belongs to the screen — it decides whether the weight tab is shown.
  /// If this method filtered on it, turning the switch off would look exactly
  /// like the history having been thrown away, and the difference between those
  /// two is the whole promise.
  Future<List<WeightRecord>> weights(int personId) async {
    final rows = await _api.weights(personId);
    return rows.map(WeightRecord.fromJson).toList();
  }

  /// Change one person's settings. Keyed on the person throughout — there is no
  /// call here that could touch anybody else's.
  Future<PersonSettings> updateSettings(
    int personId, {
    int? dailyTargetKcal,
    bool? weightTrackingOn,
    bool? figuresOff,
  }) async {
    final changes = <String, dynamic>{
      if (dailyTargetKcal != null) 'daily_target_kcal': dailyTargetKcal,
      if (weightTrackingOn != null) 'weight_tracking_on': weightTrackingOn,
      if (figuresOff != null) 'figures_off': figuresOff,
    };
    final updated = await _api.updateSettings(personId, changes);
    await _cache(updated);
    return updated;
  }
}
