import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';

/// Taking one photograph.
///
/// An interface, so the guided flow can be run and interrupted in a test where
/// there is no camera. The real implementation writes into the directory it is
/// given — which is inside the app's own storage — and nowhere else.
abstract class LabelCamera {
  /// Take [shot], writing the image into [intoDirectory]. Returns null when the
  /// person backed out of the camera without taking it.
  Future<String?> take(LabelShot shot, {required String intoDirectory});
}
