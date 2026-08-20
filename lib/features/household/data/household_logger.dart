import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

/// Putting something on somebody's day.
///
/// Everything the app logs to the household ledger comes through here, and the
/// reason it exists as its own small thing is a single line: the person it
/// counts against is worked out **at the moment of logging**, and travels with
/// the work from then on.
///
/// The alternative — deciding whose it is when the queue finally reaches the
/// server — looks identical until the phone changes hands. Then Monday's dinner,
/// still sitting in the queue on Tuesday morning, silently becomes the other
/// person's. That is the failure this class is shaped to prevent, and the test
/// at test/features/settings/change_device_owner_test.dart is what proves it.
class HouseholdLogger {
  final HouseholdRepository _repository;
  final Outbox _outbox;

  HouseholdLogger(this._repository, this._outbox);

  Future<int> _whoseDay() async {
    final owner = await _repository.storedOwner();
    if (owner == null) {
      throw StateError(
          'nobody has said whose phone this is, so there is no day to log to');
    }
    return owner;
  }

  /// One thing eaten. [author] defaults to the phone's owner — the usual case,
  /// one person logging their own food — and is passed explicitly when somebody
  /// logs for the other.
  Future<String> logFood({
    required String day,
    required String label,
    num? kcal,
    num? qty,
    String? unit,
    num? protein,
    num? fat,
    num? carbs,
    String? slot,
    int? foodId,
    int? mealId,
    int? owner,
    int? author,
    DateTime? at,
    /// The name this row already has on the phone.
    ///
    /// Passed in rather than minted here so that the phone's own diary row and
    /// the household's row share one name. That shared name is the only way
    /// the phone can ever say *which* row it means afterwards — it has no idea
    /// what number the kitchen computer gave it, and asking would mean a round
    /// trip at the exact moment the kitchen computer may be asleep.
    String? clientId,

    /// 'provisional' when the row is going on the day before anything has
    /// worked out what it is — somebody said it out loud and it is written
    /// down first. See SaidRepository.
    String state = 'settled',

    /// The words, verbatim, when they were spoken or typed as a sentence.
    String? said,

    /// What was taken for granted, in plain words.
    String? assumed,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      clientId: clientId,
      path: '/household/entry',
      body: {
        'day': day,
        'label': label,
        if (kcal != null) 'kcal': kcal,
        if (qty != null) 'qty': qty,
        if (unit != null) 'unit': unit,
        if (protein != null) 'protein': protein,
        if (fat != null) 'fat': fat,
        if (carbs != null) 'carbs': carbs,
        if (slot != null) 'slot': slot,
        if (foodId != null) 'food_id': foodId,
        if (mealId != null) 'meal_id': mealId,
        if (state != 'settled') 'state': state,
        if (said != null) 'said': said,
        if (assumed != null) 'assumed': assumed,
      },
      ownerId: owner ?? holder,
      authorId: author ?? holder,
      loggedAt: at,
    );
  }

  /// What happened to a planned meal: eaten, or not.
  ///
  /// One call, not two. The obvious shape — post an entry, then mark the plan
  /// settled — can half-succeed and leave the day showing a meal that is also
  /// still planned. The server makes the ledger row itself, so both happen or
  /// neither does.
  ///
  /// Queued like everything else, so tapping it on a train works and the meal
  /// lands when the phone gets home.
  Future<String> decidePlan({
    required int planId,
    required bool ate,
    int? owner,
    int? author,
    DateTime? at,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/plan/decide',
      body: {
        'plan_id': planId,
        'state': ate ? 'ate' : 'skipped',
      },
      ownerId: owner ?? holder,
      authorId: author ?? holder,
      loggedAt: at,
    );
  }

