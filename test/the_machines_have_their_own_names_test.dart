/// The machines in this house have names, and there are only three of them.
///
/// Aidan, twice: *"Once again, there IS no kitchen computer. There is
/// mac-mini, there is a kitchen tablet. No kitchen computer."*
///
/// - **the Mac Mini** — the server, the thing his phone talks to
/// - **the kitchen tablet** — a screen that talks to the Mac Mini
/// - **his phone** — a third thing
///
/// There is no fourth machine. An invented name is worse than jargon, which is
/// at least a hard word for a real thing: a plausible name for a machine that
/// does not exist reads as correct and quietly sends somebody to the wrong
/// room. "Your phone isn't reaching the kitchen computer" and "your phone isn't
/// reaching the Mac Mini" are instructions to go to different places.
///
/// So this is a check rather than a resolution to be careful. It reads the
/// prose this project puts in front of him — the app's own strings, the release
/// notes, and any walkthrough that has not been run yet — and fails if a made-up
/// machine is named in it.
///
/// **Walkthroughs that have already been run are deliberately left alone.** A
/// finished run is a record of what he was actually shown; editing one to read
/// better afterwards would be rewriting history to flatter the author.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Names for machines that do not exist, and what to say instead.
const invented = <String, String>{
  'kitchen computer': 'the Mac Mini, or the kitchen tablet — say which',
  'kitchen machine': 'the kitchen tablet',
  'house computer': 'the Mac Mini',
  'household computer': 'the Mac Mini',
  'kitchen pc': 'the kitchen tablet',
};

void main() {
  final root = Directory.current;

  /// Every file whose words reach Aidan.
  List<File> proseHeReads() {
    final files = <File>[];

    void walk(Directory dir) {
      if (!dir.existsSync()) return;
      for (final entry in dir.listSync(recursive: true)) {
        if (entry is! File) continue;
        if (entry.path.contains('/build/')) continue;
        if (entry.path.endsWith('.dart')) files.add(entry);
      }
    }

    // The app's own strings and the comments around them.
    walk(Directory('${root.path}/lib'));

    // The release notes.
    for (final entry in root.listSync()) {
      if (entry is File && entry.path.endsWith('.md')) files.add(entry);
    }

    // Walkthroughs he has not been given yet. One that has an output.json
    // beside it has already been run and is a record, not a draft.
    final runs = Directory('${root.path}/walkthrough-runs');
    if (runs.existsSync()) {
      for (final run in runs.listSync()) {
        if (run is! Directory) continue;
        final input = File('${run.path}/input.json');
        final output = File('${run.path}/output.json');
        if (input.existsSync() && !output.existsSync()) files.add(input);
      }
    }
    return files;
  }

  test('no machine is called by a name it does not have', () {
    final wrong = <String>[];
    for (final file in proseHeReads()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final lower = lines[i].toLowerCase();
        for (final entry in invented.entries) {
          if (lower.contains(entry.key)) {
            final where = file.path.replaceFirst('${root.path}/', '');
            wrong.add('$where:${i + 1} says "${entry.key}" — '
                'that machine does not exist. Say ${entry.value}.');
          }
        }
      }
    }
    expect(wrong, isEmpty, reason: '\n${wrong.join('\n')}\n');
  });

  test('the check can actually see the prose it is supposed to be reading', () {
    // Without this the test above passes gloriously on an empty list — which is
    // exactly how a guard like this dies without anybody noticing.
    final files = proseHeReads();
    expect(files.length, greaterThan(100),
        reason: 'the app itself should be in here');
    expect(files.map((f) => f.path), anyElement(endsWith('.md')),
        reason: 'the release notes should be in here');
  });
}
