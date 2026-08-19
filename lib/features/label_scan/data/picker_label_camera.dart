import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/features/label_scan/data/label_camera.dart';
import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';
import 'package:path/path.dart' as p;

/// The real camera behind the guided capture.
///
/// Two things it deliberately does not do. It never opens the photo library —
/// [ImageSource.camera] only, because the promise is that the app drives the
/// camera through three shots, and picking three old pictures out of a gallery
/// is a different thing. And it never leaves the image where the picker put it:
/// the file is copied into the directory the flow was given, which is inside
/// the app's own storage, so a half-finished capture survives without anything
/// of the person's ending up in a shared folder.
class PickerLabelCamera implements LabelCamera {
  final ImagePicker _picker;

  PickerLabelCamera({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<String?> take(LabelShot shot, {required String intoDirectory}) async {
    final taken = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (taken == null) return null; // backed out without taking it
    final dir = Directory(intoDirectory);
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = '${shot.key}${p.extension(taken.path)}';
    final destination = p.join(intoDirectory, name);
    await File(taken.path).copy(destination);
    return destination;
  }
}
