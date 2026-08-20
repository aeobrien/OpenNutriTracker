/// Saying what you ate, and rows that are still being worked out.
///
/// Behaviour under test (Release G, TM-0027 + TM-0028 — the phone half):
///
///  * the row goes on the household's ledger the moment you let go, before
///    anything has understood it. Not after. The kitchen computer being asleep
///    must cost you a rough number, never the thing you said;
///  * a correction made while the answer is on the wire wins, permanently;
///  * typing a sentence and speaking one are the same thing to everything
///    downstream, so the phone offers both and neither is a lesser path;
///  * and at most one question ever comes back, whatever the sentence was.
///
/// **Rewritten 20 August 2026.** This widget used to keep a list of spoken food
/// under the button, and a third of this file tested it: the rough figure, the
/// two exits on each row, how long a row had been waiting. That list is gone.
/// Aidan looked at a phone showing his spoken breakfast in one place and four
/// empty meal slots in another and said, correctly, that a second food system
/// had been built inside the first one. Spoken food now lands in the diary this
/// app already had, so what a row looks like is the diary's business and not
/// this widget's. What is left here is the sentence: saying it, sending it,
/// waiting for it visibly, and answering the one question.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/said/data/clip_store.dart';
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/said/presentation/say_what_you_ate_section.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

import '../household/fake_household_server.dart';

/// A microphone that never needs one. What it captures is set by the test —
/// including capturing nothing, which is what a tap that was not really a hold
/// produces on a real phone.
class StubMicrophone implements Microphone {
  bool permitted;
  File? captures;
  bool listening = false;
  bool abandoned = false;
  int started = 0;

  StubMicrophone({this.permitted = true, this.captures});

  @override
  Future<bool> allowed() async => permitted;

  @override
  Future<void> start() async {
    started += 1;
    listening = true;
  }

  @override
  Future<File?> stop() async {
    listening = false;
    return captures;
  }

  @override
  Future<void> abandon() async {
    listening = false;
    abandoned = true;
  }
}

/// Recordings held in memory rather than on disk — the real one writes files
/// through path_provider, which is not there in a test and is not what any of
/// this is about.
class RememberedClips extends ClipStore {
  final Map<String, File> kept = {};

  @override
  Future<File> keep(String clientId, File recording) async {
    kept[clientId] = recording;
    return recording;
  }

  @override
  Future<File?> forRow(String clientId) async => kept[clientId];

