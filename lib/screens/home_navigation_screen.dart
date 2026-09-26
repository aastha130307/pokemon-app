import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import 'favorites_screen.dart';
import 'pokemon_list_screen.dart';

/// State provider for the active bottom navigation tab.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main screen containing bottom navigation between Pokédex and Favorites.
class HomeNavigationScreen extends ConsumerWidget {
  const HomeNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final favoritesCount = ref.watch(favoritesProvider).favoriteIds.length;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          PokemonListScreen(),
          FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          elevation: 0,
          backgroundColor: AppTheme.surfaceWhite,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.catching_pokemon_outlined),
              selectedIcon:
                  Icon(Icons.catching_pokemon, color: AppTheme.primaryRed),
              label: 'Pokédex',
            ),
            NavigationDestination(
              icon: favoritesCount > 0
                  ? Badge(
                      label: Text('$favoritesCount'),
                      backgroundColor: AppTheme.primaryRed,
                      child: const Icon(Icons.favorite_border_rounded),
                    )
                  : const Icon(Icons.favorite_border_rounded),
              selectedIcon: favoritesCount > 0
                  ? Badge(
                      label: Text('$favoritesCount'),
                      backgroundColor: AppTheme.primaryRed,
                      child: const Icon(Icons.favorite_rounded,
                          color: AppTheme.primaryRed),
                    )
                  : const Icon(Icons.favorite_rounded,
                      color: AppTheme.primaryRed),
              label: 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}
