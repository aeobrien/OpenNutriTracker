/// What came back from asking the Mac Mini to work out a sentence.
///
/// Deliberately not "success or failure". Three of the four things below can be
/// true at once — the sentence was heard, it was not understood, and there is
/// one question that would help — and collapsing them into a boolean is how a
/// row ends up either silently wrong or silently gone.
library;

class Understood {
  /// Whether the row on the day was actually changed. False is normal and not
  /// an error: the sentence may not have been understood, or the person may
  /// have corrected the row themselves while this was in flight, in which case
  /// their hand wins and this answer is thrown away.
  final bool applied;

  /// Why not, in the server's own plain words, when [applied] is false.
  final String? why;

  /// The words, as they were finally heard. Worth keeping even when nothing
  /// was understood — it is what the row shows, and what the person reads to
  /// see whether they were misheard or misunderstood.
  final String said;

  /// The one thing worth asking, or null. At most one, ever: being asked four
  /// questions about a sandwich is how a fast thing becomes a slow one.
  final String? question;

  const Understood({
    required this.applied,
    required this.said,
    this.why,
    this.question,
  });

  factory Understood.fromJson(Map<String, dynamic> json) => Understood(
        applied: (json['applied'] as bool?) ?? false,
        why: json['why'] as String?,
        said: (json['said'] as String?) ?? '',
        question: json['question'] as String?,
      );
}
