/// Is any of this actually reachable?
///
/// Behaviour under test: every surface Release 1 promised is mounted somewhere a
/// person can get to, and the queue is emptied by the running app.
///
/// This file exists because of a real miss. Every other test in this suite
/// builds its widget directly — `PlannedMealsSection(repository: …)` — which
/// proves the widget works and proves nothing at all about whether the app ever
/// shows it. Seven promises passed their own tests while being unreachable: no
/// tab, no route, no caller. A component test cannot see that, because the
/// thing that is missing is the *call site*, and the test is the call site.
///
/// Since 19 August it also guards the opposite mistake. The app grew a second
/// day — a Today tab beside a Home tab that was already the day — and every
/// test passed while Aidan looked at one and reported the other. So the checks
/// below assert not only that the day is reachable but that there is *one* of
/// it.
///
/// So this reads the source instead. It is deliberately crude — it looks for
/// the mounting, not for what the mounted thing does — and that is the point:
/// what it catches is exactly the failure the careful tests are blind to.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('there is one day, and it is Home', () {
    test('the household\'s planned meals are mounted on Home', () {
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('PlannedMealsSection('), isTrue,
          reason: 'what the household has planned is built nowhere a person '
              'can see it');
      expect(home.contains('DayRepository'), isTrue,
          reason: 'the section is mounted but never given the household to '
              'ask');
    });

    test('reloading Home reloads the planned meals with it', () {
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('_planned.currentState?.reload()'), isTrue,
          reason: 'logging a meal would leave the planned row it matches '
              'sitting there until the app was restarted');
    });

    test('there is no second day anywhere', () {
      final shell = _read('lib/core/presentation/main_screen.dart');
      expect(shell.contains('TodayPage'), isFalse,
          reason: 'a second tab showing the day is the fault this release '
              'exists to remove');
      expect(shell.contains("label: 'Today'"), isFalse);
      expect(File('lib/features/today/presentation/today_screen.dart').existsSync(),
          isFalse,
          reason: 'the deleted screen is still on disk to be re-mounted by '
              'somebody who does not know why it went');
      expect(_read('lib/main.dart').contains('todayRoute'), isFalse,
          reason: 'a route to the second day is still a way to reach it');
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

    test('wherever the form is opened, it is opened as a page', () {
      // The form is deliberately a bare Column so the capture flow can place
      // it inside its own layout. That makes every place that opens it as a
      // whole screen responsible for the page around it: a Material ancestor
      // for the text fields, somewhere to scroll seven of them, and a way
      // back. Its own test supplies all three, which is exactly why the test
      // cannot notice when a route does not.
      for (final file in const [
        'lib/main.dart',
        'lib/features/label_scan/presentation/guided_capture_screen.dart',
      ]) {
        final source = _read(file);
        final at = source.indexOf('ConfirmFoodScreen(');
        expect(at, greaterThan(-1), reason: '$file no longer opens the form');
        // Look back a little way from the call for the page it sits in.
        final before = source.substring((at - 400).clamp(0, at), at);
        expect(before.contains('Scaffold('), isTrue,
            reason: '$file opens the form with no Material around it — the '
                'fields will not render');
        expect(before.contains('SingleChildScrollView('), isTrue,
            reason: '$file opens the form with nowhere to scroll — the lower '
                'fields fall off the bottom');
      }
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
