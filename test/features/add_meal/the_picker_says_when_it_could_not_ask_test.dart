/// Opening the food picker when the house cannot be reached.
///
/// Aidan, away from home on 27 August, on build 60: *"Now my own foods aren't
/// showing at all. It simply says “Search results” then “please enter a search
/// word”."*
///
/// His foods were all still there. They live on the Mac Mini and are fetched
/// every time this screen opens, and he had no route to it — so the answer came
/// back as an empty list. An empty list is also what a household that owns
/// nothing looks like, and the screen drew the same thing for both: the prompt
/// it shows before anybody has typed anything.
///
/// That prompt is a lie by omission in this case. "Type something to search"
/// and "I could not ask the house" send a person to different places, and the
/// second one is not their fault or their search's.
///
/// The search box below is deliberately left alone. It still falls through to
/// the public database on an unreachable house — there the empty list is
/// followed by an answer from somewhere else, which speaks for itself. The
/// opening list has nothing to fall through to, which is why it has to say so
/// itself.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

import '../household/fake_household_server.dart';
import 'fake_products_repository.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late FakeProductsRepository theInternet;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    theInternet = FakeProductsRepository();
    household = HouseholdRepository(
        ConfigDao(db), HouseholdApi(baseUrl: 'http://mini', client: mini.client));
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  /// The picker, wired to a house that answers or one that cannot be reached.
  ProductsBloc picker({required bool houseIsReachable}) {
    final api = HouseholdApi(
        baseUrl: 'http://mini',
        client: houseIsReachable ? mini.client : mini.unreachable());
    return ProductsBloc(
        SearchProductsUseCase(
            theInternet, FoodFinder(api, household, FoodItemDao(db))),
        GetConfigUsecase(ConfigRepository(ConfigDao(db))));
  }

  /// Open the screen and let the opening list finish arriving.
  Future<ProductsState> whatTheScreenShows({required bool reachable}) async {
    final bloc = picker(houseIsReachable: reachable);
    bloc.add(const LoadOurFoodsEvent());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final state = bloc.state;
    await bloc.close();
    return state;
  }

  test('away from home it says it could not ask, not "type something"',
      () async {
    mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
    mini.addFood(name: 'Cheddar', kcal100: 416);

    final state = await whatTheScreenShows(reachable: false);

    expect(state, isA<OurFoodsUnreachableState>(),
        reason: 'his foods are there; the route to them is not, and the '
            'screen has to be able to tell him which');
  });

  test('at home it shows his own foods, exactly as it always did', () async {
    mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
    mini.addFood(name: 'Cheddar', kcal100: 416);

    final state = await whatTheScreenShows(reachable: true);

    expect(state, isA<ProductsLoadedState>());
    expect((state as ProductsLoadedState).ours, isTrue);
    expect(state.products.map((m) => m.name), ['Oat biscuits', 'Cheddar']);
  });

  test('a house that answers and owns nothing is left exactly as it was',
      () async {
    // Nothing added to the house. It answered; the answer was "none". There is
    // nothing to say, and saying "couldn't reach the house" here would be a
    // second wrong sentence rather than a fix for the first.
    final state = await whatTheScreenShows(reachable: true);

    expect(state, isA<ProductsInitial>(),
        reason: 'the screen keeps its ordinary opening prompt');
  });
}
