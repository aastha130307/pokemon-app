import 'package:flutter/material.dart';

import '../models/pokemon_detail.dart';
import '../utils/type_colors.dart';

/// Reusable badge/chip for a Pokémon type with thematic color accents.
class TypeChip extends StatelessWidget {
  final String typeName;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const TypeChip({
    super.key,
    required this.typeName,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  factory TypeChip.fromPokemonType(PokemonType type) {
    return TypeChip(typeName: type.name);
  }

  @override
  Widget build(BuildContext context) {
    final color = PokemonTypeColors.getColor(typeName);
    final capitalized = typeName.isEmpty
        ? ''
        : typeName[0].toUpperCase() + typeName.substring(1);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        capitalized,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
