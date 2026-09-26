import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';

/// Reusable card displaying a Pokémon in the list or favorites screen.
/// Notice: Reads and mutates the centralized FavoritesProvider directly.
/// Does NOT maintain its own internal favorite boolean state.
class PokemonCard extends ConsumerWidget {
  final Pokemon pokemon;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const PokemonCard({
    super.key,
    required this.pokemon,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoritesProvider).contains(pokemon.id);

    return Card(
      elevation: 0,
      color: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(
          color: AppTheme.borderColor,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: ID and Centralized Favorite Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      pokemon.formattedId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    splashRadius: 20,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? AppTheme.primaryRed
                          : AppTheme.textSecondary,
                    ),
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: () {
                      if (onFavoriteToggle != null) {
                        onFavoriteToggle!();
                      } else {
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(pokemon.id);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Center: Pokémon Image with smooth loading and error fallback
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle circular backdrop
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Image.network(
                        pokemon.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    AppTheme.primaryRed.withValues(alpha: 0.5),
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.catching_pokemon_rounded,
                            size: 48,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.4),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bottom: Pokémon Name
              Text(
                pokemon.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
