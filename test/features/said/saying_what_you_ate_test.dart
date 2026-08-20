/// Saying what you ate, and rows that are still being worked out.
///
/// Behaviour under test (Release G, TM-0027 + TM-0028 — the phone half):
///
///  * the row goes on the day the moment you let go, before anything has
///    understood it. Not after. The kitchen computer being asleep must cost you
///    a rough number, never the thing you said;
///  * while it is rough it says so, next to the figure and not in a caption
///    somewhere else, and it says how long it has been sitting there;
///  * a correction made while the answer is on the wire wins, permanently;
///  * both exits are on the row the whole time — say it again, or take it off;
///  * typing a sentence and speaking one are the same thing to everything
///    downstream, so the phone offers both and neither is a lesser path;
///  * and at most one question ever comes back, whatever the sentence was.
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

  Widget screen({bool figuresOff = false, bool canRetire = true}) => MaterialApp(
        home: FiguresScope(
          figuresOff: figuresOff,
          child: Scaffold(
            body: SayWhatYouAteSection(
              repository: days,
              said: said,
              microphone: microphone,
              logger: canRetire ? logger : null,
              day: today,
            ),
          ),
        ),
      );

  Future<void> type(WidgetTester tester, String words) async {
    await tester.enterText(find.byType(TextField).first, words);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
  }

  group('the row goes on the day first', () {
    testWidgets('a sentence lands before anything has understood it',
        (tester) async {
      // The kitchen computer is not going to understand this one.
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await type(tester, 'two eggs and a slice of toast');

      expect(mini.entries.values.single['said'],
          'two eggs and a slice of toast');
      // ignore: avoid_print
      print('PROBE requests=${mini.requests} asked=${mini.saidAsked}');
      expect(mini.entries.values.single['state'], 'provisional');
      expect(find.text('two eggs and a slice of toast'), findsOneWidget);
    });

    testWidgets('and it stays there when nothing could be made of it',
        (tester) async {
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'whatever it was Emily made');

      expect(find.text('whatever it was Emily made'), findsOneWidget);
      expect(find.textContaining(SayWhatYouAteSection.workingOut),
          findsOneWidget);
    });

    testWidgets('a sentence understood at once leaves nothing rough behind',
        (tester) async {
      mini.saidLines = const [
        {'label': 'Free range eggs', 'kcal': 143},
        {'label': 'Wholemeal toast', 'kcal': 96},
      ];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await type(tester, 'two eggs and a slice of toast');

      expect(find.textContaining(SayWhatYouAteSection.workingOut), findsNothing);
      expect(find.text(SayWhatYouAteSection.heading), findsNothing);
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

  group('while it is still rough', () {
    setUp(() {
      mini.spoke(
          clientId: 'spoken-1',
          words: 'two eggs and a slice of toast',
          kcal: 300,
          since: '2026-08-19T09:00:00');
      mini.saidLines = const [];
    });

    testWidgets('the words are shown, not a made-up label', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('two eggs and a slice of toast'), findsOneWidget);
    });

    testWidgets('the figure says it is a guess', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('about 300 kcal'), findsOneWidget);
    });

    testWidgets('with figures off there is no number and still a row',
        (tester) async {
      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('kcal'), findsNothing);
      expect(find.text('two eggs and a slice of toast'), findsOneWidget);
    });

    testWidgets('both exits are on the row', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text(SayWhatYouAteSection.tryAgain), findsOneWidget);
      expect(find.text(SayWhatYouAteSection.takeItOff), findsOneWidget);
    });

    testWidgets('taking it off queues a retire and clears the row',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(SayWhatYouAteSection.takeItOff));
      await tester.pumpAndSettle();

      expect(find.text('two eggs and a slice of toast'), findsNothing);
      expect(await outbox.pendingCount(), 1);
    });

    testWidgets('saying it again asks the kitchen computer once more',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      final before = mini.saidAsked.length;
      await tester.tap(find.text(SayWhatYouAteSection.tryAgain));
      await tester.pumpAndSettle();
      expect(mini.saidAsked.length, greaterThan(before));
    });
  });

  group('how long it has been sitting there', () {
    // A row from four hours ago and one from four seconds ago must not read the
    // same. One of them is waiting and the other is stuck.
    final at = DateTime(2026, 8, 19, 18, 0);

    test('a moment ago', () {
      expect(
          SayWhatYouAteSection.waitingFor(at.subtract(const Duration(seconds: 20)),
              now: at),
          'just now');
    });

    test('minutes', () {
      expect(
          SayWhatYouAteSection.waitingFor(at.subtract(const Duration(minutes: 7)),
              now: at),
          '7 minutes ago');
    });

    test('hours', () {
      expect(
          SayWhatYouAteSection.waitingFor(at.subtract(const Duration(hours: 4)),
              now: at),
          '4 hours ago');
    });

    test('days', () {
      expect(
          SayWhatYouAteSection.waitingFor(at.subtract(const Duration(days: 2)),
              now: at),
          '2 days ago');
    });

    test('nothing at all when nobody wrote it down', () {
      expect(SayWhatYouAteSection.waitingFor(null), '');
    });

    testWidgets('and it is on the row', (tester) async {
      mini.spoke(
          clientId: 'spoken-1',
          words: 'a banana',
          since: DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String());
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.textContaining('3 hours ago'), findsOneWidget);
    });
  });

  group('their hand wins', () {
    testWidgets('an answer for a row they corrected first is not applied',
        (tester) async {
      mini.spoke(clientId: 'spoken-1', words: 'two eggs', kcal: 300);
      mini.saidWhy = 'it was changed by hand since';
      mini.saidLines = const [
        {'label': 'Eggs', 'kcal': 220}
      ];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(SayWhatYouAteSection.tryAgain));
      await tester.pumpAndSettle();

      expect(mini.entries['spoken-1']!['kcal'], 300);
      expect(mini.entries['spoken-1']!['label'], 'two eggs');
    });

    testWidgets('the version the row is at travels with the question',
        (tester) async {
      mini.spoke(clientId: 'spoken-1', words: 'two eggs');
      mini.entries['spoken-1']!['version'] = 3;
      mini.saidLines = const [];
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.tap(find.text(SayWhatYouAteSection.tryAgain));
      await tester.pumpAndSettle();

      expect(mini.saidAsked.last['version'], 3);
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
          SayWhatYouAteSection.notHeardYet,
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
