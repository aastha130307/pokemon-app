import '../utils/constants.dart';

/// Summary model for a Pokémon item returned from the list endpoint.
class Pokemon {
  final int id;
  final String name;
  final String url;
  final String imageUrl;

  const Pokemon({
    required this.id,
    required this.name,
    required this.url,
    required this.imageUrl,
  });

  /// Factory constructor to parse a Pokémon from the PokéAPI list results item.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final url = json['url'] as String? ?? '';

    // Extract ID from the PokéAPI URL (e.g. "https://pokeapi.co/api/v2/pokemon/25/")
    final id = _extractIdFromUrl(url) ?? (json['id'] as int? ?? 0);
    final imageUrl = AppConstants.officialArtworkUrl(id);

    return Pokemon(
      id: id,
      name: name,
      url: url,
      imageUrl: imageUrl,
    );
  }

  /// Capitalized name suitable for UI display (e.g., "pikachu" -> "Pikachu").
  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Formatted Pokédex ID with leading zeros (e.g. #025).
  String get formattedId {
    return '#${id.toString().padLeft(3, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'imageUrl': imageUrl,
    };
  }

  static int? _extractIdFromUrl(String url) {
    if (url.isEmpty) return null;
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final segments = cleanUrl.split('/');
    if (segments.isEmpty) return null;
    return int.tryParse(segments.last);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pokemon &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Pokemon(id: $id, name: $name)';
}

/// Paginated list response wrapper from PokéAPI (/pokemon?limit=X&offset=Y).
class PokemonListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Pokemon> results;

  const PokemonListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  /// True if there is a next page available.
  bool get hasNextPage => next != null && next!.isNotEmpty;

  factory PokemonListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final results = rawResults
        .whereType<Map<String, dynamic>>()
        .map((item) => Pokemon.fromJson(item))
        .toList();

    return PokemonListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: results,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((p) => p.toJson()).toList(),
    };
  }
}