  @override
  Future<void> forget(String clientId) async => kept.remove(clientId);
}

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;
  late SaidRepository said;
  late RememberedClips clips;
  late StubMicrophone microphone;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    mini.today = today;
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api(), household);
    clips = RememberedClips();
    microphone = StubMicrophone();
    said = SaidRepository(api(), logger, outbox, clips);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  var told = 0;

  Widget screen() => MaterialApp(
        home: Scaffold(
          body: SayWhatYouAteSection(
            said: said,
            microphone: microphone,
            day: today,
            onChanged: () => told += 1,
          ),
        ),
      );

  Future<void> type(WidgetTester tester, String words) async {
    await tester.enterText(find.byType(TextField).first, words);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
  }

  group('the sentence goes to the household first', () {
    testWidgets('a sentence lands before anything has understood it',
        (tester) async {
      // The kitchen computer is not going to understand this one.
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await type(tester, 'two eggs and a slice of toast');

      expect(mini.entries.values.single['said'],
          'two eggs and a slice of toast');
      expect(mini.entries.values.single['state'], 'provisional');
    });

    testWidgets('and it stays on the ledger when nothing could be made of it',
        (tester) async {
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'whatever it was Emily made');

      expect(mini.entries.values.single['state'], 'provisional');
      expect(find.text(SayWhatYouAteSection.notUnderstood), findsOneWidget);
    });

    testWidgets('a sentence that was understood says nothing went wrong',
        (tester) async {
      mini.saidLines = const [
        {'label': 'Free range eggs', 'kcal': 143},
        {'label': 'Wholemeal toast', 'kcal': 96},
      ];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'two eggs and a slice of toast');

      expect(find.text(SayWhatYouAteSection.notUnderstood), findsNothing);
      expect(find.text(SayWhatYouAteSection.couldNotReach), findsNothing);
    });

    testWidgets('and the screen around it is told to go and fetch it',
        (tester) async {
      // The meal is on the ledger by now and not yet in this phone's diary.
      // Without this the food appears the *next* time the app is opened, which
      // from where a person is standing is indistinguishable from it not
      // having worked.
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      told = 0;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'a banana');
      expect(told, greaterThan(0));
    });

    testWidgets('the queue delivers the row before anything asks about it',
        (tester) async {
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'a banana');

      // A question about a row the Mini has never heard of is a plain 404, so
      // the order matters and is asserted rather than assumed.
      final entry = mini.requests.indexOf('POST /household/entry');
      final asked = mini.requests.indexOf('POST /household/said');
      expect(entry, isNonNegative);
      expect(asked, greaterThan(entry));
    });
  });

  group('there is no second list of food here', () {
    // The fault of 20 August 2026, kept as a test so it cannot come back
    // quietly. Whatever is on the household's ledger, this widget does not draw
    // it: the diary underneath is where food is listed, and two lists of the
    // same day on one screen is the thing Aidan stopped.
    setUp(() {
      mini.spoke(
          clientId: 'spoken-1',
          words: 'two eggs and a slice of toast',
          kcal: 300,
          since: '2026-08-19T09:00:00');
      mini.saidLines = const [];
    });

    testWidgets('a row waiting on the ledger is not drawn here',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('two eggs and a slice of toast'), findsNothing);
    });

    testWidgets('and neither is a calorie figure', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('this widget never asks the household for the day at all',
        (tester) async {
      // Stronger than checking the screen: if it does not fetch the day it
      // cannot grow a list of it later by accident.
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(mini.requests.where((r) => r.contains('/household/day')), isEmpty);
    });
  });

  group('waiting is visible', () {
    testWidgets('the button says what it is doing and cannot be used twice',
        (tester) async {
      // Aidan, 20 August 2026: "It didn't seem to advance so I tried again,
      // saying the same thing. Then it updated twice in quick succession." A
      // control that is working has to look like one.
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      mini.holdSaid = true;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a banana');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(find.text(SayWhatYouAteSection.workingOut), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // A second send while the first is in flight reaches nothing.
      final before = mini.requests.length;
      await tester.enterText(find.byType(TextField).first, 'a banana');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(mini.requests.length, before);

      mini.releaseSaid();
      await tester.pumpAndSettle();
      expect(find.text(SayWhatYouAteSection.workingOut), findsNothing);
    });

    testWidgets('a kitchen computer that cannot be reached is said out loud',
        (tester) async {
      mini.reachable = false;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'a banana');
      expect(find.text(SayWhatYouAteSection.couldNotReach), findsOneWidget);
    });
  });

  group('their hand wins', () {
    testWidgets('an answer for a row they corrected first is not applied',
        (tester) async {
      mini.saidWhy = 'it was changed by hand since';

      mini.saidLines = const [
        {'label': 'Eggs', 'kcal': 220}
      ];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'two eggs');

      expect(mini.entries.values.single['label'], 'two eggs');
      expect(mini.entries.values.single['state'], 'provisional');
    });

    testWidgets('and losing that race is not reported as a fault',
        (tester) async {
      // Their correction winning is the system working. Telling them something
      // went wrong would have them undo the correction they just made.
      mini.saidWhy = 'it was changed by hand since';

      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'two eggs');

      expect(find.text(SayWhatYouAteSection.notUnderstood), findsNothing);
    });
  });

  group('the one question', () {
    testWidgets('comes back and is asked', (tester) async {
      mini.saidLines = const [
        {'label': 'Fish and chips', 'kcal': 900}
      ];
      mini.saidQuestion = 'Were the chips oven or fried?';
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'fish and chips');

      expect(find.text('Were the chips oven or fried?'), findsOneWidget);
    });

    testWidgets('the answer goes back as another sentence, not a new kind of message',
        (tester) async {
      mini.saidLines = const [
        {'label': 'Fish and chips', 'kcal': 900}
      ];
      mini.saidQuestion = 'Were the chips oven or fried?';
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'fish and chips');

      await tester.enterText(find.byType(TextField).last, 'oven');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(mini.saidAsked.last['text'], contains('oven'));
      expect(mini.requests.where((r) => r == 'POST /household/said').length,
          greaterThanOrEqualTo(2));
    });
  });

  group('holding the button', () {
    testWidgets('holding starts listening and letting go stops it',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      expect(microphone.started, 1, reason: 'holding it starts listening');
      expect(microphone.listening, isFalse, reason: 'letting go stops it');
    });

    testWidgets('a phone that will not listen says so and leaves typing open',
        (tester) async {
      microphone.permitted = false;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      expect(find.text(SayWhatYouAteSection.noMicrophone), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('a hold that captured nothing puts no row on the day',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      expect(mini.entries, isEmpty);
    });
  });

  // The recording path is exercised here rather than through the screen on
  // purpose. Sending a recording reads a file off disk, and real file I/O
  // cannot be hurried along by the widget test binding's fake clock — a test
  // driven through the button would assert against a request that had simply
  // not been made yet and would fail for a reason that has nothing to do with
  // the behaviour. What the button does is tested above; what happens to the
  // sound is tested here.
  group('the recording itself', () {
    late File clip;

    setUp(() {
      clip = File('${Directory.systemTemp.path}/said-test.m4a')
        ..writeAsBytesSync(const [0, 1, 2, 3]);
    });

    tearDown(() {
      if (clip.existsSync()) clip.deleteSync();
    });

    test('goes to the kitchen computer as itself, not as words this phone made up',
        () async {
      // The transcriber is on the Mac Mini and is the one the kitchen panel has
      // used since long before any of this. This phone captures the sound and
      // hands it over; growing a second transcriber here is what is ruled out.
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      final name = await said.heard(day: today, recording: clip);
      await said.workOut(clientId: name, version: 0);

      expect(mini.saidAsked.single['clip'], isTrue);
      expect(mini.saidAsked.single['text'], isNull);
    });

    test('leaves a row on the day before anything has heard it', () async {
      mini.reachable = false;
      final name = await said.heard(day: today, recording: clip);
      await said.workOut(clientId: name, version: 0);

      mini.reachable = true;
      await outbox.drain();
      expect(mini.entries.values.single['label'],
          SaidRepository.notHeardYet,
          reason: 'a recording nobody has listened to has no words to show');
      expect(mini.entries.values.single['state'], 'provisional');
    });

    test('is kept while it is still owed to somebody', () async {
      mini.reachable = false;
      final name = await said.heard(day: today, recording: clip);
      await said.workOut(clientId: name, version: 0);
      expect(clips.kept.keys, [name]);
    });

    test('and let go of the moment it has been heard', () async {
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      final name = await said.heard(day: today, recording: clip);
      await said.workOut(clientId: name, version: 0);

      expect(clips.kept, isEmpty,
          reason: "the only copy of somebody's voice, kept no longer than it "
              'is owed to them');
    });

    test('and let go of when the person got there first', () async {
      mini.saidWhy = 'it was changed by hand since';
      mini.saidLines = const [
        {'label': 'Banana', 'kcal': 95}
      ];
      final name = await said.heard(day: today, recording: clip);
      await said.workOut(clientId: name, version: 0);

      expect(clips.kept, isEmpty,
          reason: 'their answer stands, so nothing is owed');
    });
  });

  group('the day itself', () {
    test('says the total is rough when any row is', () {
      final day = DayView.fromJson({
        'day': today,
        'person_id': 1,
        'settings': {'person_id': 1, 'daily_target_kcal': null},
        'entries': [
          {
            'id': 1,
            'label': 'Porridge',
            'owner_id': 1,
            'author_id': 1,
            'kcal': 250,
            'state': 'settled'
          },
          {
            'id': 2,
            'label': 'two eggs',
            'owner_id': 1,
            'author_id': 1,
            'kcal': 300,
            'state': 'provisional',
            'said': 'two eggs'
          },
        ],
      });
      expect(day.totalIsRough, isTrue);
      expect(day.workingOut.single.said, 'two eggs');
    });

    test('and clears itself the moment the last one settles', () {
      final day = DayView.fromJson({
        'day': today,
        'person_id': 1,
        'settings': {'person_id': 1, 'daily_target_kcal': null},
        'entries': [
          {
            'id': 1,
            'label': 'Porridge',
            'owner_id': 1,
            'author_id': 1,
            'kcal': 250,
            'state': 'settled'
          },
        ],
      });
      expect(day.totalIsRough, isFalse);
      expect(day.workingOut, isEmpty);
    });

    test('a row with no lifecycle on it at all reads as settled', () {
      // Every row that was on a day before any of this existed. The mark must
      // not turn a day somebody has already lived into a day full of unfinished
      // rows.
      final item = LoggedItem.fromJson(
          {'label': 'Porridge', 'owner_id': 1, 'author_id': 1, 'kcal': 250});
      expect(item.stillBeingWorkedOut, isFalse);
      expect(item.version, 0);
    });
  });
}
