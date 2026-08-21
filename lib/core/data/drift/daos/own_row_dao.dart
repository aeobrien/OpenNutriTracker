import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/own_rows.dart';

part 'own_row_dao.g.dart';

/// Storage for what this phone did. See [OwnRows] for why it exists.
@DriftAccessor(tables: [OwnRows])
class OwnRowDao extends DatabaseAccessor<AppDatabase> with _$OwnRowDaoMixin {
  OwnRowDao(super.db);

  /// How long a name is kept before it is forgotten.
  static const keepFor = Duration(days: 30);

  /// Write down that this phone minted this name.
  ///
  /// Re-recording the same name is not an error — a retried enqueue is the
  /// same action, not a second one.
  Future<void> remember(String clientId, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    await into(ownRows).insert(
      OwnRowsCompanion.insert(
        clientId: clientId,
        mintedAt: when.millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Did this phone do the thing the house calls [householdName]?
  ///
  /// The house names the second and later foods out of one spoken sentence by
  /// adding `#2` to the name the phone gave it, so the part before the `#` is
  /// what identifies the action.
  Future<bool> didThisPhoneMint(String householdName) async {
    final root = householdName.split('#').first;
    final row = await (select(ownRows)..where((t) => t.clientId.equals(root)))
        .getSingleOrNull();
    return row != null;
  }

  /// Forget names older than [keepFor]. Returns how many were dropped.
  Future<int> forgetOldOnes({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(keepFor);
    return (delete(ownRows)
          ..where((t) => t.mintedAt.isSmallerThanValue(
              cutoff.millisecondsSinceEpoch)))
        .go();
  }
}
