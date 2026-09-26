import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../services/favorites_storage_service.dart';
import '../utils/constants.dart';
import 'pokemon_provider.dart';

/// State representation of the centralized favorites.
class FavoritesState {
  final Set<int> favoriteIds;
  final bool isInitialized;

  const FavoritesState({
    this.favoriteIds = const <int>{},
    this.isInitialized = false,
  });

  bool contains(int id) => favoriteIds.contains(id);

  FavoritesState copyWith({
    Set<int>? favoriteIds,
    bool? isInitialized,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Provider for the storage service to support easy dependency injection in tests.
final favoritesStorageServiceProvider =
    Provider<FavoritesStorageService>((ref) {
  return FavoritesStorageService();
});

/// Single source of truth for favorite Pokémon IDs across the entire app.
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesStorageService _storageService;

  FavoritesNotifier(this._storageService) : super(const FavoritesState()) {
    _loadInitialFavorites();
  }

  Future<void> _loadInitialFavorites() async {
    try {
      final loaded = await _storageService.loadFavorites();
      state = state.copyWith(
        favoriteIds: loaded,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Checks if a Pokémon is favorited.
  bool isFavorite(int id) => state.contains(id);

  /// Toggles favorite status for a Pokémon ID and persists the result.
  Future<void> toggleFavorite(int id) async {
    if (id <= 0) return;

    final updatedIds = Set<int>.from(state.favoriteIds);
    if (updatedIds.contains(id)) {
      updatedIds.remove(id);
    } else {
      updatedIds.add(id);
    }

    // Immediately update in-memory state for instant UI response
    state = state.copyWith(favoriteIds: updatedIds);

    // Persist to local storage
    await _storageService.saveFavorites(updatedIds);
  }

  /// Explicitly adds a Pokémon ID to favorites.
  Future<void> addFavorite(int id) async {
    if (id <= 0 || state.contains(id)) return;

    final updatedIds = Set<int>.from(state.favoriteIds)..add(id);
    state = state.copyWith(favoriteIds: updatedIds);
    await _storageService.saveFavorites(updatedIds);
  }

  /// Explicitly removes a Pokémon ID from favorites.
  Future<void> removeFavorite(int id) async {
    if (id <= 0 || !state.contains(id)) return;

    final updatedIds = Set<int>.from(state.favoriteIds)..remove(id);
    state = state.copyWith(favoriteIds: updatedIds);
    await _storageService.saveFavorites(updatedIds);
  }

  /// Clears all favorites.
  Future<void> clearAll() async {
    state = state.copyWith(favoriteIds: const <int>{});
    await _storageService.clearFavorites();
  }
}

/// Centralized provider for all favorite Pokémon interactions.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final storage = ref.watch(favoritesStorageServiceProvider);
  return FavoritesNotifier(storage);
});

/// Resolves complete Pokémon summary objects for the favorite IDs.
/// Reuses any cached Pokémon in pokemonListProvider first;
/// fetches missing IDs from PokéAPI individually without blocking or crashing on failure.
final favoritePokemonListProvider = FutureProvider<List<Pokemon>>((ref) async {
  final favoritesState = ref.watch(favoritesProvider);
  final favoriteIds = favoritesState.favoriteIds.toList()..sort();

  if (favoriteIds.isEmpty) {
    return <Pokemon>[];
  }

  final loadedPokemonList = ref.watch(pokemonListProvider).pokemonList;
  final loadedMap = {for (var p in loadedPokemonList) p.id: p};
  final apiService = ref.watch(pokemonApiServiceProvider);

  final List<Pokemon> results = [];

  for (final id in favoriteIds) {
    if (loadedMap.containsKey(id)) {
      results.add(loadedMap[id]!);
    } else {
      // Resolve from API
      try {
        final detail = await apiService.fetchPokemonDetail(id);
        results.add(
          Pokemon(
            id: detail.id,
            name: detail.name,
            url: '${AppConstants.pokeApiBaseUrl}/pokemon/${detail.id}/',
            imageUrl: detail.sprites.displayImage.isNotEmpty
                ? detail.sprites.displayImage
                : AppConstants.officialArtworkUrl(detail.id),
          ),
        );
      } catch (_) {
        // Fallback placeholder so failure to fetch one item does NOT drop the favorite
        results.add(
          Pokemon(
            id: id,
            name: 'pokemon #$id',
            url: '${AppConstants.pokeApiBaseUrl}/pokemon/$id/',
            imageUrl: AppConstants.officialArtworkUrl(id),
          ),
        );
      }
    }
  }

  return results;
});
