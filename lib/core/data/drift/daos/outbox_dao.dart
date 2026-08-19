import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/outbox_items.dart';

part 'outbox_dao.g.dart';

/// Storage for the one outbound queue. Deliberately thin: the deciding — what
/// to send, when to give up, what counts as sent — lives in [Outbox], so there
/// is one place holding the rules rather than some here and some there.
@DriftAccessor(tables: [OutboxItems])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  /// Add work to the queue. Re-adding something already queued (a double tap,
  /// a retried enqueue) leaves the original in place rather than making a
  /// second copy — the client id is the identity of the work.
  Future<void> add(OutboxItemsCompanion item) async {
    await into(outboxItems).insert(item, mode: InsertMode.insertOrIgnore);
  }

  /// Oldest first, so things reach the server in the order they happened.
  Future<List<OutboxItem>> pending({int limit = 100}) {
    return (select(outboxItems)
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> count() async {
    final rows = await select(outboxItems).get();
    return rows.length;
  }

  Future<OutboxItem?> byClientId(String clientId) {
    return (select(outboxItems)..where((t) => t.clientId.equals(clientId)))
        .getSingleOrNull();
  }

  /// Called only once the server has confirmed it. Anything else leaves the row
  /// where it is, to be tried again.
  Future<void> remove(String clientId) async {
    await (delete(outboxItems)..where((t) => t.clientId.equals(clientId))).go();
  }

  Future<void> recordFailure(String clientId, String error) async {
    final row = await byClientId(clientId);
    if (row == null) return;
    await (update(outboxItems)..where((t) => t.clientId.equals(clientId)))
        .write(OutboxItemsCompanion(
      attempts: Value(row.attempts + 1),
      lastError: Value(error),
    ));
  }
}
