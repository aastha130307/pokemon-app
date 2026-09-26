import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and restoring favorite Pokémon IDs in local storage.
class FavoritesStorageService {
  static const String _favoritesKey = 'favorite_pokemon_ids';
  final SharedPreferences? _prefs;

  FavoritesStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs;
    return await SharedPreferences.getInstance();
  }

  /// Loads persisted favorite Pokémon IDs from SharedPreferences.
  /// Handles empty storage or corrupted records gracefully without crashing.
  Future<Set<int>> loadFavorites() async {
    try {
      final prefs = await _getPrefs();
      final stringList = prefs.getStringList(_favoritesKey);

      if (stringList == null || stringList.isEmpty) {
        // Fallback check if stored as JSON string
        final jsonString = prefs.getString(_favoritesKey);
        if (jsonString != null && jsonString.isNotEmpty) {
          final decoded = jsonDecode(jsonString);
          if (decoded is List) {
            return decoded
                .map((e) => int.tryParse(e.toString()))
                .whereType<int>()
                .toSet();
          }
        }
        return <int>{};
      }

      final favoriteIds = <int>{};
      for (final item in stringList) {
        final parsed = int.tryParse(item);
        if (parsed != null && parsed > 0) {
          favoriteIds.add(parsed);
        }
      }
      return favoriteIds;
    } catch (e) {
      // Gracefully recover with empty set if data is corrupted
      return <int>{};
    }
  }

  /// Persists the set of favorite Pokémon IDs to SharedPreferences.
  Future<bool> saveFavorites(Set<int> favoriteIds) async {
    try {
      final prefs = await _getPrefs();
      final stringList = favoriteIds.map((id) => id.toString()).toList();
      return await prefs.setStringList(_favoritesKey, stringList);
    } catch (e) {
      return false;
    }
  }

  /// Clears all favorites from SharedPreferences.
  Future<bool> clearFavorites() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
}
