import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/label_capture_dao.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/label_scan/data/label_camera.dart';
import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';

/// Photographing a packet, three shots in order, survivable.
///
/// The app drives the camera rather than the person driving it: it asks for the
/// front, then the nutrition panel, then the ingredients, and it knows which one
/// is next. That is what makes the whole thing one action instead of three
/// separate photographs somebody has to remember the purpose of.
///
/// The part that matters most is the least visible. Each photograph is written
/// down as it is taken, so an interruption — a call, a locked screen, the app
/// being killed — costs the shot in progress and nothing else. Coming back
/// resumes at the next shot rather than starting again from the front. This was
/// the piece the plan review proposed cutting, and it is the piece that decides
/// whether anybody actually fills the food list in as they go: a flow that makes
/// you start over after one interruption is a flow you stop using.
///
/// Nothing here writes a food. A capture — finished or not — produces
/// photographs and nothing else; the household food list is only written after
/// somebody has seen the numbers and confirmed them. That is a property of this
/// class having no way to reach the food list at all, rather than a rule it
/// remembers to follow.
class GuidedCapture {
  final LabelCaptureDao _dao;
  final LabelCamera _camera;

  /// Where photographs are written — the app's own storage, passed in so the
  /// caller decides and this class cannot quietly choose the camera roll.
  final String directory;

  final _log = Logger('GuidedCapture');

  GuidedCapture(this._dao, this._camera, {required this.directory});

  factory GuidedCapture.of(AppDatabase db, LabelCamera camera,
          {required String directory}) =>
      GuidedCapture(LabelCaptureDao(db), camera, directory: directory);

  /// Start photographing a new packet. Returns the id of the capture, which is
  /// how it is picked up again if it is interrupted.
  String start() => IdGenerator.getUniqueID();

  /// The shots already taken for [captureId], in the order they were taken.
  Future<List<CapturedShot>> taken(String captureId) async {
    final rows = await _dao.shotsFor(captureId);
    return rows
        .map((r) => CapturedShot(
              shot: LabelShot.fromKey(r.shot),
              path: r.path,
              takenAt: DateTime.fromMillisecondsSinceEpoch(r.takenAt),
            ))
        .toList();
  }

  /// Which photograph is wanted next, or null when all three are done.
  Future<LabelShot?> nextShot(String captureId) async {
    final done = (await taken(captureId)).map((s) => s.shot).toSet();
    for (final shot in LabelShot.values) {
      if (!done.contains(shot)) return shot;
    }
    return null;
  }

  Future<bool> isComplete(String captureId) async =>
      (await nextShot(captureId)) == null;

  /// Take whichever photograph is next. Returns it, or null if the person
  /// backed out or there is nothing left to take.
  ///
  /// Written down before it returns, which is what makes the next call after an
  /// interruption pick up where this one left off.
  Future<CapturedShot?> takeNext(String captureId) async {
    final shot = await nextShot(captureId);
    if (shot == null) return null;
    final path = await _camera.take(shot, intoDirectory: directory);
    if (path == null) {
      _log.info('[CAPTURE] $captureId: backed out of ${shot.key}');
      return null;
    }
    final takenAt = DateTime.now();
    await _dao.record(LabelCapturesCompanion(
      captureId: Value(captureId),
      shot: Value(shot.key),
      path: Value(path),
      takenAt: Value(takenAt.millisecondsSinceEpoch),
    ));
    _log.info('[CAPTURE] $captureId: kept ${shot.key}');
    return CapturedShot(shot: shot, path: path, takenAt: takenAt);
  }

  /// Take one shot again — the blurry-photograph case. Replaces what was there
  /// rather than adding a fourth image, so a retake cannot leave two versions
  /// of the nutrition panel to choose between.
  Future<CapturedShot?> retake(String captureId, LabelShot shot) async {
    final path = await _camera.take(shot, intoDirectory: directory);
    if (path == null) return null;
    final takenAt = DateTime.now();
    await _dao.record(LabelCapturesCompanion(
      captureId: Value(captureId),
      shot: Value(shot.key),
      path: Value(path),
      takenAt: Value(takenAt.millisecondsSinceEpoch),
    ));
    _log.info('[CAPTURE] $captureId: retook ${shot.key}');
    return CapturedShot(shot: shot, path: path, takenAt: takenAt);
  }

  /// A capture that was left part-done, if there is one. This is what an
  /// interrupted flow is offered on the way back in.
  Future<String?> unfinishedCapture() async {
    final rows = await _dao.unfinished();
    if (rows.isEmpty) return null;
    final captureId = rows.first.captureId;
    return (await isComplete(captureId)) ? null : captureId;
  }

  /// The three photographs, ready to be read. Null while any is missing —
  /// a partial capture is not a packet and must not be sent as one.
  Future<Map<String, String>?> shotsForReading(String captureId) async {
    if (!await isComplete(captureId)) return null;
    return {
      for (final s in await taken(captureId)) s.shot.key: s.path,
    };
  }

  /// Throw a capture away. Called when it has been saved, or when the person
  /// says they are done with it — never on an interruption.
  Future<void> discard(String captureId) => _dao.clear(captureId);
}
