import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon_detail.dart';
import '../services/pokemon_api_service.dart';
import 'pokemon_provider.dart';

/// State representation for Pokémon detail screen.
class PokemonDetailState {
  final PokemonDetail? detail;
  final bool isLoading;
  final String? errorMessage;

  const PokemonDetailState({
    this.detail,
    this.isLoading = false,
    this.errorMessage,
  });

  PokemonDetailState copyWith({
    PokemonDetail? detail,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return PokemonDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

/// Manages fetching and error recovery for a specific Pokémon's detail data.
class PokemonDetailNotifier extends StateNotifier<PokemonDetailState> {
  final PokemonApiService _apiService;
  final dynamic _idOrName;

  PokemonDetailNotifier(this._apiService, this._idOrName)
      : super(const PokemonDetailState(isLoading: true)) {
    loadDetail();
  }

  /// Fetches the Pokémon detail from the API service.
  Future<void> loadDetail() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: () => null,
    );

    try {
      final result = await _apiService.fetchPokemonDetail(_idOrName);
      state = state.copyWith(
        isLoading: false,
        detail: result,
        errorMessage: () => null,
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => message,
      );
    }
  }

  /// Retries fetching the detail data.
  Future<void> retry() => loadDetail();
}

/// Family provider that instantiates a PokemonDetailNotifier for any Pokémon ID or name.
final pokemonDetailProvider = StateNotifierProvider.family<
    PokemonDetailNotifier, PokemonDetailState, dynamic>((ref, idOrName) {
  final apiService = ref.watch(pokemonApiServiceProvider);
  return PokemonDetailNotifier(apiService, idOrName);
});
