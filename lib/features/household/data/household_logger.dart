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
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
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

  Future<String> logWeight({
    required String day,
    required num kg,
    int? owner,
    int? author,
    DateTime? at,
  }) async {
    final holder = await _whoseDay();
    return _outbox.enqueue(
      path: '/household/weight',
      body: {'day': day, 'kg': kg},
      ownerId: owner ?? holder,
      authorId: author ?? holder,
      loggedAt: at,
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
