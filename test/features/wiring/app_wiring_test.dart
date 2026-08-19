/// Is any of this actually reachable?
///
/// Behaviour under test: every surface Release 1 promised is mounted somewhere a
/// person can get to, and the queue is emptied by the running app.
///
/// This file exists because of a real miss. Every other test in this suite
/// builds its widget directly — `TodayScreen(repository: …)` — which proves the
/// screen works and proves nothing at all about whether the app ever shows it.
/// Seven promises passed their own tests while being unreachable: no tab, no
/// route, no caller. A component test cannot see that, because the thing that
/// is missing is the *call site*, and the test is the call site.
///
/// So this reads the source instead. It is deliberately crude — it looks for
/// the mounting, not for what the mounted thing does — and that is the point:
/// what it catches is exactly the failure the careful tests are blind to.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('the day is reachable', () {
    test('Today is one of the app\'s tabs', () {
      final shell = _read('lib/core/presentation/main_screen.dart');
      expect(shell.contains('TodayPage()'), isTrue,
          reason: 'the day is built nowhere in the tab shell');
      expect(shell.contains("label: 'Today'"), isTrue,
          reason: 'there is no way to select the day');
    });

    test('the day is also a named route', () {
      expect(_read('lib/main.dart').contains('NavigationOptions.todayRoute'),
          isTrue);
    });

    test('the mounted day is given the exercise routes', () {
      final page = _read('lib/features/today/presentation/today_page.dart');
      expect(page.contains('ExerciseSync'), isTrue,
          reason: 'the watch is never read from the mounted day');
      expect(page.contains('TypeExerciseScreen'), isTrue,
          reason: 'there is no way to type exercise in');
    });
  });

  group('the queue is emptied', () {
    test('something starts the sender', () {
      final main = _read('lib/main.dart');
      expect(main.contains('OutboxSender'), isTrue,
          reason: 'nothing in the running app ever sends what is held');
      expect(main.contains('sender:'), isTrue,
          reason: 'the sender is built but not handed to the scope');
    });

    test('the scope starts and stops it', () {
      final scope =
          _read('lib/features/household/presentation/household_scope.dart');
      expect(scope.contains('sender?.start()'), isTrue);
      expect(scope.contains('sender?.stop()'), isTrue,
          reason: 'a sender that is never stopped outlives the app tree');
    });

    test('the sender sends on resume, not only at launch', () {
      final sender = _read('lib/features/household/data/outbox_sender.dart');
      expect(sender.contains('AppLifecycleState.resumed'), isTrue,
          reason: 'coming back into range is the moment held work can go');
    });
  });

  group('a food can be got into the list', () {
    test('both routes are in the add sheet', () {
      final sheet =
          _read('lib/core/presentation/widgets/add_item_bottom_sheet.dart');
      expect(sheet.contains('NavigationOptions.labelCaptureRoute'), isTrue,
          reason: 'the three-shot camera is unreachable');
      expect(sheet.contains('NavigationOptions.addFoodByHandRoute'), isTrue,
          reason: 'the hand-typed form is unreachable');
    });

    test('both routes are registered', () {
      final main = _read('lib/main.dart');
      expect(main.contains('GuidedCaptureScreen('), isTrue);
      expect(main.contains('ConfirmFoodScreen('), isTrue);
    });

    test('the camera behind the flow is a real one', () {
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('PickerLabelCamera()'), isTrue,
          reason: 'the guided flow has no camera outside the tests');
      final camera =
          _read('lib/features/label_scan/data/picker_label_camera.dart');
      expect(camera.contains('ImageSource.camera'), isTrue);
      expect(camera.contains('ImageSource.gallery'), isFalse,
          reason: 'the promise is three shots taken, not three pictures found');
    });
  });

  test('the weight view is mounted where a person looks', () {
    expect(_read('lib/features/profile/profile_page.dart')
        .contains('OwnerWeightSection()'), isTrue,
        reason: 'the switch hides a view nobody can see either way');
  });
}
