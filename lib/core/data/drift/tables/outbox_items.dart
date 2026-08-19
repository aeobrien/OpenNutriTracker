import 'package:drift/drift.dart';

/// Work the phone has done that the Mac Mini has not yet acknowledged.
///
/// There is exactly one of these queues in the app, and everything that writes
/// to the household server goes through it — meals, exercise, weights, new
/// foods. A second queue somewhere else would mean two answers to "have we sent
/// that yet", and the moment they disagree an entry is either lost or logged
/// twice.
///
/// Three columns carry more weight than they look like they do:
///
///  * [clientId] is minted once, on the phone, when the person taps. The server
///    stores it, so sending the same item again is harmless — which is what
///    lets the phone retry without ever having to know whether the last attempt
///    arrived.
///  * [ownerId] and [authorId] are decided when the work is logged, not when it
///    is sent. If they were resolved at send time, handing the phone over on
///    Tuesday would silently move Monday's dinner onto the other person.
///  * [loggedAt] is likewise the moment it happened, not the moment it left.
class OutboxItems extends Table {
  TextColumn get clientId => text()();
  TextColumn get path => text()();
  TextColumn get body => text()();
  IntColumn get ownerId => integer()();
  IntColumn get authorId => integer()();
  IntColumn get loggedAt => integer()();
  IntColumn get queuedAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientId};
}
