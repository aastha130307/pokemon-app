import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_app/models/pokemon.dart';
import 'package:pokemon_app/models/pokemon_detail.dart';
import 'package:pokemon_app/providers/favorites_provider.dart';
import 'package:pokemon_app/providers/pokemon_provider.dart';
import 'package:pokemon_app/screens/favorites_screen.dart';
import 'package:pokemon_app/screens/pokemon_detail_screen.dart';
import 'package:pokemon_app/screens/pokemon_list_screen.dart';
import 'package:pokemon_app/services/favorites_storage_service.dart';
import 'package:pokemon_app/services/pokemon_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryFavoritesStorage extends FavoritesStorageService {
  Set<int> _storage;

  InMemoryFavoritesStorage([Set<int>? initial]) : _storage = initial ?? <int>{};

  @override
  Future<Set<int>> loadFavorites() async => Set<int>.from(_storage);

  @override
  Future<bool> saveFavorites(Set<int> favorites) async {
    _storage = Set<int>.from(favorites);
    return true;
  }

  @override
  Future<bool> clearFavorites() async {
    _storage.clear();
    return true;
  }

  Set<int> get currentStorage => _storage;
}

class TestMockApiService extends PokemonApiService {
  @override
  Future<PokemonListResponse> fetchPokemonList(
      {int limit = 20, int offset = 0}) async {
    // Only returns Bulbasaur (ID 1) in currently loaded list
    return const PokemonListResponse(
      count: 1,
      results: [
        Pokemon(
          id: 1,
          name: 'bulbasaur',
          url: 'https://pokeapi.co/api/v2/pokemon/1/',
          imageUrl: 'https://example.com/1.png',
        ),
      ],
    );
  }

