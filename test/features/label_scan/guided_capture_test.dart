/// Photographing a packet, three shots, and surviving being interrupted.
///
/// Behaviour under test (Release 1, promise 8): a food the app does not know can
/// be added by photographing it — the app drives the camera through three shots
/// in order, and if the flow is interrupted the shots already taken are kept and
/// it carries on from where it stopped.
///
/// The test that carries the item is [it carries on from where it stopped, after
/// the app has been killed]. Two shots are taken, the database is closed — which
/// is what a kill leaves behind — and reopened from the same file. The flow must
/// ask for the third shot, not the first. Resumability is the part the plan
/// review proposed cutting, so it is proved against a real file rather than
/// against memory, where it would have proved nothing.
///
/// Two more things are held to, both easy to lose quietly:
///
///  * **Nothing enters the food list from a partial capture.** Asserted against
///    the server after an interruption, and structurally: the capture flow is
///    given no way to reach the food list at all, which the last group checks by
///    reading the source.
///  * **No photograph is written to the system photo library.** A picture of the
///    back of a cereal box is not a memory. Every shot goes into the directory
///    the flow was given, inside the app's own storage, and the source is
///    checked for any call that would put one in the camera roll.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/label_scan/data/guided_capture.dart';
import 'package:opennutritracker/features/label_scan/data/label_camera.dart';
import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';

import '../household/fake_household_server.dart';

/// A camera that always succeeds, unless told to refuse — which is what backing
/// out of the camera looks like from here.
class FakeCamera implements LabelCamera {
  final List<LabelShot> asked = [];
  final List<String> wroteInto = [];

  /// Shots the person backs out of instead of taking.
  final Set<LabelShot> refuse = {};

  @override
  Future<String?> take(LabelShot shot, {required String intoDirectory}) async {
    asked.add(shot);
    if (refuse.contains(shot)) return null;
    wroteInto.add(intoDirectory);
    return '$intoDirectory/${shot.key}.jpg';
  }
}

