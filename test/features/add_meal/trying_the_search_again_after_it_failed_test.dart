/// Trying a search again, after it failed, actually tries.
///
/// Aidan said on 24 August 2026, of Open Food Facts failures he had been living
/// with for about a week: *"It hasn't worked any of the times I've retried
/// manually so I'm not sure if that's helpful."* Requests made from a Mac that
/// afternoon said a couple of tries should land most times, so the question was
/// whether his try was ever a try at all.
///
/// It was not. The search screen remembered the last words searched for and
/// silently dropped any search carrying the same ones — and it wrote those
/// words down *before* making the request, so a failed search for "peanut
/// butter" had already recorded "peanut butter". Pressing search again matched,
/// and was discarded: no request, no spinner, no fresh error. It stayed that
/// way however many times he pressed, and stayed that way after Open Food Facts
/// started answering again.
///
/// The saving the comparison was there for is real and is kept: searching the
/// same words again straight after they *worked* still asks nobody, because the
/// results are already on the screen. It is only a failure that makes the same
/// words worth asking about a second time.
///
/// An earlier version of this file proved the broken behaviour, at commit
/// 93450d0, before anything was changed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';

import 'fake_products_repository.dart';

void main() {
  late AppDatabase db;
  late FakeProductsRepository theInternet;
  late ProductsBloc bloc;
  late FoodBloc otherTab;

  setUp(() {
    db = AppDatabase.createInMemory();
    theInternet = FakeProductsRepository();
    final config = GetConfigUsecase(ConfigRepository(ConfigDao(db)));
    final search = SearchProductsUseCase(theInternet);
    bloc = ProductsBloc(search, config);
    otherTab = FoodBloc(search, config);
  });

  tearDown(() async {
    await bloc.close();
    await otherTab.close();
    await db.close();
  });

  /// Let the bloc finish whatever the last event set going.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 1));

  Future<void> search(String words) async {
    bloc.add(LoadProductsEvent(searchString: words));
    await settle();
  }

  group('a search that failed, tried again with the same words', () {
    test('goes and asks again', () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');
      expect(bloc.state, isA<ProductsFailedState>(),
          reason: 'the first search should have failed');
      expect(theInternet.searchesMade, ['peanut butter']);

      // He types the same thing and presses search again.
      await search('peanut butter');

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter']);
    });

    test('shows the spinner, so the press visibly does something', () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');

      final seen = <ProductsState>[];
      final watching = bloc.stream.listen(seen.add);
      await search('peanut butter');
      await watching.cancel();

      expect(seen.first, isA<ProductsLoadingState>());
    });

    test('and finds the food once the database is answering again', () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');

      theInternet.searchesFailWith = null; // Open Food Facts is back
      await search('peanut butter');

      expect(bloc.state, isA<ProductsLoadedState>());
    });

    test('and keeps trying for as long as he keeps pressing', () async {
      theInternet.searchesFailWith = 503;
      for (var i = 0; i < 5; i++) {
        await search('peanut butter');
      }
      expect(theInternet.searchesMade, hasLength(5));
    });

    test('the second search tab does the same', () async {
      theInternet.searchesFailWith = 503;
      otherTab.add(const LoadFoodEvent(searchString: 'peanut butter'));
      await settle();
      otherTab.add(const LoadFoodEvent(searchString: 'peanut butter'));
      await settle();

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter']);
    });
  });

  group('a search that worked, tried again with the same words', () {
    test('asks nobody, because the results are already on the screen',
        () async {
      await search('peanut butter');
      expect(bloc.state, isA<ProductsLoadedState>());
      expect(theInternet.searchesMade, ['peanut butter']);

      await search('peanut butter');

      expect(theInternet.searchesMade, ['peanut butter'],
          reason: 'the saving the comparison exists for is kept');
    });

    test('and does not blank the results with a spinner', () async {
      await search('peanut butter');

      final seen = <ProductsState>[];
      final watching = bloc.stream.listen(seen.add);
      await search('peanut butter');
      await watching.cancel();

      expect(seen, isEmpty);
    });
  });

  group('the Retry button under the error message', () {
    test('still sends a fresh request', () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');

      bloc.add(const RefreshProductsEvent());
      await settle();

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter']);
    });

    test('and shows the results when the database answers', () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');

      theInternet.searchesFailWith = null;
      bloc.add(const RefreshProductsEvent());
      await settle();

      expect(bloc.state, isA<ProductsLoadedState>());
    });

    test('and a search for the same words after it does not repeat the work',
        () async {
      theInternet.searchesFailWith = 503;
      await search('peanut butter');

      theInternet.searchesFailWith = null;
      bloc.add(const RefreshProductsEvent());
      await settle();

      await search('peanut butter');

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter'],
          reason: 'the Retry succeeded, so the words are worth nothing again');
    });
  });

  test('typing something different always goes and asks', () async {
    theInternet.searchesFailWith = 503;
    await search('peanut butter');
    await search('cheddar');

    expect(theInternet.searchesMade, ['peanut butter', 'cheddar']);
  });
}
