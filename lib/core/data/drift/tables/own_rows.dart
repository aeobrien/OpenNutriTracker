import 'package:drift/drift.dart';

/// The names this phone has given to things it did.
///
/// Every write the phone makes to the household mints a client id, and that id
/// is the name the row keeps at the house. Rows come back down again later
/// through the pull, by which time nothing about them says where they started —
/// a sentence this phone spoke and a sentence somebody spoke at the kitchen
/// panel arrive down the same pipe, in the same shape.
///
/// So the phone writes down what it did, at the moment it did it. That is the
/// only record that can answer "was this mine?" without asking the house, and
/// asking the house is exactly what is unavailable at the moment it matters —
/// a snackbar deciding whether to offer Undo cannot wait for a round trip.
///
/// Kept for thirty days and then pruned. The question is only ever asked about
/// rows on a day somebody is looking at, and a month is far past the point
/// where undoing something is a thing anyone would do.
class OwnRows extends Table {
  /// The client id this phone minted. For a spoken sentence that became
  /// several foods, the house names the extras by adding `#2`, `#3` and so on
  /// to this one — so a lookup matches on the part before the `#`.
  TextColumn get clientId => text()();

  /// When this phone did it, so old ones can be cleared out.
  IntColumn get mintedAt => integer()();

  @override
  Set<Column> get primaryKey => {clientId};
}
