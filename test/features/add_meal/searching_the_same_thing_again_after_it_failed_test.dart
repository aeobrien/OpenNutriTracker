/// What actually happens when a search fails and the person tries again.
///
/// Aidan said on 24 August 2026, of the Open Food Facts failures he had been
/// living with for about a week: *"It hasn't worked any of the times I've
/// retried manually so I'm not sure if that's helpful."* Twenty requests made
/// from a Mac that afternoon came back six good and fourteen refused, which
/// says a couple of tries should land most times. His experience says
/// otherwise, so before proposing that the app retry by itself, the question
/// is whether his try was ever a try at all.
///
/// It was not, on one of the two paths. This file is the evidence, and it does
/// not fix anything.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';

import 'fake_products_repository.dart';

void main() {
  late AppDatabase db;
  late FakeProductsRepository theInternet;
  late ProductsBloc bloc;

  setUp(() {
    db = AppDatabase.createInMemory();
    theInternet = FakeProductsRepository();
    bloc = ProductsBloc(
      SearchProductsUseCase(theInternet),
      GetConfigUsecase(ConfigRepository(ConfigDao(db))),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  /// Let the bloc finish whatever the last event set going.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 1));

  group('a search that failed, tried again with the same words', () {
    test('asks nobody the second time', () async {
      theInternet.searchesFailWith = 503;

      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();
      expect(bloc.state, isA<ProductsFailedState>(),
          reason: 'the first search should have failed');
      expect(theInternet.searchesMade, ['peanut butter']);

      // He types the same thing and presses search again.
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      expect(theInternet.searchesMade, ['peanut butter'],
          reason: 'the second press sent nothing — this is the finding');
    });

    test('leaves the screen exactly as it was, so nothing looks like it tried',
        () async {
      theInternet.searchesFailWith = 503;
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      final seen = <ProductsState>[];
      final watching = bloc.stream.listen(seen.add);

      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();
      await watching.cancel();

      expect(seen, isEmpty,
          reason: 'no spinner, no new error — the press does nothing at all');
    });

    test('and it stays dead however many times he tries', () async {
      theInternet.searchesFailWith = 503;
      for (var i = 0; i < 5; i++) {
        bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
        await settle();
      }
      expect(theInternet.searchesMade, ['peanut butter']);
    });

    test('even once the database has come back up', () async {
      theInternet.searchesFailWith = 503;
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      theInternet.searchesFailWith = null; // Open Food Facts is answering again
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      expect(bloc.state, isA<ProductsFailedState>(),
          reason: 'still the error screen, with a working database behind it');
      expect(theInternet.searchesMade, ['peanut butter']);
    });

    test('typing something different does go and ask', () async {
      theInternet.searchesFailWith = 503;
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      bloc.add(const LoadProductsEvent(searchString: 'peanut butter '));
      await settle();

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter '],
          reason: 'a single trailing space is enough to make it a real search');
    });
  });

  group('the Retry button under the error message', () {
    test('does send a fresh request', () async {
      theInternet.searchesFailWith = 503;
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      bloc.add(const RefreshProductsEvent());
      await settle();

      expect(theInternet.searchesMade, ['peanut butter', 'peanut butter']);
    });

    test('and shows the results when the database answers', () async {
      theInternet.searchesFailWith = 503;
      bloc.add(const LoadProductsEvent(searchString: 'peanut butter'));
      await settle();

      theInternet.searchesFailWith = null;
      bloc.add(const RefreshProductsEvent());
      await settle();

      expect(bloc.state, isA<ProductsLoadedState>());
    });
  });
}
