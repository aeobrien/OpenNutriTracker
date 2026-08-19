/// The three photographs a packet needs, in the order they are asked for.
///
/// The order is not decoration. The front identifies the product, the nutrition
/// panel carries the numbers, and the ingredients settle what it actually is —
/// and a person holding a packet turns it over once, so asking in that order is
/// asking for one turn rather than three.
enum LabelShot {
  front,
  nutrition,
  ingredients;

  /// What the person is asked to point the camera at.
  String get instruction {
    switch (this) {
      case LabelShot.front:
        return 'Photograph the front of the packet';
      case LabelShot.nutrition:
        return 'Now the nutrition panel';
      case LabelShot.ingredients:
        return 'And the ingredients';
    }
  }

  /// The name this shot is stored and sent under.
  String get key => name;

  static LabelShot fromKey(String key) =>
      LabelShot.values.firstWhere((s) => s.name == key);
}

/// A photograph that has been taken, and where it is.
class CapturedShot {
  final LabelShot shot;

  /// A file inside the app's own storage. Never the system photo library.
  final String path;

  final DateTime takenAt;

  const CapturedShot({
    required this.shot,
    required this.path,
    required this.takenAt,
  });
}