  @override
  Future<PokemonDetail> fetchPokemonDetail(dynamic idOrName) async {
    final id = int.tryParse(idOrName.toString()) ?? 150;
    String name = 'pokemon-$id';
    if (id == 1) name = 'bulbasaur';
    if (id == 150) name = 'mewtwo';

    return PokemonDetail(
      id: id,
      name: name,
      height: 20,
      weight: 1220,
      types: const [PokemonType(slot: 1, name: 'psychic')],
      abilities: const [
        PokemonAbility(name: 'pressure', isHidden: false, slot: 1)
      ],
      stats: const [PokemonStat(name: 'hp', baseStat: 106, effort: 0)],
      sprites:
          const PokemonSprites(frontDefault: 'https://example.com/mewtwo.png'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Favorites Storage & Provider Unit Tests (Requirements A - D, I, J)',
      () {
    test('A. Initial persisted favorites are loaded correctly', () async {
      final storage = InMemoryFavoritesStorage({4, 7, 25});
      final notifier = FavoritesNotifier(storage);

      // Await initial load
      await Future.delayed(Duration.zero);

      expect(notifier.state.isInitialized, isTrue);
      expect(notifier.state.favoriteIds, containsAll([4, 7, 25]));
      expect(notifier.isFavorite(25), isTrue);
      expect(notifier.isFavorite(1), isFalse);
    });

    test('B. toggleFavorite adds an ID', () async {
      final storage = InMemoryFavoritesStorage();
      final notifier = FavoritesNotifier(storage);
      await Future.delayed(Duration.zero);

      expect(notifier.isFavorite(25), isFalse);
      await notifier.toggleFavorite(25);

      expect(notifier.isFavorite(25), isTrue);
      expect(notifier.state.favoriteIds, contains(25));
    });

    test('C. toggleFavorite removes an ID', () async {
      final storage = InMemoryFavoritesStorage({25});
      final notifier = FavoritesNotifier(storage);
      await Future.delayed(Duration.zero);

      expect(notifier.isFavorite(25), isTrue);
      await notifier.toggleFavorite(25);

      expect(notifier.isFavorite(25), isFalse);
      expect(notifier.state.favoriteIds, isEmpty);
    });

    test('D. Changes are persisted to storage', () async {
      final storage = InMemoryFavoritesStorage();
      final notifier = FavoritesNotifier(storage);
      await Future.delayed(Duration.zero);

      await notifier.toggleFavorite(1);
      await notifier.toggleFavorite(4);

      expect(storage.currentStorage, containsAll([1, 4]));

      await notifier.removeFavorite(1);
      expect(storage.currentStorage, equals({4}));
    });

    test(
        'I. Favorites survive provider reinitialization using persisted storage',
        () async {
      final sharedStorage = InMemoryFavoritesStorage();
      final firstNotifier = FavoritesNotifier(sharedStorage);
      await Future.delayed(Duration.zero);

      await firstNotifier.addFavorite(6);
      await firstNotifier.addFavorite(9);

      // Reinitialize second notifier using the same storage
      final secondNotifier = FavoritesNotifier(sharedStorage);
      await Future.delayed(Duration.zero);

      expect(secondNotifier.state.favoriteIds, containsAll([6, 9]));
      expect(secondNotifier.isFavorite(6), isTrue);
      expect(secondNotifier.isFavorite(9), isTrue);
    });

    test('J. Empty favorites state works cleanly without errors', () async {
      final storage = InMemoryFavoritesStorage();
      final notifier = FavoritesNotifier(storage);
      await Future.delayed(Duration.zero);

      expect(notifier.state.favoriteIds, isEmpty);
      expect(notifier.isFavorite(1), isFalse);
      expect(notifier.state.isInitialized, isTrue);
    });

    test(
        'SharedPreferences persistence with mock values handles empty and corrupted values',
        () async {
      SharedPreferences.setMockInitialValues({
        'favorite_pokemon_ids': ['1', 'invalid', '25', '-5'],
      });

      final storage = FavoritesStorageService();
      final loaded = await storage.loadFavorites();

      expect(loaded, equals({1, 25}));
    });
  });

  group(
      'Reactive Synchronization Between List, Detail, and Favorites (Requirements E - H, K)',
      () {
    testWidgets(
        'E & F. Favoriting from List causes the same provider state to be observed in Detail and Favorites',
        (tester) async {
      final storage = InMemoryFavoritesStorage();
      final testApi = TestMockApiService();

      final container = ProviderContainer(
        overrides: [
          favoritesStorageServiceProvider.overrideWithValue(storage),
          pokemonApiServiceProvider.overrideWithValue(testApi),
        ],
      );

      // Pump List Screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PokemonListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Bulbasaur is loaded
      expect(find.text('Bulbasaur'), findsOneWidget);

      // Check initial favorite state: heart is unfilled
      expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
      expect(container.read(favoritesProvider).contains(1), isFalse);

      // Tap favorite button on Bulbasaur's card
      final favoriteButton = find.byTooltip('Add to favorites').first;
      await tester.tap(favoriteButton);
      await tester.pumpAndSettle();

      // State is now favorited in centralized provider!
      expect(container.read(favoritesProvider).contains(1), isTrue);

      // Now pump Detail Screen for Bulbasaur using same container
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PokemonDetailScreen(pokemonId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Detail Screen immediately shows filled heart without any reload!
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets(
        'G. Unfavoriting from Detail removes the same ID from centralized state and List observes it',
        (tester) async {
      final storage = InMemoryFavoritesStorage({1});
      final testApi = TestMockApiService();

      final container = ProviderContainer(
        overrides: [
          favoritesStorageServiceProvider.overrideWithValue(storage),
          pokemonApiServiceProvider.overrideWithValue(testApi),
        ],
      );

      // Pump Detail Screen for ID 1
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PokemonDetailScreen(pokemonId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initially filled heart
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(container.read(favoritesProvider).contains(1), isTrue);

      // Tap favorite button in Detail AppBar to unfavorite
      await tester.tap(find.byTooltip('Remove from favorites'));
      await tester.pumpAndSettle();

      // Centralized state immediately updated to false!
      expect(container.read(favoritesProvider).contains(1), isFalse);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Now render List screen: Bulbasaur's card also shows unfilled heart
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PokemonListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Add to favorites'), findsWidgets);
      expect(container.read(favoritesProvider).contains(1), isFalse);
    });

    testWidgets(
        'H. Unfavoriting from Favorites screen immediately updates centralized state',
        (tester) async {
      final storage = InMemoryFavoritesStorage({1});
      final testApi = TestMockApiService();

      final container = ProviderContainer(
        overrides: [
          favoritesStorageServiceProvider.overrideWithValue(storage),
          pokemonApiServiceProvider.overrideWithValue(testApi),
        ],
      );

      // Pump Favorites Screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify item is present
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);

      // Tap to remove favorite
      await tester.tap(find.byTooltip('Remove from favorites'));
      await tester.pumpAndSettle();

      // Centralized state updated immediately and empty state appears
      expect(container.read(favoritesProvider).contains(1), isFalse);
      expect(find.text('No Favorites Yet'), findsOneWidget);
    });

    testWidgets(
        'K. A favorite ID not in currently loaded List still appears in Favorites after being resolved by ID',
        (tester) async {
      // Favorited ID 150 (Mewtwo), which is NOT in loaded list (only Bulbasaur was in list)
      final storage = InMemoryFavoritesStorage({150});
      final testApi = TestMockApiService();

      final container = ProviderContainer(
        overrides: [
          favoritesStorageServiceProvider.overrideWithValue(storage),
          pokemonApiServiceProvider.overrideWithValue(testApi),
        ],
      );

      // Pump Favorites Screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified Mewtwo was resolved by ID via API and displayed!
      expect(find.text('Mewtwo'), findsOneWidget);
      expect(find.text('#150'), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });
  });
}
