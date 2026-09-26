import '../utils/constants.dart';

/// Detailed model representing the full information of a Pokémon from PokéAPI (/pokemon/{id}).
class PokemonDetail {
  final int id;
  final String name;
  final int height; // in decimetres
  final int weight; // in hectograms
  final List<PokemonType> types;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final PokemonSprites sprites;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.sprites,
  });

  /// Capitalized name suitable for display.
  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Formatted Pokédex ID with leading zeros (e.g. #025).
  String get formattedId {
    return '#${id.toString().padLeft(3, '0')}';
  }

  /// Height converted to meters (1 decimetre = 0.1 meter).
  double get heightInMeters => height / 10.0;

  /// Human-readable height (e.g. "0.7 m").
  String get heightFormatted => '${heightInMeters.toStringAsFixed(1)} m';

  /// Weight converted to kilograms (1 hectogram = 0.1 kilogram).
  double get weightInKg => weight / 10.0;

  /// Human-readable weight (e.g. "6.9 kg").
  String get weightFormatted => '${weightInKg.toStringAsFixed(1)} kg';

  /// Primary type of the Pokémon (first type in list).
  String get primaryType => types.isNotEmpty ? types.first.name : 'normal';

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['types'] as List<dynamic>? ?? [];
    final types = rawTypes
        .whereType<Map<String, dynamic>>()
        .map((t) => PokemonType.fromJson(t))
        .toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));

    final rawAbilities = json['abilities'] as List<dynamic>? ?? [];
    final abilities = rawAbilities
        .whereType<Map<String, dynamic>>()
        .map((a) => PokemonAbility.fromJson(a))
        .toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));

    final rawStats = json['stats'] as List<dynamic>? ?? [];
    final stats = rawStats
        .whereType<Map<String, dynamic>>()
        .map((s) => PokemonStat.fromJson(s))
        .toList();

    final rawSprites = json['sprites'] as Map<String, dynamic>? ?? {};
    final id = json['id'] as int? ?? 0;

    return PokemonDetail(
      id: id,
      name: json['name'] as String? ?? '',
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      types: types,
      abilities: abilities,
      stats: stats,
      sprites: PokemonSprites.fromJson(rawSprites, id: id),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'types': types.map((t) => t.toJson()).toList(),
      'abilities': abilities.map((a) => a.toJson()).toList(),
      'stats': stats.map((s) => s.toJson()).toList(),
      'sprites': sprites.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonDetail &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'PokemonDetail(id: $id, name: $name)';
}

/// Pokémon Type information (e.g. Grass, Poison, Fire).
class PokemonType {
  final int slot;
  final String name;

  const PokemonType({
    required this.slot,
    required this.name,
  });

  /// Capitalized type name (e.g. "Grass").
  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  factory PokemonType.fromJson(Map<String, dynamic> json) {
    final typeObj = json['type'] as Map<String, dynamic>? ?? {};
    return PokemonType(
      slot: json['slot'] as int? ?? 1,
      name: typeObj['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'type': {'name': name},
    };
  }

  @override
  String toString() => 'PokemonType($name, slot: $slot)';
}

/// Pokémon Ability (e.g. Overgrow, Chlorophyll).
class PokemonAbility {
  final String name;
  final bool isHidden;
  final int slot;

  const PokemonAbility({
    required this.name,
    required this.isHidden,
    required this.slot,
  });

  /// Capitalized and hyphen-formatted display name (e.g. "solar-power" -> "Solar Power").
  String get displayName {
    if (name.isEmpty) return '';
    return name
        .split('-')
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    final abilityObj = json['ability'] as Map<String, dynamic>? ?? {};
    return PokemonAbility(
      name: abilityObj['name'] as String? ?? '',
      isHidden: json['is_hidden'] as bool? ?? false,
      slot: json['slot'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ability': {'name': name},
      'is_hidden': isHidden,
      'slot': slot,
    };
  }

  @override
  String toString() => 'PokemonAbility($name, isHidden: $isHidden)';
}

/// Pokémon Base Stat (e.g. HP, Attack, Defense).
class PokemonStat {
  final String name;
  final int baseStat;
  final int effort;

  const PokemonStat({
    required this.name,
    required this.baseStat,
    required this.effort,
  });

  /// Clean abbreviated/human-readable stat name.
  String get displayName {
    switch (name) {
      case 'hp':
        return 'HP';
      case 'attack':
        return 'Attack';
      case 'defense':
        return 'Defense';
      case 'special-attack':
        return 'Sp. Atk';
      case 'special-defense':
        return 'Sp. Def';
      case 'speed':
        return 'Speed';
      default:
        if (name.isEmpty) return '';
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  /// Normalized value between 0.0 and 1.0 (assuming max base stat is ~255).
  double get normalizedValue => (baseStat / 255.0).clamp(0.0, 1.0);

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    final statObj = json['stat'] as Map<String, dynamic>? ?? {};
    return PokemonStat(
      name: statObj['name'] as String? ?? '',
      baseStat: json['base_stat'] as int? ?? 0,
      effort: json['effort'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stat': {'name': name},
      'base_stat': baseStat,
      'effort': effort,
    };
  }

  @override
  String toString() => 'PokemonStat($name: $baseStat)';
}

/// Pokémon Sprites (official artwork, front default, etc.).
class PokemonSprites {
  final String? frontDefault;
  final String? frontShiny;
  final String? officialArtwork;

  const PokemonSprites({
    this.frontDefault,
    this.frontShiny,
    this.officialArtwork,
  });

  /// Best display image (prefers official artwork, falls back to front default).
  String get displayImage => officialArtwork ?? frontDefault ?? '';

  factory PokemonSprites.fromJson(Map<String, dynamic> json, {int? id}) {
    String? officialArtwork;

    final other = json['other'] as Map<String, dynamic>?;
    if (other != null) {
      final artworkObj = other['official-artwork'] as Map<String, dynamic>?;
      if (artworkObj != null) {
        officialArtwork = artworkObj['front_default'] as String?;
      }
    }

    // Fallback if not provided in json but ID is known
    if (officialArtwork == null && id != null && id > 0) {
      officialArtwork = AppConstants.officialArtworkUrl(id);
    }

    return PokemonSprites(
      frontDefault: json['front_default'] as String?,
      frontShiny: json['front_shiny'] as String?,
      officialArtwork: officialArtwork,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'front_default': frontDefault,
      'front_shiny': frontShiny,
      'other': {
        'official-artwork': {
          'front_default': officialArtwork,
        }
      },
    };
  }
}
