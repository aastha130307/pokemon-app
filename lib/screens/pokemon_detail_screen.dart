import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';
import '../providers/pokemon_detail_provider.dart';
import '../utils/app_theme.dart';
import '../utils/type_colors.dart';
import '../widgets/error_view.dart';
import '../widgets/stat_bar.dart';
import '../widgets/type_chip.dart';

/// Screen displaying complete details for a single Pokémon.
class PokemonDetailScreen extends ConsumerWidget {
  final dynamic pokemonId;
  final String? initialName;

  const PokemonDetailScreen({
    super.key,
    required this.pokemonId,
    this.initialName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(pokemonDetailProvider(pokemonId));
    final notifier = ref.read(pokemonDetailProvider(pokemonId).notifier);
    final theme = Theme.of(context);

    final title = detailState.detail?.displayName ??
        (initialName != null && initialName!.isNotEmpty
            ? initialName![0].toUpperCase() + initialName!.substring(1)
            : 'Pokémon Details');

    final resolvedId = detailState.detail?.id ??
        (pokemonId is int
            ? pokemonId as int
            : int.tryParse(pokemonId.toString()) ?? 0);
    final isFavorite =
        resolvedId > 0 && ref.watch(favoritesProvider).contains(resolvedId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Colors.redAccent,
              size: 26,
            ),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () {
              if (resolvedId > 0) {
                ref.read(favoritesProvider.notifier).toggleFavorite(resolvedId);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, detailState, notifier, theme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PokemonDetailState state,
    PokemonDetailNotifier notifier,
    ThemeData theme,
  ) {
    // 1. Loading State
    if (state.isLoading && state.detail == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Pokémon details...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 2. Error State
    if (state.errorMessage != null && state.detail == null) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => notifier.retry(),
      );
    }

    final detail = state.detail;
    if (detail == null) {
      return const Center(child: Text('No details available.'));
    }

    final primaryColor = PokemonTypeColors.getColor(detail.primaryType);

    // 3. Success State with complete Pokémon information
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner Header with Primary Color gradient and Artwork
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.25),
                  primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Top row: ID badge
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      detail.formattedId,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Large Pokémon Artwork
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.network(
                    detail.sprites.displayImage,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.catching_pokemon_rounded,
                        size: 96,
                        color: primaryColor.withValues(alpha: 0.6),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  detail.displayName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Types row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: detail.types
                      .map((type) => TypeChip.fromPokemonType(type))
                      .toList(),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Physical Measurements (Height & Weight)
                _buildSectionTitle(theme, 'About'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasurementCard(
                        theme: theme,
                        icon: Icons.straighten_rounded,
                        label: 'Height',
                        value: detail.heightFormatted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMeasurementCard(
                        theme: theme,
                        icon: Icons.scale_rounded,
                        label: 'Weight',
                        value: detail.weightFormatted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section: Abilities
                _buildSectionTitle(theme, 'Abilities'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.abilities.map((ability) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ability.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (ability.isHidden) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Hidden',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Section: Base Stats
                _buildSectionTitle(theme, 'Base Stats'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: detail.stats
                        .map((stat) => StatBar(stat: stat))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildMeasurementCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
