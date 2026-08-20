import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Holding the button and letting go.
///
/// Capture only. The transcribing happens on the Mac Mini, on the transcriber
/// the kitchen panel's Talk button has used since long before this project —
/// this hands the sound over and has no opinion about what is in it. A second
/// transcriber living here would be two things that could disagree about the
/// same sentence, and it would be the one nobody maintained.
///
/// An interface with one real implementation, which exists so the screen above
/// it can be exercised without a microphone. That is not test scaffolding for
/// its own sake: everything interesting about this feature — the row appearing
/// at once, the words arriving late, a correction beating the answer home — is
/// about what happens *after* the sound is captured, and none of it should be
/// untestable because the capture itself needs hardware.
abstract class Microphone {
  /// Whether this phone will let us listen. Asks the person the first time.
  Future<bool> allowed();

  Future<void> start();

  /// The recording, or null if nothing was captured.
  Future<File?> stop();

  /// Let go somewhere else, changed your mind. The sound is thrown away and no
  /// row is ever created — abandoning is a gesture on this phone and never
  /// reaches the kitchen computer at all.
  Future<void> abandon();
}

class PhoneMicrophone implements Microphone {
  final AudioRecorder _recorder;
  final _log = Logger('Microphone');

  PhoneMicrophone({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  @override
  Future<bool> allowed() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final base = await getTemporaryDirectory();
    final path =
        '${base.path}/said-${DateTime.now().millisecondsSinceEpoch}.m4a';
    // Mono, and no better than speech needs. The recording exists to be
    // transcribed and then deleted; a bigger file would only make it slower to
    // get across the house.
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        sampleRate: 22050,
        bitRate: 48000,
      ),
      path: path,
    );
    _log.info('[SAID] listening -> $path');
  }

  @override
  Future<File?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    _log.info('[SAID] captured ${await file.length()} bytes');
    return file;
  }

  @override
  Future<void> abandon() async {
    await _recorder.cancel();
    _log.info('[SAID] abandoned');
  }
}
