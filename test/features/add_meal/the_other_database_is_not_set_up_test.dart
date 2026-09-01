/// The second search tab has never worked, and it did not say so.
///
/// The "Food" tab searches the United States Department of Agriculture's food
/// database, which requires a key. The key this app was built with is eight
/// characters long; a real one is forty. Asked with it, that database answers
/// `403 API_KEY_INVALID` every time, in a fifth of a second.
///
/// The screen showed that as "Error while fetching product data" with a Retry
/// button — the same words, the same button and the same cloud-off picture as
/// the Products tab shows when Open Food Facts is having a bad morning. One of
/// those is worth pressing Retry on and the other can never work, and on 1
/// September Aidan met both in one sitting and reasonably read them as one
/// fault.
///
/// So a refused key says it is not set up, and offers nothing to press.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';

import 'fake_products_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What the USDA actually returns for a key it does not recognise, copied
  /// from a real call on 1 September 2026.
  const refusal = '{"error":{"code":"API_KEY_INVALID",'
      '"message":"An invalid api_key was supplied."}}';

  test('a key the database will not accept is told apart from a bad line',
      () async {
    final source = FDCDataSource(
        client: MockClient((_) async => http.Response(refusal, 403)));

    await expectLater(
      source.fetchSearchWordResults('plum tomatoes'),
      throwsA(isA<FoodDatabaseNotSetUp>()),
    );
  });

  test('and anything else it refuses is not called a setup problem', () async {
    final source = FDCDataSource(
        client: MockClient((_) async => http.Response('<html>no</html>', 503)));

    await expectLater(
      source.fetchSearchWordResults('plum tomatoes'),
      throwsA(isNot(isA<FoodDatabaseNotSetUp>())),
    );
  });

  test('an answer it accepts still comes back as results', () async {
    final source = FDCDataSource(
        client: MockClient((_) async => http.Response('{"foods":[]}', 200)));

    final result = await source.fetchSearchWordResults('plum tomatoes');
    expect(result.foods, isEmpty);
  });

  group('and the tab the person is looking at', () {
    late AppDatabase db;
    late FakeProductsRepository theInternet;

    setUp(() {
      db = AppDatabase.createInMemory();
      theInternet = FakeProductsRepository();
    });
    tearDown(() async => db.close());

    FoodBloc theFoodTab() => FoodBloc(SearchProductsUseCase(theInternet),
        GetConfigUsecase(ConfigRepository(ConfigDao(db))));

    test('says it is not set up, rather than that the search failed', () async {
      theInternet.searchesFailWith = const FoodDatabaseNotSetUp();
      final tab = theFoodTab();

      tab.add(const LoadFoodEvent(searchString: 'plum tomatoes'));
      await expectLater(
          tab.stream,
          emitsInOrder(
              [isA<FoodLoadingState>(), isA<FoodSourceNotSetUpState>()]));
    });

    test('still calls an ordinary outage an outage', () async {
      theInternet.searchesFailWith = 503;
      final tab = theFoodTab();

      tab.add(const LoadFoodEvent(searchString: 'plum tomatoes'));
      await expectLater(tab.stream,
          emitsInOrder([isA<FoodLoadingState>(), isA<FoodFailedState>()]));
    });
  });
}
