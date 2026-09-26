import 'package:flutter/material.dart';

import '../models/pokemon_detail.dart';

/// Reusable horizontal progress bar for displaying a Pokémon base stat.
class StatBar extends StatelessWidget {
  final PokemonStat stat;

  const StatBar({
    super.key,
    required this.stat,
  });

  Color _getStatColor(int value) {
    if (value >= 100) return const Color(0xFF4CAF50); // High: Green
    if (value >= 70) return const Color(0xFF2196F3); // Good: Blue
    if (value >= 50) return const Color(0xFFFF9800); // Average: Amber/Orange
    return const Color(0xFFF44336); // Low: Red
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statColor = _getStatColor(stat.baseStat);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Stat label (e.g. "HP", "Attack", "Sp. Atk")
          SizedBox(
            width: 72,
            child: Text(
              stat.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Numeric stat value (e.g. 78)
          SizedBox(
            width: 40,
            child: Text(
              stat.baseStat.toString(),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.normalizedValue,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
