/// The shopping list, as somebody standing in a shop reads it.
library;

/// One planned meal that put a line on the list.
class PutItThere {
  final String title;
  final String day;

  const PutItThere({required this.title, required this.day});

  factory PutItThere.fromJson(Map<String, dynamic> json) => PutItThere(
        title: json['title'] as String? ?? '',
        day: json['day'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'title': title, 'day': day};
}

/// One line: a thing to buy, at the total the week needs.
///
/// The total is folded on the Mac Mini at the moment the list is compiled, and
/// nothing here adds anything up. Two meals wanting 200g and 300g of chicken
/// are one line of 500g before it ever reaches a phone.
class ShoppingLine {
  final int id;
  final String text;
  final bool done;

  /// Which planned meals put it there, in the order the week has them. Empty
  /// for a line somebody typed themselves, which is the honest answer rather
  /// than a guess at which dinner they must have meant.
  final List<PutItThere> putItThere;

  const ShoppingLine({
    required this.id,
    required this.text,
    this.done = false,
    this.putItThere = const [],
  });

  factory ShoppingLine.fromJson(Map<String, dynamic> json) => ShoppingLine(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        // The house stores this as 0 or 1; a phone reads a tick.
        done: (json['done'] as num? ?? 0) != 0,
        putItThere: [
          for (final one in (json['from_meals'] as List? ?? const []))
            PutItThere.fromJson((one as Map).cast<String, dynamic>()),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done ? 1 : 0,
        'from_meals': [for (final one in putItThere) one.toJson()],
      };

  ShoppingLine ticked(bool now) => ShoppingLine(
      id: id, text: text, done: now, putItThere: putItThere);

  /// Whether anything on the plan is responsible for this line.
  bool get isFromThePlan => putItThere.isNotEmpty;
}