  /// Exercise, from the Watch or typed in. [source] says which, because a day
  /// that shows both needs to be able to tell them apart.
  Future<String> logExercise({
    required String day,
    required String source,
    required num kcal,
    num? minutes,
    String? note,
    int? owner,
    int? author,
    DateTime? at,
    String? clientId,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/exercise',
      clientId: clientId,
      body: {
        'day': day,
        'source': source,
        'kcal': kcal,
        if (minutes != null) 'minutes': minutes,
        if (note != null) 'note': note,
      },
      ownerId: owner ?? holder,
      authorId: author ?? holder,
      loggedAt: at,
    );
  }

  /// One weigh-in.
  ///
  /// [source] says where the number came from — `typed` if somebody stood on
  /// the scales and put it in, `health` if it was brought in from Apple
  /// Health. The server keeps both and decides which is the reading for the
  /// day; a typed one always wins.
  ///
  /// [clientId] is worth passing. Named after the day, the same day sent twice
  /// is a correction to that day rather than a second weigh-in on it, which is
  /// what makes bringing in an overlapping stretch of history safe.
  Future<String> logWeight({
    required String day,
    required num kg,
    String source = 'typed',
    String? clientId,
    int? owner,
    int? author,
    DateTime? at,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      clientId: clientId,
      path: '/household/weight',
      body: {'day': day, 'kg': kg, if (source != 'typed') 'source': source},
      ownerId: owner ?? holder,
      authorId: author ?? holder,
      loggedAt: at,
    );
  }

  /// Take something back off a day.
  ///
  /// Soft at the other end: the row and its numbers stay and stop counting, and
  /// if it was a planned meal being confirmed, the meal goes back to waiting
  /// for an answer. Queued like everything else, so deleting something on a
  /// train works.
  ///
  /// [entryClientId] is the name the phone gave the row when it logged it —
  /// see [logFood].
  Future<String> retireFood(String entryClientId) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/entry/by-client/$entryClientId/retire',
      body: const {},
      ownerId: holder,
      authorId: holder,
    );
  }

  /// Correct something already on a day — including moving it to the other
  /// person, which is [owner].
  ///
  /// One call, not two, for the same reason confirming a planned meal is one
  /// call: a move that landed without its figure would leave both people's
  /// totals wrong with nothing to say so.
  Future<String> amendFood(
    String entryClientId, {
    int? owner,
    String? label,
    num? kcal,
    num? qty,
    String? unit,
    num? protein,
    num? fat,
    num? carbs,
    String? slot,
    String? day,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/entry/by-client/$entryClientId/amend',
      body: {
        // Who made the correction. Recorded beside whoever entered the row
        // rather than replacing them.
        'author_id': holder,
        if (owner != null) 'owner_id': owner,
        if (label != null) 'label': label,
        if (kcal != null) 'kcal': kcal,
        if (qty != null) 'qty': qty,
        if (unit != null) 'unit': unit,
        if (protein != null) 'protein': protein,
        if (fat != null) 'fat': fat,
        if (carbs != null) 'carbs': carbs,
        if (slot != null) 'slot': slot,
        if (day != null) 'day': day,
      },
      ownerId: owner ?? holder,
      authorId: holder,
    );
  }

  /// A new food for the household list. It belongs to the house rather than to
  /// a day, but it goes through the same queue so it is not lost when the Mini
  /// is unreachable.
  Future<String> addFood({
    required String name,
    required String trust,
    String source = 'manual',
    String? brand,
    String? barcode,
    num? kcal100,
    num? protein100,
    num? fat100,
    num? carbs100,
    num? packGrams,
    int? perPack,
    num? servingG,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/food',
      body: {
        'name': name,
        'trust': trust,
        'source': source,
        if (brand != null) 'brand': brand,
        if (barcode != null) 'barcode': barcode,
        if (kcal100 != null) 'kcal_100': kcal100,
        if (protein100 != null) 'protein_100': protein100,
        if (fat100 != null) 'fat_100': fat100,
        if (carbs100 != null) 'carbs_100': carbs100,
        if (packGrams != null) 'pack_grams': packGrams,
        if (perPack != null) 'per_pack': perPack,
        if (servingG != null) 'serving_g': servingG,
        'created_by': holder,
      },
      ownerId: holder,
      authorId: holder,
    );
  }
}
