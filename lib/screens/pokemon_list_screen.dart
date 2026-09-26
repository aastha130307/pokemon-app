import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/search_bar_widget.dart';
import 'home_navigation_screen.dart';
import 'pokemon_detail_screen.dart';

/// Main screen displaying the paginated Pokémon list with in-memory search.
class PokemonListScreen extends ConsumerStatefulWidget {
  const PokemonListScreen({super.key});

  @override
  ConsumerState<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends ConsumerState<PokemonListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Trigger initial load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pokemonListProvider);
      if (state.pokemonList.isEmpty &&
          !state.isInitialLoading &&
          state.initialError == null) {
        ref.read(pokemonListProvider.notifier).fetchInitialPokemon();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // When user scrolls within 250 pixels of the bottom, load the next page
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 250;
      if (_scrollController.position.pixels >= threshold) {
        ref.read(pokemonListProvider.notifier).fetchNextPage();
      }
    }
  }

  void _onPokemonTapped(Pokemon pokemon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemonId: pokemon.id,
          initialName: pokemon.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(pokemonListProvider);
    final notifier = ref.read(pokemonListProvider.notifier);

    final filteredList = listState.filteredPokemon;
    final isSearching = listState.searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFDC0A2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.catching_pokemon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pokédex',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            tooltip: 'Favorites',
            onPressed: () {
              ref.read(navigationIndexProvider.notifier).state = 1;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh list',
            onPressed: () => notifier.fetchInitialPokemon(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SearchBarWidget(
                query: listState.searchQuery,
                onChanged: notifier.setSearchQuery,
                onClear: notifier.clearSearch,
              ),
            ),

            // Main Content Area
            Expanded(
              child: _buildBody(
                context,
                listState: listState,
                filteredList: filteredList,
                isSearching: isSearching,
                notifier: notifier,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required PokemonListState listState,
    required List<Pokemon> filteredList,
    required bool isSearching,
    required PokemonListNotifier notifier,
  }) {
    // 1. Initial Loading State
    if (listState.isInitialLoading && listState.pokemonList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Pokémon...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 2. Initial Error State
    if (listState.initialError != null && listState.pokemonList.isEmpty) {
      return ErrorView(
        message: listState.initialError!,
        onRetry: () => notifier.fetchInitialPokemon(),
      );
    }

    // 3. Search Empty State (Loaded Pokémon exist, but none match query)
    if (isSearching && filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No Pokémon found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'No matches for "${listState.searchQuery}" in currently loaded Pokémon.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: notifier.clearSearch,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Empty State (API returned no Pokémon at all)
    if (listState.pokemonList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Pokémon available.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => notifier.fetchInitialPokemon(),
              child: const Text('Load Pokémon'),
            ),
          ],
        ),
      );
    }

    // 5. Success Grid with Infinite Scroll Footer
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 640 ? 3 : 2;

        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pokemon = filteredList[index];
                    return PokemonCard(
                      pokemon: pokemon,
                      onTap: () => _onPokemonTapped(pokemon),
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),

            // Pagination footer
            SliverToBoxAdapter(
              child: _buildPaginationFooter(listState, notifier, isSearching),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationFooter(
    PokemonListState state,
    PokemonListNotifier notifier,
    bool isSearching,
  ) {
    if (isSearching) {
      return const SizedBox(height: 16);
    }

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              SizedBox(width: 12),
              Text(
                'Loading more Pokémon...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (state.paginationError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Column(
          children: [
            Text(
              state.paginationError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => notifier.fetchNextPage(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry loading next page'),
            ),
          ],
        ),
      );
    }

    if (!state.hasNextPage && state.pokemonList.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'All Pokémon have been loaded.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    return const SizedBox(height: 20);
  }
}
