# Pokédex Flutter App

A Flutter Pokédex application built using the PokéAPI. The app allows users to browse Pokémon, search Pokémon, view detailed information, and manage persistent favorites.

## Features

* Pokémon list with pagination
* Infinite scrolling
* Search by Pokémon name or Pokédex ID
* Pokémon detail screen
* Pokémon types, abilities, height, weight, and base stats
* Add/remove Pokémon from favorites
* Favorites synchronized across List, Detail, and Favorites screens
* Persistent favorites using local storage
* Loading, error, empty, and retry states
* Responsive portrait layout

## Tech Stack

* Flutter
* Dart
* Riverpod
* SharedPreferences
* HTTP
* PokéAPI

## State Management

Riverpod is used for application state management.

Favorites are maintained through a centralized `FavoritesProvider`, which acts as the single source of truth. The List, Detail, and Favorites screens all read and update the same state, ensuring that favorite changes are reflected immediately across the application.

## Local Storage

SharedPreferences is used to persist favorite Pokémon IDs locally.

Only the IDs of favorited Pokémon are stored. This allows favorites to remain available after restarting the application without requiring a backend database.

## API

The application uses PokéAPI:

```text
https://pokeapi.co/api/v2
```

Pokémon list:

```text
GET /pokemon?limit={limit}&offset={offset}
```

Pokémon details:

```text
GET /pokemon/{id-or-name}
```

## Project Structure

```text
lib/
├── models/
├── services/
├── providers/
├── screens/
├── widgets/
└── utils/
```

The project separates API/data services, state management, models, screens, and reusable UI components.

## Running the Project

Install Flutter and ensure it is configured correctly:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Testing

Run the test suite:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

## Known Limitations

* Pokémon data depends on the availability of PokéAPI.
* Favorites are stored locally on the device and are not synchronized between devices.
* Some Pokémon forms may have limited artwork availability.
