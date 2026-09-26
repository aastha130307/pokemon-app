# Pokédex Flutter App

A Flutter-based Pokédex application that uses the PokéAPI to browse Pokémon, search Pokémon, view detailed information, and manage favorite Pokémon.

## Features

* Browse Pokémon using paginated loading
* Infinite scrolling
* Search Pokémon by name or Pokédex ID
* View detailed Pokémon information
* Display Pokémon artwork, types, abilities, height, weight, and base stats
* Add and remove Pokémon from favorites
* Favorites synchronized across the List, Detail, and Favorites screens
* Persistent favorites using local storage
* Loading, error, empty, and retry states
* Responsive UI

## Tech Stack

* **Flutter**
* **Dart**
* **Riverpod** — state management
* **SharedPreferences** — local favorite persistence
* **HTTP** — API requests
* **PokéAPI** — Pokémon data source

## Application Structure

```text
lib/
├── models/
│   ├── pokemon.dart
│   └── pokemon_detail.dart
│
├── services/
│   ├── pokemon_api_service.dart
│   └── favorites_storage_service.dart
│
├── providers/
│   ├── pokemon_provider.dart
│   ├── pokemon_detail_provider.dart
│   └── favorites_provider.dart
│
├── screens/
│   ├── pokemon_list_screen.dart
│   ├── pokemon_detail_screen.dart
│   ├── favorites_screen.dart
│   └── home_navigation_screen.dart
│
├── widgets/
│   ├── pokemon_card.dart
│   ├── type_chip.dart
│   ├── stat_bar.dart
│   ├── search_bar_widget.dart
│   └── error_view.dart
│
└── utils/
```

## API

The application uses [PokéAPI](https://pokeapi.co/).

### Pokémon List

```text
GET /api/v2/pokemon?limit={limit}&offset={offset}
```

Used for paginated Pokémon loading.

### Pokémon Details

```text
GET /api/v2/pokemon/{id-or-name}
```

Used to retrieve detailed information about a Pokémon.

## Favorites

Favorites are managed through a centralized Riverpod provider.

The same favorites state is consumed by:

* Pokémon List
* Pokémon Detail
* Favorites

Favorite Pokémon IDs are persisted locally using SharedPreferences, allowing favorites to remain available after restarting the application.

## Error Handling

The application provides handling for:

* Network/API errors
* Request timeouts
* Pokémon not found
* Image loading failures
* Empty search results
* Empty favorites
* Pagination failures

Retry actions are provided where appropriate.

## Testing

The project includes unit and widget tests covering:

* Pokémon model parsing
* API service
* API error handling
* Pagination
* Search
* Pokémon detail loading
* Favorites management
* Favorites persistence
* Cross-screen favorite synchronization
* Application navigation

Run tests with:

```bash
flutter test
```

Run static analysis with:

```bash
flutter analyze
```

Format the project with:

```bash
dart format lib test
```

## Getting Started

### Prerequisites

* Flutter SDK
* Dart SDK
* Android Studio or another Flutter-compatible IDE
* Android emulator or physical device

### Installation

Clone the repository:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

Navigate to the project directory:

```bash
cd pokemon-flutter-app
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Project Status

The application implements the core Pokédex functionality including Pokémon browsing, search, detailed information, favorites, local persistence, and responsive UI.
