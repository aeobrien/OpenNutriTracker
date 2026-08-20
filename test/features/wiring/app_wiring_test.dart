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

    test('the planned rows can actually be answered', () {
      // The buttons only appear when the section is given something to put the
      // answer on. A section mounted without it renders the plan perfectly and
      // silently offers no way to confirm it — which looks like a design
      // choice rather than a missing line.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('logger: locator<HouseholdLogger>()'), isTrue,
          reason: 'the planned meals on Home have no way to be confirmed');
      expect(home.contains('onDecided:'), isTrue,
          reason: 'eating a planned meal would not redraw the day it changed');
    });

    test('reloading Home reloads the planned meals with it', () {
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('_planned.currentState?.reload()'), isTrue,
          reason: 'logging a meal would leave the planned row it matches '
              'sitting there until the app was restarted');
    });

    test('and the one reload does not call itself', () {
      // Written after doing exactly this. Routing every reload in Home through
      // one helper is right; a search-and-replace that rewrites the helper's
      // own body along with its call sites turns it into infinite recursion.
      // Nothing caught it, because no test mounts Home — which is the same
      // blind spot this file exists for.
      final home = _read('lib/features/home/home_page.dart');
      final body = RegExp(r'void _reload\(\) \{(.*?)\n  \}', dotAll: true)
          .firstMatch(home)
          ?.group(1);
      expect(body, isNotNull, reason: 'Home has no single reload any more');
      expect(body!.contains('_reload()'), isFalse,
          reason: 'Home\'s reload calls itself');
      expect(body.contains('LoadItemsEvent'), isTrue,
          reason: 'Home\'s reload no longer reloads Home');
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

  group('food added on a screen', () {
    test('every screen that adds a food goes through the one method', () {
      // Home, Diary, the food search and the portion sheet all add a food by
      // calling MealDetailBloc.addIntake. That is why the household write was
      // put there and not on the sheet: one line covers four screens, and a
      // fifth screen added later gets it without anybody remembering.
      for (final path in [
        'lib/features/home/presentation/widgets/intake_vertical_list.dart',
        'lib/features/diary/diary_page.dart',
        'lib/features/add_meal/presentation/add_meal_screen.dart',
        'lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart',
      ]) {
        expect(_read(path).contains('addIntake('), isTrue,
            reason: '$path stopped adding food the shared way, so the '
                'household write no longer reaches it');
      }
    });

    test('that method reaches the household', () {
      final bloc = _read(
          'lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart');
      expect(bloc.contains('_alsoTellTheHousehold('), isTrue,
          reason: 'food added on any screen never leaves the phone');
      expect(bloc.contains('FoodLedger'), isTrue,
          reason: 'the bloc has nothing to write to the household with');
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('FoodLedger('), isTrue,
          reason: 'the household half of adding a food is never built');
    });

    test('the portion sheet asks who it was for', () {
      final sheet = _read(
          'lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart');
      expect(sheet.contains('WhoWasItFor('), isTrue,
          reason: 'there is no way to say a meal was for both of you');
      expect(sheet.contains('alsoFor: _shares()'), isTrue,
          reason: 'the answer is asked for and then thrown away');
    });
  });

  group('weight', () {
    test('there is one weight row on Profile, not two', () {
      final profile = _read('lib/features/profile/profile_page.dart');
      expect(profile.contains('OwnerWeightSection'), isFalse,
          reason: 'a household weight section sitting above the app\'s own '
              'weight row is the thing he tripped over');
      expect(
          File('lib/features/household/presentation/weight_section.dart')
              .existsSync(),
          isFalse,
          reason: 'the deleted section is still on disk to be re-mounted');
    });

    test('the row that is left reaches the household', () {
      final profile = _read('lib/features/profile/profile_page.dart');
      expect(profile.contains('logWeight('), isTrue,
          reason: 'a weight typed on Profile never leaves the phone');
    });
  });

  group("the house's own foods", () {
    test('the picker opens by asking the house', () {
      final screen =
          _read('lib/features/add_meal/presentation/add_meal_screen.dart');
      expect(screen.contains('LoadOurFoodsEvent()'), isTrue,
          reason: 'the picker still opens on an empty screen telling him to '
              'start typing');
      expect(screen.contains('AddMealScreen.ourFoodsLabel'), isTrue,
          reason: "his own foods would appear under the heading 'Search "
              "results', before he has searched for anything");
    });

    test('searching and scanning are given the house to ask', () {
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('FoodFinder('), isTrue,
          reason: 'nothing builds the thing that asks the house');
      expect(locator.contains('SearchProductsUseCase(locator(), locator())'),
          isTrue,
          reason: 'the search is built without the house, so it silently goes '
              'straight to the internet as it always did');
      expect(
          locator.contains(
              'SearchProductByBarcodeUseCase(locator(), locator())'),
          isTrue,
          reason: 'the scanner is built without the house, so a packet already '
              'read here is looked up on the internet anyway');
    });

    test('a food logged from our own list says which food it was', () {
      final bloc = _read(
          'lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart');
      expect(bloc.contains('HouseholdFood.idFromCode(meal.code)'), isTrue,
          reason: "entries never say which food they were, so 'your own foods "
              "first' has nothing to count");
    });
  });

  group('looking a food up online', () {
    test('the offer is on the search screen, under the results', () {
      final screen =
          _read('lib/features/add_meal/presentation/add_meal_screen.dart');
      expect(screen.contains('LookItUpWidget('), isTrue,
          reason: 'there is no way to ask, so a food neither list has is a '
              'dead end');

      final results = screen.indexOf('_productsBody(state)');
      final hunt = screen.indexOf('LookItUpWidget(');
      expect(results, greaterThan(-1));
      expect(hunt, greaterThan(results),
          reason: 'the least-checked numbers would sit above the two lists '
              'whose numbers somebody has actually checked');
    });

    test('the hunt is a button, not something that runs on its own', () {
      final widget = _read(
          'lib/features/add_meal/presentation/widgets/look_it_up_widget.dart');
      expect(widget.contains('initState'), isFalse,
          reason: 'a hunt started on screen open runs before anybody has '
              'looked at what the two better lists offered');
    });

    test('what a hunt finds is written only through the confirmation screen',
        () {
      final widget = _read(
          'lib/features/add_meal/presentation/widgets/look_it_up_widget.dart');
      expect(widget.contains('ConfirmFoodScreen('), isTrue);
      expect(widget.contains('addFood('), isFalse,
          reason: 'a second write path means a food can reach the household '
              'list without anybody having looked at its numbers');
    });
  });

  group('the figure already in the amount box', () {
    test('the screen asks for one rather than choosing its own', () {
      final screen = _read('lib/features/meal_detail/meal_detail_screen.dart');
      expect(screen.contains('defaultPortionFor('), isTrue,
          reason: 'the order lives inline again where it cannot be tested');
      expect(screen.contains('portion: _portion'), isTrue,
          reason: 'the reason is worked out and then thrown away before the '
              'sheet can say it');
    });

    test('the sheet says where the figure came from', () {
      final sheet = _read(
          'lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart');
      expect(sheet.contains('widget.portion?.explanation'), isTrue,
          reason: 'a figure nobody typed appears with nothing saying what it '
              'is');
    });
  });

  group('correcting something already logged', () {
    // Release D's three promises each die at a different call site, and each
    // death is invisible to the tests that cover the pieces: the ledger's own
    // tests build it by hand, so they cannot see whether the app ever builds
    // it that way.

    test('the two use cases are given the household to tell', () {
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('DeleteIntakeUsecase(locator(), locator())'),
          isTrue,
          reason: 'taking a row off this phone leaves it standing in the '
              "house, and nothing on either screen says so");
      expect(locator.contains('UpdateIntakeUsecase(locator(), locator())'),
          isTrue,
          reason: 'a corrected figure stays corrected only here, so the two '
              'people are looking at different numbers');
    });

    test('the edit box offers the other person', () {
      final dialog = _read('lib/core/presentation/widgets/edit_dialog.dart');
      expect(dialog.contains('WhoseDayIsIt('), isTrue,
          reason: 'a row logged against the wrong person can be changed in '
              'every way except the one that is wrong');
    });

    test('the person picked is carried through to the house', () {
      // Three hops, and the choice is silently dropped at any of them: the
      // screen reads the dialog's answer, the bloc forwards it, the use case
      // sends it. A move that stops halfway leaves the amount corrected on one
      // day and the row still on the other.
      expect(_read('lib/features/home/home_page.dart')
          .contains('moveTo: edit.moveTo'), isTrue,
          reason: 'the screen asks whose day it is and then throws the answer '
              'away');
      expect(_read('lib/features/home/presentation/bloc/home_bloc.dart')
          .contains('moveTo: moveTo'), isTrue,
          reason: 'the answer reaches the bloc and stops there');
      expect(_read('lib/core/domain/usecase/update_intake_usecase.dart')
          .contains('moveTo: moveTo'), isTrue,
          reason: 'the move is worked out and never sent');
    });

    test('a logged food is given the name both machines will use', () {
      // Without this the phone's diary row and the household's row have no
      // name in common, and there is nothing for a later correction to land
      // on. It is the one line the other three tests all rest on.
      final bloc = _read(
          'lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart');
      expect(bloc.contains('intakeId: intakeId'), isTrue,
          reason: 'the household mints its own name for the row, so nothing '
              'logged from this screen can ever be corrected or withdrawn');
    });
  });

  group('the week', () {
    test('is mounted on Home, and Home is where it stays', () {
      // Its own tab is exactly what this project already got wrong once: a
      // second Today beside a Home that was already the day. The week is a
      // section on the screen that exists, or it is nothing.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('WeekAheadSection('), isTrue,
          reason: 'the week is built nowhere a person can see it');
      expect(home.contains('locator<WeekRepository>()'), isTrue,
          reason: 'the section is mounted but never given the household to ask');
    });

    test('is redrawn when the day it sits under is', () {
      // Logging a meal changes today's figure on the week. Without this the
      // section sits showing the week as it was when the app opened, which
      // reads as a wrong figure rather than a stale one.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('_week.currentState?.reload()'), isTrue,
          reason: 'the week goes stale the moment anything is logged');
    });

    test('the repository it needs is built', () {
      expect(_read('lib/core/utils/locator.dart')
          .contains('WeekRepository(householdApi, householdRepository)'), isTrue,
          reason: 'Home asks for something nothing ever registered');
    });
  });

  group('planning the week', () {
    test('the week is given something to plan with', () {
      // The section takes a planner only if Home passes one. Without it every
      // day on the week is inert and the phone can read the plan but never
      // change it — which is the half-built state this release exists to end.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('planner: locator<PlanRepository>()'), isTrue,
          reason: 'the week is mounted read-only, so no day opens');
    });

    test('the repository it needs is built', () {
      expect(_read('lib/core/utils/locator.dart')
          .contains('PlanRepository(householdApi, householdRepository)'), isTrue,
          reason: 'Home asks for something nothing ever registered');
    });

    test('planning is not queued behind the outbox', () {
      // Deliberate, and the one thing about this path most likely to be
      // "fixed" later by somebody making it consistent with the ledger writes.
      // It must not be: a meal planned against a week you cannot see is
      // planned blind, and the other phone may have put something on that day
      // a minute ago.
      final repository =
          _read('lib/features/plan/data/plan_repository.dart');
      expect(repository.contains('Outbox'), isFalse,
          reason: 'planning has been put on the queue, so somebody can plan '
              'on top of a meal they were never shown');
    });

    test('the day that was changed is redrawn behind the sheet', () {
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('onPlanned: _reload'), isTrue,
          reason: "putting tonight's dinner on the plan leaves today showing "
              'the day as it was before');
    });
  });
}
