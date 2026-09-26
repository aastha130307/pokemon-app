import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_app/main.dart';
import 'package:pokemon_app/models/pokemon.dart';
import 'package:pokemon_app/providers/pokemon_provider.dart';
import 'package:pokemon_app/services/pokemon_api_service.dart';

class MockPokemonApiService extends PokemonApiService {
  @override
  Future<PokemonListResponse> fetchPokemonList(
      {int limit = 20, int offset = 0}) async {
    return const PokemonListResponse(
      count: 2,
      results: [
        Pokemon(
          id: 1,
          name: 'bulbasaur',
          url: 'https://pokeapi.co/api/v2/pokemon/1/',
          imageUrl: 'https://example.com/1.png',
        ),
        Pokemon(
          id: 25,
          name: 'pikachu',
          url: 'https://pokeapi.co/api/v2/pokemon/25/',
          imageUrl: 'https://example.com/25.png',
        ),
      ],
    );
  }
}

void main() {
  testWidgets('PokemonListScreen renders header, search, and pokemon cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pokemonApiServiceProvider.overrideWithValue(MockPokemonApiService()),
        ],
        child: const PokemonApp(),
      ),
    );

    // Initial frame shows loading or immediately kicks off fetch
    await tester.pumpAndSettle();

    // Verify AppBar header title and bottom navigation label
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.text('Favorites'), findsOneWidget);

    // Verify Search bar
    expect(find.text('Search Pokémon by name or #ID...'), findsOneWidget);

    // Verify loaded cards
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('#025'), findsOneWidget);
  });
}