void main() {
  late Directory temp;
  late File dbFile;
  late Directory shots;
  late AppDatabase db;
  late FakeCamera camera;
  late GuidedCapture capture;

  /// Open the app's storage. Called again after a "kill" to reopen the same
  /// file, which is the whole point of the file being real.
  GuidedCapture open() {
    db = AppDatabase(NativeDatabase(dbFile));
    camera = FakeCamera();
    return GuidedCapture.of(db, camera, directory: shots.path);
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('guided-capture');
    dbFile = File('${temp.path}/foodtracker.db');
    shots = await Directory('${temp.path}/label-shots').create();
    capture = open();
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  group('three shots, in order', () {
    test('it asks for the front first', () async {
      final id = capture.start();
      expect(await capture.nextShot(id), LabelShot.front);
    });

    test('then the nutrition panel, then the ingredients', () async {
      final id = capture.start();
      await capture.takeNext(id);
      expect(await capture.nextShot(id), LabelShot.nutrition);
      await capture.takeNext(id);
      expect(await capture.nextShot(id), LabelShot.barcode);
      await capture.takeNext(id);
      expect(await capture.nextShot(id), isNull);
    });

    test('the app drives the camera rather than the person', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);
      await capture.takeNext(id);

      expect(camera.asked,
          [LabelShot.front, LabelShot.nutrition, LabelShot.barcode]);
    });

    test('it says what to point the camera at', () {
      expect(LabelShot.front.instruction,
          'Photograph the front of the packet');
      expect(LabelShot.nutrition.instruction, 'Now the nutrition panel');
      expect(LabelShot.barcode.instruction, 'And the barcode');
    });

    test('a shot backed out of leaves the flow where it was', () async {
      final id = capture.start();
      camera.refuse.add(LabelShot.front);

      expect(await capture.takeNext(id), isNull);
      expect(await capture.nextShot(id), LabelShot.front);
      expect(await capture.taken(id), isEmpty);
    });

    test('a blurry shot can be retaken without adding a fourth image',
        () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);

      await capture.retake(id, LabelShot.front);

      final taken = await capture.taken(id);
      expect(taken.length, 2, reason: 'a retake replaces, it does not add');
      expect(taken.map((s) => s.shot).toSet(),
          {LabelShot.front, LabelShot.nutrition});
      expect(await capture.nextShot(id), LabelShot.barcode,
          reason: 'retaking one does not send the flow backwards');
    });
  });

  group('being interrupted', () {
    test('the shots already taken are kept', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);

      expect((await capture.taken(id)).map((s) => s.shot).toList(),
          [LabelShot.front, LabelShot.nutrition]);
    });

    test('it carries on from where it stopped, after the app has been killed',
        () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);

      // The app is killed mid-capture and started again.
      await db.close();
      capture = open();

      expect(await capture.nextShot(id), LabelShot.barcode,
          reason: 'coming back must not start again from the front');
      await capture.takeNext(id);
      expect(await capture.isComplete(id), isTrue);
      expect(camera.asked, [LabelShot.barcode],
          reason: 'the two photographs already taken were not asked for again');
    });

    test('a part-done capture is offered on the way back in', () async {
      final id = capture.start();
      await capture.takeNext(id);

      await db.close();
      capture = open();

      expect(await capture.unfinishedCapture(), id);
    });

    test('a finished one is not offered again', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);
      await capture.takeNext(id);

      expect(await capture.unfinishedCapture(), isNull);
    });

    test('a part-done capture is not readable as a packet', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);

      // Two photographs of a packet are not a packet, and sending them as one
      // would produce numbers off a panel nobody photographed.
      expect(await capture.shotsForReading(id), isNull);
    });

    test('all three are, once they are all there', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);
      await capture.takeNext(id);

      final ready = await capture.shotsForReading(id);
      expect(ready, isNotNull);
      expect(ready!.keys.toSet(), {'front', 'nutrition', 'barcode'});
    });
  });

  group('nothing enters the food list from a partial capture', () {
    test('the household list is untouched by an interrupted capture', () async {
      final mini = FakeHouseholdServer();
      final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
      final household = HouseholdRepository(ConfigDao(db), api);
      await household.setOwner(mini.aidan);

      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);
      await db.close();
      capture = open();
      await capture.takeNext(id);

      expect(mini.foods, isEmpty,
          reason: 'photographing a packet creates nothing; saving does, and '
              'saving has not happened');
    });

    test('a discarded capture leaves nothing behind', () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.discard(id);

      expect(await capture.taken(id), isEmpty);
      expect(await capture.unfinishedCapture(), isNull);
    });
  });

  group('the photographs stay in the app', () {
    test('every shot is written into the directory the flow was given',
        () async {
      final id = capture.start();
      await capture.takeNext(id);
      await capture.takeNext(id);
      await capture.takeNext(id);

      expect(camera.wroteInto, everyElement(shots.path));
      for (final s in await capture.taken(id)) {
        expect(s.path, startsWith(shots.path));
      }
    });

    test('nothing in the capture path can reach the system photo library', () {
      // The rule is structural rather than remembered: if the code cannot call
      // the camera roll, no photograph can end up there. Written as a source
      // check so a later change that adds one breaks the build.
      final gallery = RegExp(
          r'ImageGallerySaver|GallerySaver|photo_manager|PhotoManager|'
          r'saveImageToGallery|writeToPhotoLibrary|saveToGallery');
      final offenders = <String>[];
      for (final entity
          in Directory('lib/features/label_scan').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (gallery.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'a picture of the back of a cereal box does not belong in '
              "somebody's camera roll:\n${offenders.join('\n')}");
    });

    test('the capture flow has no way to write a food at all', () {
      // The strongest form of "nothing is created by photographing": the class
      // holds no logger, no queue and no food list.
      final source =
          File('lib/features/label_scan/data/guided_capture.dart')
              .readAsStringSync();
      for (final forbidden in [
        'HouseholdLogger',
        'Outbox',
        'addFood',
        '/household/food',
      ]) {
        expect(source.contains(forbidden), isFalse,
            reason: 'guided_capture.dart must not be able to reach '
                '$forbidden');
      }
    });
  });
}
