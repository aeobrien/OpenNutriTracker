import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';

/// Reading and changing the household's plan from the phone.
///
/// There is one plan and it lives on the Mac Mini. This writes into
/// the same table the panel already reads, through the same endpoint the panel
/// itself would use — not a second plan the phone keeps and reconciles later.
///
/// **Nothing here is queued, on purpose.** Every other write on this phone —
/// logging a food, correcting a figure, answering a planned meal — goes on the
/// outbox and is delivered whenever the house is reachable, because those are
/// records of something that already happened and losing them loses the truth.
/// Putting a meal on next Tuesday is not that. It is a decision being made
/// right now, in front of a screen showing what is already there, and a
/// decision made against a week you cannot currently see is a decision made
/// blind. So the planner is simply unavailable when the Mac Mini
/// cannot be reached, and says so — rather than accepting taps into a queue
/// and letting somebody plan a meal on top of one they did not know about.
class PlanRepository {
  final HouseholdApi _api;
  final HouseholdRepository _household;

  PlanRepository(this._api, this._household);

  /// The household's planned week. [start] names the Monday; leaving it off
  /// lets the Mac Mini decide which week today is in, so the two
  /// handsets and the panel cannot disagree about where a week starts.
  Future<PlanWeek> week({String? start}) async =>
      PlanWeek.fromJson(await _api.plan(start: start));

  /// The house's own meals, for the picker. [q] narrows by name.
  Future<List<MealChoice>> meals({String? q}) async {
    final rows = await _api.meals(q: q);
    return [for (final row in rows) MealChoice.fromJson(row)];
  }

  /// Put one of the house's meals on a day. Returns its new plan id.
  ///
  /// Who did it is recorded from whoever the app says this phone belongs to,
  /// not from the handset — a phone can be handed over, and the plan should
  /// name the person who made the decision.
  Future<int> add({required String day, required int mealId}) async {
    return _api.planAdd(
      date: day,
      mealId: mealId,
      actor: await _actor(),
    );
  }

  /// Put something on a day that is not one of the house's meals — a takeaway,
  /// a meal out, "at Mum's".
  ///
  /// It gets no calories and no shopping lines, and that is correct rather
  /// than a shortcoming: the week counts what it can stand behind and reports
  /// the rest as awaiting, so a night out shows up as a night out instead of
  /// quietly reading as a day with no dinner.
  Future<int> addByName({required String day, required String title}) async {
    return _api.planAdd(date: day, title: title, actor: await _actor());
  }

  /// Take one meal off the plan.
  Future<void> remove(int planId) => _api.planRemove(planId);

  Future<String?> _actor() async {
    final owner = await _household.storedOwner();
    if (owner == null) return null;
    final people = await _household.cachedPeople();
    for (final person in people) {
      if (person.id == owner) return person.name;
    }
    return null;
  }
}
