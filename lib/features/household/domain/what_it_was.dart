/// What a logged row said before somebody changed it.
///
/// Release 7, TM-0023 / BC-0024. The card asks for a correction that can be
/// looked at afterwards, and the reason it needs this rather than a "last
/// edited" stamp is in the card's own words: a correction is only safe to
/// make if the thing it replaced is still readable. "I did not eat that" is
/// itself sometimes a mistake.
library;

/// One version a row used to be.
///
/// The whole row as it stood, not a list of what changed. A list of changes
/// has to be replayed to be understood and cannot survive a field being added
/// later; a whole row reads on its own, forever.
class WhatItWas {
  /// The version this snapshot *was* — so 3 means "before the change that
  /// made it version 4".
  final int version;

  /// 'corrected', 'taken off', or 'put back'. The house's own words, shown
  /// unchanged rather than translated, because they are already plain.
  final String what;

  /// Who made the change, when the house knows. Null for a removal, which
  /// nobody signs.
  final int? changedBy;

  final DateTime? changedAt;

  /// The whole row, as it stood.
  final Map<String, dynamic> snapshot;

  /// Exactly the fields to send back to put this version back.
  ///
  /// Worked out on the Mac Mini, not here, and that is deliberate: which
  /// fields a correction may touch is the house's rule, and a phone that kept
  /// its own copy of the list would go quietly wrong the day the list changed.
  final Map<String, dynamic> putBack;

  const WhatItWas({
    required this.version,
    required this.what,
    this.changedBy,
    this.changedAt,
    this.snapshot = const {},
    this.putBack = const {},
  });

  factory WhatItWas.fromJson(Map<String, dynamic> json) => WhatItWas(
        version: (json['version'] as num?)?.toInt() ?? 0,
        what: json['what'] as String? ?? '',
        changedBy: (json['changed_by'] as num?)?.toInt(),
        changedAt: DateTime.tryParse(json['changed_at'] as String? ?? ''),
        snapshot: ((json['snapshot'] as Map?) ?? const {})
            .cast<String, dynamic>(),
        putBack:
            ((json['put_back'] as Map?) ?? const {}).cast<String, dynamic>(),
      );

  /// What it was called at the time. The one field a person recognises a
  /// version by, which is why it is lifted out of the snapshot.
  String get label => snapshot['label'] as String? ?? '';

  /// The amount, with its unit, as one readable piece: "125 g".
  ///
  /// Empty when the row never had an amount — a quick-added calorie figure
  /// has none, and "0 " in front of somebody would be a lie about the row
  /// rather than a gap in it.
  String get amount {
    final qty = snapshot['qty'] as num?;
    if (qty == null) return '';
    final unit = snapshot['unit'] as String? ?? '';
    final rounded = qty == qty.roundToDouble()
        ? qty.round().toString()
        : qty.toStringAsFixed(1);
    return unit.isEmpty ? rounded : '$rounded $unit';
  }

  /// The calorie figure it carried, rounded the way a day is read.
  int? get kcal => (snapshot['kcal'] as num?)?.round();

  /// Whose day it counted against at the time. This is what makes a move
  /// visible in the history rather than silent.
  int? get owner => (snapshot['owner_id'] as num?)?.toInt();

  /// One line describing this version, without any of the words a screen
  /// would add around it.
  ///
  /// Written here rather than in the widget so a test can read it, and so the
  /// panel and anything else that ever shows a version say the same thing.
  String get line {
    final parts = <String>[
      if (label.isNotEmpty) label,
      if (amount.isNotEmpty) amount,
      if (kcal != null) '$kcal kcal',
    ];
    return parts.isEmpty ? 'an entry with nothing on it' : parts.join(', ');
  }

  /// Whether putting this version back would move the row to somebody else.
  ///
  /// Worth saying out loud on the screen: restoring a version that was on the
  /// other person's day takes the row off this one's, and a person pressing
  /// "put this back" is thinking about the amount, not about whose day it is.
  bool movesItTo(int? currentOwner) =>
      owner != null && currentOwner != null && owner != currentOwner;

  /// The amount to put back, in the units the row carried.
  num? get putBackAmount => putBack['qty'] as num?;

  /// The name to put back.
  String? get putBackLabel => putBack['label'] as String?;

  /// The calorie figure to put back.
  num? get putBackKcal => putBack['kcal'] as num?;

  /// Whose day to put it back on, or null to leave it where it is.
  ///
  /// Null when the version was on the same person's day it is on now — the
  /// restore is then not a move, and saying "move it to whoever already has
  /// it" would write a change nobody asked for.
  int? putBackOwner(int? currentOwner) => movesItTo(currentOwner) ? owner : null;

  /// Everything one row has been, newest first, out of the server's answer.
  static List<WhatItWas> allOf(Map<String, dynamic> body) => [
        for (final one in (body['history'] as List? ?? const []))
          WhatItWas.fromJson((one as Map).cast<String, dynamic>()),
      ];
}
