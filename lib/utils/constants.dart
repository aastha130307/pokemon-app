class AppConstants {
  static const String pokeApiBaseUrl = 'https://pokeapi.co/api/v2';
  static const int defaultPageLimit = 20;
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Helper to get the official artwork image URL for a given Pokémon ID.
  static String officialArtworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  /// Helper to get the standard front sprite image URL as fallback.
  static String defaultSpriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
}
