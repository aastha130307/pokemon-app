import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_app/models/pokemon.dart';
import 'package:pokemon_app/providers/pokemon_provider.dart';
import 'package:pokemon_app/services/pokemon_api_service.dart';

/// Test implementation of PokemonApiService returning predetermined responses without network.
class FakePokemonApiService extends PokemonApiService {
  final Future<PokemonListResponse> Function(int limit, int offset)?
      onFetchList;

  FakePokemonApiService({this.onFetchList});

  @override
  Future<PokemonListResponse> fetchPokemonList(
      {int limit = 20, int offset = 0}) async {
    if (onFetchList != null) {
      return onFetchList!(limit, offset);
    }
    return const PokemonListResponse(count: 0, results: []);
  }
}

void main() {
  group('PokemonListNotifier Unit Tests', () {
    test('Initial state is empty and not loading', () {
      final fakeApi = FakePokemonApiService();
      final notifier = PokemonListNotifier(fakeApi);

      expect(notifier.state.pokemonList, isEmpty);
      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.initialError, isNull);
      expect(notifier.state.searchQuery, isEmpty);
      expect(notifier.state.hasNextPage, isTrue);
    });

    test('fetchInitialPokemon sets loading and loads first page', () async {
      final fakeApi = FakePokemonApiService(
        onFetchList: (limit, offset) async {
          expect(limit, 20);
          expect(offset, 0);
          return const PokemonListResponse(
            count: 40,
            next: 'https://pokeapi.co/api/v2/pokemon?offset=20&limit=20',
            results: [
              Pokemon(id: 1, name: 'bulbasaur', url: '', imageUrl: ''),
              Pokemon(id: 2, name: 'ivysaur', url: '', imageUrl: ''),
            ],
          );
        },
      );

      final notifier = PokemonListNotifier(fakeApi);
      await notifier.fetchInitialPokemon();

      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.pokemonList.length, 2);
      expect(notifier.state.pokemonList.first.name, 'bulbasaur');
      expect(notifier.state.currentOffset, 2);
      expect(notifier.state.hasNextPage, isTrue);
      expect(notifier.state.initialError, isNull);
    });

    test('fetchInitialPokemon records error on API failure', () async {
      final fakeApi = FakePokemonApiService(
        onFetchList: (limit, offset) async {
          throw const ApiException('Network failed', statusCode: 500);
        },
      );

      final notifier = PokemonListNotifier(fakeApi);
      await notifier.fetchInitialPokemon();

      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.pokemonList, isEmpty);
      expect(notifier.state.initialError, contains('Network failed'));
    });

    test('fetchNextPage appends items to existing list without replacing them',
        () async {
      int callCount = 0;
      final fakeApi = FakePokemonApiService(
        onFetchList: (limit, offset) async {
          callCount++;
          if (offset == 0) {
            return const PokemonListResponse(
              count: 4,
              next: 'https://pokeapi.co/api/v2/pokemon?offset=2&limit=2',
              results: [
                Pokemon(id: 1, name: 'bulbasaur', url: '', imageUrl: ''),
                Pokemon(id: 2, name: 'ivysaur', url: '', imageUrl: ''),
              ],
            );
          } else {
            return const PokemonListResponse(
              count: 4,
              next: null,
              results: [
                Pokemon(id: 3, name: 'venusaur', url: '', imageUrl: ''),
                Pokemon(id: 4, name: 'charmander', url: '', imageUrl: ''),
              ],
            );
          }
        },
      );

      final notifier = PokemonListNotifier(fakeApi);
      await notifier.fetchInitialPokemon();
      expect(notifier.state.pokemonList.length, 2);

      await notifier.fetchNextPage();
      expect(notifier.state.pokemonList.length, 4);
      expect(notifier.state.pokemonList[0].id, 1);
      expect(notifier.state.pokemonList[1].id, 2);
      expect(notifier.state.pokemonList[2].id, 3);
      expect(notifier.state.pokemonList[3].id, 4);
      expect(notifier.state.hasNextPage, isFalse);
      expect(callCount, 2);

      // Subsequent fetchNextPage should NOT trigger because hasNextPage is false
      await notifier.fetchNextPage();
      expect(callCount, 2);
    });

    test('fetchNextPage keeps existing items if pagination fails', () async {
      final fakeApi = FakePokemonApiService(
        onFetchList: (limit, offset) async {
          if (offset == 0) {
            return const PokemonListResponse(
              count: 10,
              next: 'https://pokeapi.co/api/v2/pokemon?offset=2&limit=2',
              results: [
                Pokemon(id: 1, name: 'bulbasaur', url: '', imageUrl: ''),
              ],
            );
          } else {
            throw const ApiException('Connection lost');
          }
        },
      );

      final notifier = PokemonListNotifier(fakeApi);
      await notifier.fetchInitialPokemon();
      expect(notifier.state.pokemonList.length, 1);

      await notifier.fetchNextPage();
      // Existing list preserved!
      expect(notifier.state.pokemonList.length, 1);
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.paginationError, isNotNull);
    });

    test('Search filters currently loaded Pokémon case-insensitively',
        () async {
      final fakeApi = FakePokemonApiService(
        onFetchList: (limit, offset) async {
          return const PokemonListResponse(
            count: 3,
            results: [
              Pokemon(id: 1, name: 'bulbasaur', url: '', imageUrl: ''),
              Pokemon(id: 4, name: 'charmander', url: '', imageUrl: ''),
              Pokemon(id: 25, name: 'pikachu', url: '', imageUrl: ''),
            ],
          );
        },
      );

      final notifier = PokemonListNotifier(fakeApi);
      await notifier.fetchInitialPokemon();

      // Empty search query returns all
      expect(notifier.state.filteredPokemon.length, 3);

      // Search by partial lowercase name
      notifier.setSearchQuery('char');
      expect(notifier.state.filteredPokemon.length, 1);
      expect(notifier.state.filteredPokemon.first.name, 'charmander');

      // Search by uppercase name (case-insensitive)
      notifier.setSearchQuery('PIKA');
      expect(notifier.state.filteredPokemon.length, 1);
      expect(notifier.state.filteredPokemon.first.name, 'pikachu');

      // Search by ID string
      notifier.setSearchQuery('1');
      expect(notifier.state.filteredPokemon.length, 1);
      expect(notifier.state.filteredPokemon.first.name, 'bulbasaur');

      // Search with no matches
      notifier.setSearchQuery('mewtwo');
      expect(notifier.state.filteredPokemon, isEmpty);

      // Clear search
      notifier.clearSearch();
      expect(notifier.state.filteredPokemon.length, 3);
    });
  });
}
