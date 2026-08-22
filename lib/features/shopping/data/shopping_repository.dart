/// The shopping list, and the fact that it is read in a shop.
///
/// Release 6, TM-0022 / BC-0023. Everything here is shaped by one observation
/// in the card: the list is read standing in a supermarket, which is a place
/// with famously bad signal and a trolley in one hand.
///
/// So:
///
///   * **The list is kept on the phone.** Every successful read writes it down,
///     and a read that cannot reach the Mac Mini answers with what was written
///     down last rather than an error. A shopping list that needs a network is
///     a shopping list that is not there when it is needed.
///   * **A tick lands immediately and is sent later.** It changes the kept copy
///     first and goes into the one outbox, so ticking works in an aisle and
///     arrives at the house whenever the phone next has signal.
///   * **Making the list needs the server, and says so.** Compiling reads the
///     whole plan and every meal behind it; there is no honest way to do that
///     from a phone, and queuing it would mean pressing a button and finding
///     out much later that the week it compiled was not the week you meant.
library;

import 'dart:convert';

import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/shopping/domain/shopping_line.dart';

/// What compiling the plan did, so it can be said out loud.
class ListMade {
  final int added;
  final int removed;
  final int meals;
  final List<ShoppingLine> list;

  const ListMade({
    this.added = 0,
    this.removed = 0,
    this.meals = 0,
    this.list = const [],
  });
}

class ShoppingRepository {
  static const _key = 'household_shopping_list';

  final HouseholdApi _api;
  final HouseholdRepository _household;
  final ConfigDao _config;
  final Outbox _outbox;

  ShoppingRepository(this._api, this._household, this._config, this._outbox);

  /// The list. From the house when it can be reached, from the phone's own
  /// copy when it cannot.
  Future<List<ShoppingLine>> list() async {
    try {
      final body = await _api.shopping();
      final fresh = _read(body['shopping']);
      await _keep(fresh);
      return fresh;
    } on HouseholdUnreachable {
      return kept();
    }
  }

  /// What the phone wrote down last. This is what a shop sees.
  Future<List<ShoppingLine>> kept() async {
    final raw = await _config.getValue(_key);
    if (raw == null) return const [];
    return _read(jsonDecode(raw));
  }

  /// Tick a line off, or put it back.
  ///
  /// The kept copy changes first and the house is told through the outbox, so
  /// the tick is on the screen before anything leaves the phone. Which state
  /// is wanted is sent rather than "the other one" — a toggle that arrives
  /// twenty minutes late flips whatever it finds instead of what was tapped.
  Future<List<ShoppingLine>> tick(int id, bool done) async {
    final now = [
      for (final line in await kept())
        if (line.id == id) line.ticked(done) else line,
    ];
    await _keep(now);
    final who = await _household.storedOwner();
    if (who != null) {
      await _outbox.enqueue(
        path: '/household/shopping/$id/tick',
        body: {'done': done},
        ownerId: who,
        authorId: who,
      );
    }
    return now;
  }

  /// Take a line off the list entirely.
  Future<List<ShoppingLine>> remove(int id) async {
    final now = [
      for (final line in await kept())
        if (line.id != id) line,
    ];
    await _keep(now);
    final who = await _household.storedOwner();
    if (who != null) {
      await _outbox.enqueue(
        path: '/household/shopping/$id/remove',
        body: const {},
        ownerId: who,
        authorId: who,
      );
    }
    return now;
  }

  /// Turn the plan into the shopping list. Needs the server, and throws
  /// [HouseholdUnreachable] rather than queuing when it has not got one.
  Future<ListMade> make({String? start, String? end}) async {
    final body = await _api.shoppingMake(start: start, end: end);
    final made = _read(body['shopping']);
    await _keep(made);
    return ListMade(
      added: (body['added'] as num? ?? 0).toInt(),
      removed: (body['removed'] as num? ?? 0).toInt(),
      meals: (body['meals'] as num? ?? 0).toInt(),
      list: made,
    );
  }

  List<ShoppingLine> _read(dynamic raw) => [
        for (final line in (raw as List? ?? const []))
          ShoppingLine.fromJson((line as Map).cast<String, dynamic>()),
      ];

  Future<void> _keep(List<ShoppingLine> lines) => _config.setValue(
      _key, jsonEncode([for (final line in lines) line.toJson()]));
}
