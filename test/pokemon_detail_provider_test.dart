import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_app/models/pokemon_detail.dart';
import 'package:pokemon_app/providers/pokemon_detail_provider.dart';
import 'package:pokemon_app/providers/pokemon_provider.dart';
import 'package:pokemon_app/screens/pokemon_detail_screen.dart';
import 'package:pokemon_app/services/pokemon_api_service.dart';

class FakeDetailApiService extends PokemonApiService {
  final Future<PokemonDetail> Function(dynamic idOrName)? onFetchDetail;

  FakeDetailApiService({this.onFetchDetail});

  @override
  Future<PokemonDetail> fetchPokemonDetail(dynamic idOrName) async {
    if (onFetchDetail != null) {
      return onFetchDetail!(idOrName);
    }
    throw const ApiException('Not configured');
  }
}

void main() {
  final sampleDetail = PokemonDetail(
    id: 25,
    name: 'pikachu',
    height: 4,
    weight: 60,
    types: const [
      PokemonType(slot: 1, name: 'electric'),
    ],
    abilities: const [
      PokemonAbility(name: 'static', isHidden: false, slot: 1),
      PokemonAbility(name: 'lightning-rod', isHidden: true, slot: 3),
    ],
    stats: const [
      PokemonStat(name: 'hp', baseStat: 35, effort: 0),
      PokemonStat(name: 'attack', baseStat: 55, effort: 0),
      PokemonStat(name: 'defense', baseStat: 40, effort: 0),
      PokemonStat(name: 'special-attack', baseStat: 50, effort: 0),
      PokemonStat(name: 'special-defense', baseStat: 50, effort: 0),
      PokemonStat(name: 'speed', baseStat: 90, effort: 2),
    ],
    sprites: const PokemonSprites(
      frontDefault: 'https://example.com/pika.png',
      officialArtwork: 'https://example.com/pika-art.png',
    ),
  );

  group('PokemonDetailNotifier Unit Tests', () {
    test('Notifier successfully loads detail on initialization', () async {
      final fakeApi = FakeDetailApiService(
        onFetchDetail: (idOrName) async => sampleDetail,
      );

      final notifier = PokemonDetailNotifier(fakeApi, 25);
      expect(notifier.state.isLoading, isTrue);

      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.detail, isNotNull);
      expect(notifier.state.detail?.name, 'pikachu');
      expect(notifier.state.detail?.displayName, 'Pikachu');
      expect(notifier.state.errorMessage, isNull);
    });

    test('Notifier records error on API failure', () async {
      final fakeApi = FakeDetailApiService(
        onFetchDetail: (idOrName) async {
          throw const ApiException('Pokémon not found', statusCode: 404);
        },
      );

      final notifier = PokemonDetailNotifier(fakeApi, 9999);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.detail, isNull);
      expect(notifier.state.errorMessage, contains('Pokémon not found'));
    });

    test('Notifier retry triggers fetch again', () async {
      int fetchCount = 0;
      final fakeApi = FakeDetailApiService(
        onFetchDetail: (idOrName) async {
          fetchCount++;
          if (fetchCount == 1) {
            throw const ApiException('Temporary error');
          }
          return sampleDetail;
        },
      );

      final notifier = PokemonDetailNotifier(fakeApi, 25);
      await Future.delayed(Duration.zero);

      expect(notifier.state.detail, isNull);
      expect(notifier.state.errorMessage, contains('Temporary error'));

      await notifier.retry();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.detail?.id, 25);
      expect(notifier.state.errorMessage, isNull);
      expect(fetchCount, 2);
    });
  });

  group('PokemonDetailScreen Widget Tests', () {
    testWidgets('Renders all required detail sections on success',
        (tester) async {
      final fakeApi = FakeDetailApiService(
        onFetchDetail: (idOrName) async => sampleDetail,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pokemonApiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: PokemonDetailScreen(pokemonId: 25),
          ),
        ),
      );

      // Initial frame
      await tester.pump();
      // Allow async load to complete
      await tester.pumpAndSettle();

      // Verify Name & ID
      expect(find.text('Pikachu'), findsWidgets);
      expect(find.text('#025'), findsOneWidget);

      // Verify Type
      expect(find.text('Electric'), findsOneWidget);

      // Verify Measurements
      expect(find.text('0.4 m'), findsOneWidget);
      expect(find.text('6.0 kg'), findsOneWidget);

      // Verify Abilities
      expect(find.text('Static'), findsOneWidget);
      expect(find.text('Lightning Rod'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);

      // Verify Base Stats
      expect(find.text('HP'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('Attack'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
      expect(find.text('Defense'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);

      // Verify Favorite button presence (without local state)
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('Renders error UI with Retry button on failure',
        (tester) async {
      final fakeApi = FakeDetailApiService(
        onFetchDetail: (idOrName) async {
          throw const ApiException('Failed to load Pokémon details');
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pokemonApiServiceProvider.overrideWithValue(fakeApi),
          ],
          child: const MaterialApp(
            home: PokemonDetailScreen(pokemonId: 999),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load Pokémon details'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
