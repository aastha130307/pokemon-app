import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';
import '../models/pokemon_detail.dart';
import '../utils/constants.dart';

/// Base custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Thrown when device has no network or host cannot be resolved.
class NetworkException extends ApiException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a request takes longer than the allowed timeout window.
class TimeoutExceptionWrapper extends ApiException {
  const TimeoutExceptionWrapper(super.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Thrown when Pokémon is not found (404).
class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode = 404});

  @override
  String toString() => 'NotFoundException: $message';
}

/// Service responsible for fetching Pokémon data from the official PokéAPI.
/// Independent of any state management layer (Riverpod).
class PokemonApiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;
  final bool _isInternalClient;

  PokemonApiService({
    http.Client? client,
    String baseUrl = AppConstants.pokeApiBaseUrl,
    Duration timeout = AppConstants.requestTimeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl,
        _timeout = timeout,
        _isInternalClient = client == null;

  /// Fetches a paginated list of Pokémon.
  ///
  /// [limit]: Number of Pokémon to fetch per page (defaults to 20).
  /// [offset]: Offset index from which to fetch (defaults to 0).
  Future<PokemonListResponse> fetchPokemonList({
    int limit = AppConstants.defaultPageLimit,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset');

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw const ApiException('Invalid JSON response format.');
        }
        return PokemonListResponse.fromJson(data);
      } else {
        throw ApiException(
          'Failed to load Pokémon list. Server returned ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to PokéAPI server. Please check your internet connection: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Connection error: ${e.message}',
      );
    } on TimeoutException {
      throw const TimeoutExceptionWrapper(
        'The request to PokéAPI timed out. Please try again.',
      );
    } on FormatException catch (e) {
      throw ApiException('Failed to parse response data: ${e.message}');
    }
  }

  /// Fetches detailed information for a single Pokémon by its ID or lowercase name.
  ///
  /// [idOrName]: Either an integer ID (e.g. 25) or a String (e.g. 'pikachu' or '25').
  Future<PokemonDetail> fetchPokemonDetail(dynamic idOrName) async {
    final identifier = idOrName.toString().trim().toLowerCase();
    if (identifier.isEmpty) {
      throw const ApiException('Pokémon identifier cannot be empty.');
    }

    final uri = Uri.parse('$_baseUrl/pokemon/$identifier');

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw const ApiException(
              'Invalid JSON response format for Pokémon detail.');
        }
        return PokemonDetail.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotFoundException(
          'Pokémon "$identifier" was not found on PokéAPI.',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          'Failed to load Pokémon details ($identifier). Server returned ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to PokéAPI server: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Connection error: ${e.message}',
      );
    } on TimeoutException {
      throw const TimeoutExceptionWrapper(
        'The request timed out while loading Pokémon details.',
      );
    } on FormatException catch (e) {
      throw ApiException('Failed to parse Pokémon detail: ${e.message}');
    }
  }

  /// Closes the HTTP client if it was created internally.
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
  }
}
