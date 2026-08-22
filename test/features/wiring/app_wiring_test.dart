/// Is any of this actually reachable?
///
/// Behaviour under test: every surface Release 1 promised is mounted somewhere a
/// person can get to, and the queue is emptied by the running app.
///
/// This file exists because of a real miss. Every other test in this suite
/// builds its widget directly — `PlannedMealCard(item: …)` — which
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

/// The same source with every run of whitespace closed up.
///
/// These wiring checks look for a call in the source text, and a call is only
/// text until the formatter decides the line is too long and breaks it at the
/// dot. On 20 August `locator<WeightRepository>().typed(` went over the limit
/// and split across two lines, and the check for it failed while the wiring it
/// was checking had not moved at all. A test that reports a defect because a
/// line got longer is worse than no test: it costs a hunt and teaches you to
/// distrust it. Matching against the closed-up source asks the question the
/// test means to ask — is this call here — rather than "is it laid out the way
/// it was when I was written".
String _calls(String path) => _read(path).replaceAll(RegExp(r'\s+'), '');

void main() {
  group('there is one day, and it is Home', () {
    test('there is one list of food on Home, and it is the diary', () {
      // The fault of 20 August 2026 in one check. Home showed spoken food in a
      // section of its own, above four meal slots that stayed empty, with the
      // ring at the top counting only the slots. Aidan: "it seems like despite
      // the issues we had yesterday you are still building a separate system
      // inside the existing system." Any household list of eaten food mounted
      // on this screen is that fault coming back.
      final home = _read('lib/features/home/home_page.dart');
      expect('IntakeVerticalList('.allMatches(home).length, 4,
          reason: 'the diary\'s four meal slots are no longer all on Home');
      expect(home.contains('WeekAheadSection('), isFalse,
          reason: 'WeekAheadSection( is a second day on the screen that '
              'already has one — the week ahead belongs on the kitchen panel');
    });

    test('tonight\'s planned dinner is on the day as a ghost entry', () {
      // Aidan, asked on 22 August where confirming a planned dinner should
      // live: "a 'ghost' entry on the home screen of the phone app which looks
      // just like a regular food entry, but says 'tap to confirm' - you tap to
      // confirm you ate that thing and it becomes a real entry."
      //
      // This is the reverse of what this file asserted the day before, and the
      // reversal is deliberate. The earlier version forbade a planned *section*
      // on Home — a list of its own above the day, which is the fault it was
      // written for. What he asked for is not a section: it is a card inside
      // the diary's own list. So the check moved from "no planned anything on
      // Home" to "the planned meals are handed to the diary list".
      //
      // And it is a wiring check, not a component one, because the card has its
      // own tests and they cannot see whether Home ever passes it anything.
      final wired = _calls('lib/features/home/home_page.dart');
      expect(wired.contains('planned:_planned.items'), isTrue,
          reason: 'nothing on Home hands the day\'s planned meals to the '
              'diary, so a planned dinner can never be confirmed from the '
              'phone');
      expect(wired.contains('onAtePlanned:'), isTrue,
          reason: 'the ghost entry is drawn but tapping it records nothing');
      expect(wired.contains('onPlannedNotEaten:'), isTrue,
          reason: 'there is no way to say you did not have it');
    });

    test('saying what you ate reaches the diary and not a list of its own', () {
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('SayWhatYouAteSection('), isTrue,
          reason: 'there is no way to say what you ate on the screen you are '
              'looking at');
      expect(home.contains('onChanged: _afterSaying'), isTrue,
          reason: 'a sentence is understood and then nothing fetches what it '
              'became, so the food appears the next time the app opens — '
              'which looks exactly like it not having worked');
      final after = RegExp(r'void _afterSaying\(\) \{(.*?)\n  \}',
              dotAll: true)
          .firstMatch(home)
          ?.group(1);
      expect(after, isNotNull, reason: 'Home no longer does anything after a '
          'sentence is understood');
      expect(after!.contains('_syncMantel()'), isTrue,
          reason: 'nothing pulls the meal into the diary');
    });

    test('the mirror into the diary is still wired to opening the app', () {
      // The pull is at-least-once by design: if the one after a sentence is
      // missed — killed app, no signal, a sleeping Mini — opening the app has
      // to be enough to catch up. Losing this would make a dropped sync
      // permanent.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('MantelSyncService'), isTrue,
          reason: 'nothing brings household meals into the diary at all');
      expect(home.contains('_syncMantel()'), isTrue);
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
      // Two links, checked separately, because the weight now goes through the
      // repository that also holds the history rather than straight to the
      // queue. Either link missing and a weight typed on Profile never leaves
      // the phone, so neither is taken on trust.
      final profile = _calls('lib/features/profile/profile_page.dart');
      expect(profile.contains('WeightRepository>().typed('), isTrue,
          reason: 'a weight typed on Profile is not handed to anything');
      final weights =
          _calls('lib/features/weight/data/weight_repository.dart');
      expect(weights.contains('_logger.logWeight('), isTrue,
          reason: 'the weight is handed on and then goes nowhere');
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

  group('a meal with more than three things in it', () {
    // Aidan, 21 August: "if there are more than three items in a meal, I can't
    // view them all - they disappear off the right, and I can't scroll because
    // scrolling swipes left as if to delete." Two gestures were wired to the
    // same drag — the strip scrolling sideways, and the card under the thumb
    // being swiped away — and the card won every time.
    test('the card does not answer a sideways drag', () {
      final card = _read('lib/core/presentation/widgets/intake_card.dart');
      expect(card.contains('Dismissible'), isFalse,
          reason: 'a card that swipes away takes the drag that scrolls the '
              'strip, and a meal past its third item cannot be read at all');
    });

    test('removing a row is asked for by name, and can still be taken back',
        () {
      // The swipe was the only place Undo was ever offered, so losing it would
      // have quietly deleted a feature Aidan had not yet seen. These two lines
      // are where it went instead.
      final home = _calls('lib/features/home/home_page.dart');
      expect(home.contains('edit.remove'), isTrue,
          reason: 'the DELETE button in the edit dialog reaches nothing — '
              'tapping a row is now the way a row is removed');
      expect(home.contains('sayTheRowIsGone(context,intakeEntity)'), isTrue,
          reason: 'a row can be removed with no offer to put it back');

      final dialog =
          _calls('lib/core/presentation/widgets/edit_dialog.dart');
      expect(dialog.contains('IntakeEdit(null,remove:true)'), isTrue,
          reason: 'the edit dialog offers no way to remove the row it is '
              'showing');
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
    test('is not on the phone at all', () {
      // Aidan's call, 20 August 2026, after a run in which the week and the
      // plan on the phone were both empty and both untestable: planning is what
      // the kitchen panel is for, and a second copy of it here was a second
      // thing to keep in step for no gain. The repository below stays — the
      // phone still reads the household — but nothing draws a week on Home.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('WeekAheadSection('), isFalse,
          reason: 'the week is back on the phone');
    });

    test('the repository it needs is built', () {
      expect(_read('lib/core/utils/locator.dart')
          .contains('WeekRepository(householdApi, householdRepository)'), isTrue,
          reason: 'Home asks for something nothing ever registered');
    });
  });

  group('planning the week', () {
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

  });

  group('saying what you ate', () {
    test('the button is on the screen people already look at', () {
      // Not behind a tab. A screen you have to find first is a screen people
      // go back to typing instead of, and the whole promise here is that it
      // takes one motion.
      final home = _read('lib/features/home/home_page.dart');
      expect(home.contains('SayWhatYouAteSection('), isTrue,
          reason: 'nothing on Home lets anybody say what they ate');
    });

    test('everything it needs is built', () {
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('SaidRepository('), isTrue);
      expect(locator.contains('registerLazySingleton<Microphone>'), isTrue,
          reason: 'Home asks for a microphone nothing ever registered');
      expect(locator.contains('ClipStore()'), isTrue);
    });

    test('the phone does not grow a transcriber of its own', () {
      // The transcribing is the Mac Mini's, on the one the kitchen panel has
      // used since long before this project. A second one on the phone would
      // mean two things that could disagree about the same sentence, and the
      // one on the phone would be the one nobody maintained.
      final pubspec = _read('pubspec.yaml');
      for (final onDevice in ['speech_to_text', 'whisper', 'flutter_stt']) {
        expect(pubspec.contains(onDevice), isFalse,
            reason: '$onDevice would make two things that can disagree about '
                'the same sentence, and this one nobody would maintain');
      }
      expect(_read('lib/features/said/data/microphone.dart').contains('Mac Mini'),
          isTrue,
          reason: 'say out loud where the transcribing happens');
    });

    test('the row is written before anything tries to understand it', () {
      // The order is the design. Written down here as well as in the code
      // because reversing it reads better and is wrong in the one case that
      // matters — the Mac Mini asleep, and what you said simply gone.
      final repository = _read('lib/features/said/data/said_repository.dart');
      final heard = repository.indexOf('Future<String> heard(');
      final logFood = repository.indexOf('_logger.logFood(', heard);
      final workOut = repository.indexOf('Future<Understood?> workOut(');
      expect(logFood, isNonNegative);
      expect(logFood, lessThan(workOut),
          reason: 'understanding it has got in front of writing it down');
    });

    test('the phone asks for the microphone in words a person can read', () {
      final plist = _read('ios/Runner/Info.plist');
      expect(plist.contains('NSMicrophoneUsageDescription'), isTrue,
          reason: 'iOS kills an app that opens the microphone without one');
    });
  });

  group('weight, and the trend', () {
    test('the trend is on the row the weight is already on', () {
      // Not a tab, not a screen. Aidan stopped an earlier build because a
      // second Today tab sat beside the Home tab doing the same job; a weight
      // screen beside the weight row would be that mistake again.
      final profile = _read('lib/features/profile/profile_page.dart');
      expect(profile.contains('TrendLine.of('), isTrue,
          reason: 'the trend is worked out and shown nowhere');
      expect(profile.contains('WeightHistorySheet'), isTrue,
          reason: 'there is no way into the dated history from the weight');
    });

    test('nothing else in the app opens a weight surface of its own', () {
      // If the history sheet is opened from two places, one of them is a
      // second way in that nobody asked for and only one of them will be
      // maintained.
      final opens = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('/weight/'))
          .where((f) => f.readAsStringSync().contains('WeightHistorySheet.show('))
          .map((f) => f.path)
          .toList();
      expect(opens, ['lib/features/profile/profile_page.dart']);
    });

    test('everything it needs is built', () {
      final locator = _read('lib/core/utils/locator.dart');
      expect(locator.contains('WeightRepository('), isTrue,
          reason: 'Profile asks for a weight repository nothing registered');
    });

    test('weights and calories are read from Apple Health apart', () {
      // The two share one permission dialog and must not share one read: the
      // combined list passed to the calorie query would fold every weigh-in
      // into the day's active calories as if a kilogram were a kilocalorie.
      final health = _read('lib/core/data/data_source/health_data_source.dart');
      expect(health.contains('types: _energy'), isTrue,
          reason: "the day's calories are read with the combined type list");
      expect(health.contains('types: _weight'), isTrue,
          reason: 'weights are read with something other than the weight type');
    });

    test('the phone says out loud that it reads weight, not just calories', () {
      final plist = _read('ios/Runner/Info.plist');
      final start = plist.indexOf('NSHealthShareUsageDescription');
      final reason = plist.substring(start, start + 260);
      expect(reason.toLowerCase().contains('weight'), isTrue,
          reason: 'the app now reads body weight and does not say so');
    });

    test('a backlog goes through the queue, not through a route of its own', () {
      // There is no batch import. A backlog is a lot of ordinary weigh-ins
      // through the outbox that already retries and already refuses to store
      // the same thing twice.
      final repository = _read('lib/features/weight/data/weight_repository.dart');
      expect(repository.contains('_logger.logWeight('), isTrue);
      expect(repository.contains('/weights/import'), isFalse,
          reason: 'a second way to write a weight, with its own retrying to '
              'get wrong');
    });
  });
}
