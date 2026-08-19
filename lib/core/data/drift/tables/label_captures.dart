import 'package:drift/drift.dart';

/// Photographs already taken of a packet, for a capture that has not finished.
///
/// This table exists for one reason: the capture is three photographs taken one
/// after another, and life interrupts it. A phone call, a locked screen, a
/// toddler — and the person comes back to find they have to photograph the
/// packet again from the front. Because the shots are written here as they are
/// taken rather than held in memory until the end, coming back resumes at the
/// shot that was next.
///
/// Nothing here is a food. A capture sitting in this table has produced no
/// entry in the household food list and never will on its own: the list is only
/// written after somebody has looked at the numbers and confirmed them. That is
/// why the paths live here and not on a half-made food record.
class LabelCaptures extends Table {
  /// The capture this shot belongs to. One capture, one packet.
  TextColumn get captureId => text()();

  /// Which of the three: 'front', 'nutrition', 'ingredients'.
  TextColumn get shot => text()();

  /// Where the photograph is, inside the app's own storage. Never the system
  /// photo library — a picture of the back of a cereal box is not a memory and
  /// does not belong in somebody's camera roll.
  TextColumn get path => text()();

  IntColumn get takenAt => integer()();

  @override
  Set<Column> get primaryKey => {captureId, shot};
}
