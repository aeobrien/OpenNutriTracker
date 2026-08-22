/// The shopping list, read in a shop.
///
/// Behaviour under test (Release 6, TM-0022 / BC-0023). Compiling the plan
/// into a list is old and the Mac Mini's; what is new is that the list is on
/// the phone, where it is actually read.
///
/// Everything here is shaped by one line in the card: the list is read
/// standing in a supermarket. That is a place with famously bad signal and a
/// trolley in one hand, so the list is kept on the phone, ticking works with
/// no network at all, and only making the list needs the house.
///
/// The carrying test is [the list is there with no Mac Mini at all]. Every
/// other test here would pass on a version that fetched the list fresh each
/// time — and that version is useless precisely where the list is used. A
/// shopping list that needs a network is a shopping list that is not there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/shopping/data/shopping_repository.dart';
import 'package:opennutritracker/features/shopping/presentation/shopping_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late ShoppingRepository shopping;
  late Outbox outbox;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    outbox = Outbox.of(db, api);
    shopping = ShoppingRepository(api, household, ConfigDao(db), outbox);
  });

  tearDown(() async => db.close());

  Future<void> openIt(WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(home: ShoppingScreen(repository: shopping)));
    await tester.pumpAndSettle();
  }

  void aList() {
    mini.addShoppingLine('Chicken thighs 400g', putItThere: const [
      {'title': 'Chicken traybake', 'day': '2026-08-24'},
      {'title': 'Chicken traybake', 'day': '2026-08-27'},
    ]);
    mini.addShoppingLine('Tenderstem broccoli', putItThere: const [
      {'title': 'Chicken traybake', 'day': '2026-08-24'},
    ]);
    mini.addShoppingLine('Bin bags');
  }

  group('reading it', () {
    testWidgets('the list is there with no Mac Mini at all', (tester) async {
      // The carrying test. The list is read in a shop; a version that fetched
      // it fresh each time would be useless in exactly the place it is used.
      aList();
      await shopping.list();
      mini.reachable = false;

      await openIt(tester);

      expect(find.text('Chicken thighs 400g'), findsOneWidget);
      expect(find.text('Bin bags'), findsOneWidget);
    });

    testWidgets('a line says which meals put it there', (tester) async {
      // The question a shopping list gets asked in a shop: why am I buying
      // this much chicken.
      aList();
      await openIt(tester);

      await tester.tap(find.byTooltip(ShoppingScreen.whyThis).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Chicken traybake'), findsOneWidget);
      expect(find.textContaining('2 times'), findsOneWidget,
          reason: 'the same dinner twice is exactly why the number is what it '
              'is, and saying it once hides that');
    });

    testWidgets('a line nobody planned is not asked about', (tester) async {
      // Somebody typed "bin bags". No meal is responsible and offering to
      // explain it would be offering to make something up.
      aList();
      await openIt(tester);

      expect(find.byTooltip(ShoppingScreen.whyThis), findsNWidgets(2));
    });

    testWidgets('an empty list says so', (tester) async {
      await openIt(tester);
      expect(find.text(ShoppingScreen.nothingOnIt), findsOneWidget);
    });
  });

  group('ticking', () {
    testWidgets('a tick lands with no signal and waits to be sent',
        (tester) async {
      // The whole reason ticking goes through the queue. An aisle has no
      // network and a tick that needed one would be a tick that did not
      // happen.
      aList();
      await shopping.list();
      mini.reachable = false;
      await openIt(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(await outbox.pendingCount(), 1);
      final line = tester.widget<Text>(find.text('Chicken thighs 400g'));
      expect(line.style?.decoration, TextDecoration.lineThrough,
          reason: 'the tick is not on the screen, so somebody in a shop has '
              'no idea whether it took');
    });

    testWidgets('a ticked line stays on the screen', (tester) async {
      // A list that empties as you shop leaves nothing to check at the till.
      aList();
      await openIt(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Chicken thighs 400g'), findsOneWidget);
    });

    testWidgets('a tick reaches the house when there is signal again',
        (tester) async {
      aList();
      await shopping.list();
      mini.reachable = false;
      await openIt(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      mini.reachable = true;
      await outbox.drain();

      expect(mini.shopping.first['done'], 1);
      expect(await outbox.pendingCount(), 0);
    });

    testWidgets('a tick says which way rather than the other way',
        (tester) async {
      // Sent as "ticked", not as "toggle". A toggle arriving twenty minutes
      // late flips whatever it finds instead of what was tapped.
      aList();
      await shopping.list();
      mini.reachable = false;
      await openIt(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final queued = await outbox.pending();
      expect(queued.single.body, contains('"done":true'));
    });

    testWidgets('a line can be taken off the list', (tester) async {
      aList();
      await openIt(tester);
      await tester.tap(find.byTooltip('Take it off').first);
      await tester.pumpAndSettle();

      expect(find.text('Chicken thighs 400g'), findsNothing);
    });
  });

  group('making it', () {
    testWidgets('pressing the button makes the list from the plan',
        (tester) async {
      mini.compilesTo = [
        {'id': 9, 'text': 'Salmon 2 fillets', 'done': 0, 'from_meals': const [
          {'title': 'Baked salmon', 'day': '2026-08-25'},
        ]},
      ];
      await openIt(tester);
      await tester.tap(find.text(ShoppingScreen.makeIt));
      await tester.pumpAndSettle();

      expect(mini.madeTheList, 1);
      expect(find.text('Salmon 2 fillets'), findsOneWidget);
      expect(find.textContaining('1 thing to buy'), findsOneWidget);
    });

    testWidgets('a week with nothing to buy says so rather than going quiet',
        (tester) async {
      await openIt(tester);
      await tester.tap(find.text(ShoppingScreen.makeIt));
      await tester.pumpAndSettle();

      expect(find.text(ShoppingScreen.madeNothing), findsOneWidget);
    });

    testWidgets('with no Mac Mini it says so and leaves the list alone',
        (tester) async {
      // Not queued. Compiling reads the whole plan, and pressing a button now
      // to find out much later that it compiled a week you did not mean is
      // worse than being told you cannot.
      aList();
      await shopping.list();
      mini.reachable = false;
      await openIt(tester);

      await tester.tap(find.text(ShoppingScreen.makeIt));
      await tester.pumpAndSettle();

      expect(find.text(ShoppingScreen.cannotMakeIt), findsOneWidget);
      expect(find.text('Chicken thighs 400g'), findsOneWidget);
      expect(await outbox.pendingCount(), 0,
          reason: 'compiling was queued, so a week nobody meant will be '
              'compiled the next time this phone finds signal');
    });
  });
}
