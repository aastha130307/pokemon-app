import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../services/pokemon_api_service.dart';
import '../utils/constants.dart';

/// State representation for the paginated Pokémon list and search filter.
class PokemonListState {
  final List<Pokemon> pokemonList;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? initialError;
  final String? paginationError;
  final int currentOffset;
  final bool hasNextPage;
  final String searchQuery;

  const PokemonListState({
    this.pokemonList = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.initialError,
    this.paginationError,
    this.currentOffset = 0,
    this.hasNextPage = true,
    this.searchQuery = '',
  });

  /// Returns the currently loaded Pokémon filtered by the search query.
  /// Operates entirely in-memory and is case-insensitive.
  List<Pokemon> get filteredPokemon {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return pokemonList;
    }
    return pokemonList.where((pokemon) {
      final nameMatches = pokemon.name.toLowerCase().contains(query);
      final idMatches = pokemon.id.toString() == query ||
          pokemon.formattedId.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  PokemonListState copyWith({
    List<Pokemon>? pokemonList,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? Function()? initialError,
    String? Function()? paginationError,
    int? currentOffset,
    bool? hasNextPage,
    String? searchQuery,
  }) {
    return PokemonListState(
      pokemonList: pokemonList ?? this.pokemonList,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialError: initialError != null ? initialError() : this.initialError,
      paginationError:
          paginationError != null ? paginationError() : this.paginationError,
      currentOffset: currentOffset ?? this.currentOffset,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Provider for the API service instance, enabling dependency injection in tests.
final pokemonApiServiceProvider = Provider<PokemonApiService>((ref) {
  final service = PokemonApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Centralized Notifier managing the Pokémon list, pagination, and search query.
class PokemonListNotifier extends StateNotifier<PokemonListState> {
  final PokemonApiService _apiService;
  static const int _limit = AppConstants.defaultPageLimit;

  PokemonListNotifier(this._apiService) : super(const PokemonListState());

  /// Loads the first page of Pokémon.
  Future<void> fetchInitialPokemon() async {
    // Prevent duplicate loading if already loading
    if (state.isInitialLoading) return;

    state = state.copyWith(
      isInitialLoading: true,
      initialError: () => null,
      paginationError: () => null,
      currentOffset: 0,
      hasNextPage: true,
    );

    try {
      final response = await _apiService.fetchPokemonList(
        limit: _limit,
        offset: 0,
      );

      state = state.copyWith(
        pokemonList: response.results,
        isInitialLoading: false,
        currentOffset: response.results.length,
        hasNextPage: response.hasNextPage,
        initialError: () => null,
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isInitialLoading: false,
        initialError: () => message,
      );
    }
  }

  /// Fetches the next page of Pokémon and appends to the current list.
  Future<void> fetchNextPage() async {
    // Guards against: already loading, no more pages, or currently searching
    if (state.isLoadingMore ||
        state.isInitialLoading ||
        !state.hasNextPage ||
        state.searchQuery.trim().isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      paginationError: () => null,
    );

    try {
      final response = await _apiService.fetchPokemonList(
        limit: _limit,
        offset: state.currentOffset,
      );

      // Append new items avoiding duplicate IDs if any
      final existingIds = state.pokemonList.map((p) => p.id).toSet();
      final newUniqueItems =
          response.results.where((p) => !existingIds.contains(p.id)).toList();

      state = state.copyWith(
        pokemonList: [...state.pokemonList, ...newUniqueItems],
        isLoadingMore: false,
        currentOffset: state.currentOffset + response.results.length,
        hasNextPage: response.hasNextPage,
        paginationError: () => null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        paginationError: () => 'Failed to load more Pokémon. Tap to retry.',
      );
    }
  }

  /// Updates the in-memory search query.
  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }

  /// Clears the search filter.
  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(searchQuery: '');
  }

  /// Retries the last failed operation (either initial or pagination).
  Future<void> retry() async {
    if (state.pokemonList.isEmpty) {
      await fetchInitialPokemon();
    } else if (state.paginationError != null) {
      await fetchNextPage();
    }
  }
}

/// Main provider for accessing the Pokémon list state and actions.
final pokemonListProvider =
    StateNotifierProvider<PokemonListNotifier, PokemonListState>((ref) {
  final apiService = ref.watch(pokemonApiServiceProvider);
  return PokemonListNotifier(apiService);
});
