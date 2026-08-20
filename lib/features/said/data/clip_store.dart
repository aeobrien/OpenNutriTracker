import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Recordings the Mac Mini has not heard yet.
///
/// A recording is kept only for as long as it is still owed to somebody. The
/// moment the sentence has been worked out the file goes, because it is the
/// only copy of somebody's voice this app holds and holding it after it has
/// served its purpose is not something anybody asked for.
///
/// Filed under the name the phone gave the row, which is the same name the
/// Mac Mini knows it by. That is what lets a recording made on a train
/// this morning find its own row this evening without anything having to
/// remember the pairing.
class ClipStore {
  final _log = Logger('ClipStore');
  Directory? _dir;

  Future<Directory> _folder() async {
    final have = _dir;
    if (have != null) return have;
    final base = await getApplicationSupportDirectory();
    final made = Directory('${base.path}/said');
    if (!await made.exists()) {
      await made.create(recursive: true);
    }
    _dir = made;
    return made;
  }

  Future<File> keep(String clientId, File recording) async {
    final folder = await _folder();
    final kept = File('${folder.path}/$clientId${_suffix(recording.path)}');
    await recording.copy(kept.path);
    _log.info('[SAID] kept ${kept.path}');
    return kept;
  }

  /// The recording behind a row, if this phone still has one. Null once it has
  /// been heard, and null for a sentence that was typed rather than spoken.
  Future<File?> forRow(String clientId) async {
    final folder = await _folder();
    await for (final item in folder.list()) {
      final name = item.path.split('/').last;
      if (item is File && name.split('.').first == clientId) return item;
    }
    return null;
  }

  Future<void> forget(String clientId) async {
    final file = await forRow(clientId);
    if (file == null) return;
    await file.delete();
    _log.info('[SAID] forgot $clientId');
  }

  String _suffix(String path) {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '.m4a' : path.substring(dot);
  }
}
