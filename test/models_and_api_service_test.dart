import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pokemon_app/models/pokemon.dart';
import 'package:pokemon_app/models/pokemon_detail.dart';
import 'package:pokemon_app/services/pokemon_api_service.dart';

/// Lightweight mock HTTP client for unit tests without external network requests.
class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('Pokemon Model & List Parsing Tests', () {
    test('Pokemon.fromJson correctly extracts ID from URL and builds image URL',
        () {
      final json = {
        'name': 'pikachu',
        'url': 'https://pokeapi.co/api/v2/pokemon/25/',
      };

      final pokemon = Pokemon.fromJson(json);

      expect(pokemon.id, 25);
      expect(pokemon.name, 'pikachu');
      expect(pokemon.displayName, 'Pikachu');
      expect(pokemon.formattedId, '#025');
      expect(
        pokemon.imageUrl,
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
      );
    });

    test(
        'PokemonListResponse.fromJson correctly parses pagination metadata and results',
        () {
      final json = {
        'count': 1302,
        'next': 'https://pokeapi.co/api/v2/pokemon?offset=20&limit=20',
        'previous': null,
        'results': [
          {'name': 'bulbasaur', 'url': 'https://pokeapi.co/api/v2/pokemon/1/'},
          {'name': 'ivysaur', 'url': 'https://pokeapi.co/api/v2/pokemon/2/'},
        ],
      };

      final response = PokemonListResponse.fromJson(json);

      expect(response.count, 1302);
      expect(response.hasNextPage, isTrue);
      expect(response.previous, isNull);
      expect(response.results.length, 2);
      expect(response.results.first.id, 1);
      expect(response.results.first.displayName, 'Bulbasaur');
      expect(response.results.last.id, 2);
      expect(response.results.last.displayName, 'Ivysaur');
    });

    test('PokemonListResponse.hasNextPage returns false when next is null', () {
      final json = {
        'count': 2,
        'next': null,
        'previous': 'https://pokeapi.co/api/v2/pokemon?offset=0&limit=20',
        'results': <Map<String, dynamic>>[],
      };

      final response = PokemonListResponse.fromJson(json);
      expect(response.hasNextPage, isFalse);
    });
  });

  group('PokemonDetail Model Parsing Tests', () {
    final sampleDetailJson = {
      'id': 6,
      'name': 'charizard',
      'height': 17,
      'weight': 905,
      'types': [
        {
          'slot': 1,
          'type': {'name': 'fire', 'url': 'https://pokeapi.co/api/v2/type/10/'}
        },
        {
          'slot': 2,
          'type': {'name': 'flying', 'url': 'https://pokeapi.co/api/v2/type/3/'}
        },
      ],
      'abilities': [
        {
          'ability': {
            'name': 'blaze',
            'url': 'https://pokeapi.co/api/v2/ability/66/'
          },
          'is_hidden': false,
          'slot': 1,
        },
        {
          'ability': {
            'name': 'solar-power',
            'url': 'https://pokeapi.co/api/v2/ability/94/'
          },
          'is_hidden': true,
          'slot': 3,
        },
      ],
      'stats': [
        {
          'base_stat': 78,
          'effort': 0,
          'stat': {'name': 'hp', 'url': 'https://pokeapi.co/api/v2/stat/1/'}
        },
        {
          'base_stat': 84,
          'effort': 0,
          'stat': {'name': 'attack', 'url': 'https://pokeapi.co/api/v2/stat/2/'}
        },
        {
          'base_stat': 109,
          'effort': 3,
          'stat': {
            'name': 'special-attack',
            'url': 'https://pokeapi.co/api/v2/stat/4/'
          }
        },
      ],
      'sprites': {
        'front_default':
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/6.png',
        'other': {
          'official-artwork': {
            'front_default':
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png'
          }
        }
      }
    };

    test('PokemonDetail parses basic measurements and formatting correctly',
        () {
      final detail = PokemonDetail.fromJson(sampleDetailJson);

      expect(detail.id, 6);
      expect(detail.name, 'charizard');
      expect(detail.displayName, 'Charizard');
      expect(detail.formattedId, '#006');
      expect(detail.heightInMeters, 1.7);
      expect(detail.heightFormatted, '1.7 m');
      expect(detail.weightInKg, 90.5);
      expect(detail.weightFormatted, '90.5 kg');
      expect(detail.primaryType, 'fire');
    });

    test('PokemonDetail parses types and abilities properly', () {
      final detail = PokemonDetail.fromJson(sampleDetailJson);

      expect(detail.types.length, 2);
      expect(detail.types[0].name, 'fire');
      expect(detail.types[0].displayName, 'Fire');
      expect(detail.types[1].name, 'flying');
      expect(detail.types[1].displayName, 'Flying');

      expect(detail.abilities.length, 2);
      expect(detail.abilities[0].name, 'blaze');
      expect(detail.abilities[0].displayName, 'Blaze');
      expect(detail.abilities[0].isHidden, isFalse);

      expect(detail.abilities[1].name, 'solar-power');
      expect(detail.abilities[1].displayName, 'Solar Power');
      expect(detail.abilities[1].isHidden, isTrue);
    });

    test('PokemonDetail parses stats and sprites properly', () {
      final detail = PokemonDetail.fromJson(sampleDetailJson);

      expect(detail.stats.length, 3);
      expect(detail.stats[0].displayName, 'HP');
      expect(detail.stats[0].baseStat, 78);
      expect(detail.stats[1].displayName, 'Attack');
      expect(detail.stats[1].baseStat, 84);
      expect(detail.stats[2].displayName, 'Sp. Atk');
      expect(detail.stats[2].baseStat, 109);

      expect(
        detail.sprites.displayImage,
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
      );
    });
  });

  group('PokemonApiService with Mock Client', () {
    test(
        'fetchPokemonList queries correct endpoint and returns parsed response',
        () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/api/v2/pokemon');
        expect(request.url.queryParameters['limit'], '20');
        expect(request.url.queryParameters['offset'], '40');

        final body = jsonEncode({
          'count': 1302,
          'next': 'https://pokeapi.co/api/v2/pokemon?offset=60&limit=20',
          'previous': 'https://pokeapi.co/api/v2/pokemon?offset=20&limit=20',
          'results': [
            {'name': 'zubat', 'url': 'https://pokeapi.co/api/v2/pokemon/41/'},
          ],
        });
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      });

      final service = PokemonApiService(client: mockClient);
      final response = await service.fetchPokemonList(limit: 20, offset: 40);

      expect(response.count, 1302);
      expect(response.results.length, 1);
      expect(response.results.first.name, 'zubat');
      expect(response.results.first.id, 41);
    });

    test('fetchPokemonDetail successfully returns detail model on 200',
        () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/api/v2/pokemon/pikachu');
        final body = jsonEncode({
          'id': 25,
          'name': 'pikachu',
          'height': 4,
          'weight': 60,
          'types': [
            {
              'slot': 1,
              'type': {
                'name': 'electric',
                'url': 'https://pokeapi.co/api/v2/type/13/'
              }
            }
          ],
          'abilities': [],
          'stats': [],
          'sprites': {'front_default': 'https://example.com/pika.png'},
        });
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      });

      final service = PokemonApiService(client: mockClient);
      final detail = await service.fetchPokemonDetail('pikachu');

      expect(detail.id, 25);
      expect(detail.displayName, 'Pikachu');
      expect(detail.primaryType, 'electric');
    });

    test('fetchPokemonDetail throws NotFoundException on 404 response',
        () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = PokemonApiService(client: mockClient);

      expect(
        () => service.fetchPokemonDetail('unknown-mon'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('fetchPokemonList throws ApiException on 500 server error', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = PokemonApiService(client: mockClient);

      expect(
        () => service.fetchPokemonList(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
