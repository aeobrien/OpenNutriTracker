import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/label_captures.dart';

part 'label_capture_dao.g.dart';

/// Storage for a capture in progress. Thin on purpose — the order of the shots
/// and what counts as finished are decided in one place, in GuidedCapture.
@DriftAccessor(tables: [LabelCaptures])
class LabelCaptureDao extends DatabaseAccessor<AppDatabase>
    with _$LabelCaptureDaoMixin {
  LabelCaptureDao(super.db);

  /// Record a shot as taken. Retaking one replaces it rather than adding a
  /// second, so a blurry photograph can simply be taken again.
  Future<void> record(LabelCapturesCompanion shot) async {
    await into(labelCaptures).insert(shot, mode: InsertMode.insertOrReplace);
  }

  Future<List<LabelCapture>> shotsFor(String captureId) {
    return (select(labelCaptures)
          ..where((t) => t.captureId.equals(captureId))
          ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
        .get();
  }

  /// Any capture with shots waiting — what an interrupted flow leaves behind.
  Future<List<LabelCapture>> unfinished() {
    return (select(labelCaptures)
          ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
        .get();
  }

  /// Called when a capture has been confirmed and saved, or deliberately
  /// abandoned. Not called on interruption — that is the whole point.
  Future<void> clear(String captureId) async {
    await (delete(labelCaptures)..where((t) => t.captureId.equals(captureId)))
        .go();
  }
}
