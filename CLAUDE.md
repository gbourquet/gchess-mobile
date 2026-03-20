# CLAUDE.md

Ce fichier fournit des instructions à Claude Code pour ce dépôt.

## Vue d'ensemble du projet

Application mobile Flutter **gChess** pour jouer aux échecs en ligne.
Backend Kotlin dans `../gChess` — specs REST dans `../gChess/src/main/resources/openapi/openapi.json`.

## Stack

- **State management** : Riverpod v3 (`flutter_riverpod ^3.3.1`) — `Notifier`, `AsyncNotifier`, `autoDispose`
- **Navigation** : GoRouter v17
- **HTTP** : Dio + intercepteur JWT automatique (`ApiClient`)
- **WebSocket** : `web_socket_channel`
- **Logique échecs** : `chess ^0.8.1`
- **DI** : GetIt + Injectable
- **Either** : `dartz`
- **Tests** : `mocktail`, pas de `bloc_test` (plus de BLoC)

## Architecture

Clean Architecture par feature : `domain → data → presentation`

```
lib/
├── config/           # app_config, router_provider, routes, theme
├── core/             # ApiClient (Dio), WebSocketClient, SecureStorage, PreferencesStorage, injection
└── features/
    ├── auth/         # User, AuthNotifier (AsyncNotifier)
    ├── lobby/        # LobbyScreen, sélection contrôle du temps
    ├── matchmaking/  # MatchmakingNotifier (AsyncNotifier), WebSocket /ws/matchmaking
    ├── game/         # GameNotifier (Notifier autoDispose), WebSocket /ws/game/{gameId}
    └── history/      # GameHistoryNotifier (AsyncNotifier), REST /api/history/*
```

## Règles de développement

### TDD obligatoire

Toujours **Red → Green → Refactor**. Écrire le test qui échoue avant d'écrire le code.

```bash
flutter test                    # tous les tests
flutter test <fichier_test>     # un fichier
flutter test --coverage         # avec couverture
```

Structure miroir : `lib/features/foo/bar.dart` → `test/features/foo/bar_test.dart`

### Patterns Riverpod v3

```dart
// Notifier synchrone (game)
final myProvider = NotifierProvider.autoDispose<MyNotifier, MyState>(MyNotifier.new);
class MyNotifier extends Notifier<MyState> { ... }

// Notifier asynchrone (auth, history)
final myProvider = AsyncNotifierProvider<MyNotifier, List<T>>(MyNotifier.new);
class MyNotifier extends AsyncNotifier<List<T>> { ... }

// Tests : ProviderContainer isolé, dispose en tearDown
final container = ProviderContainer(overrides: [...]);
addTearDown(container.dispose);
```

### Mocks

- Interfaces de repository → fakes manuels (classe concrète qui implémente l'interface)
- Classes concrètes → `mocktail`
- Enregistrer les fallback values pour les types custom : `registerFallbackValue(...)`

### Gestion d'état Riverpod dans les widgets

```dart
// ConsumerWidget (lecture seule)
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) { ... }
}

// ConsumerStatefulWidget (état local + Riverpod)
class MyWidget extends ConsumerStatefulWidget { ... }
class _MyWidgetState extends ConsumerState<MyWidget> { ... }
```

### AsyncValue dans les écrans

```dart
final asyncData = ref.watch(myAsyncProvider);
asyncData.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Erreur : $e'),
  data: (data) => MyWidget(data: data),
);
```

## Endpoints backend

### REST (via `ApiClient` — JWT auto-injecté)

| Endpoint | Description |
|---|---|
| `POST /api/auth/register` | Inscription |
| `POST /api/auth/login` | Connexion → token JWT |
| `GET /api/history/games` | Liste des parties du joueur connecté |
| `GET /api/history/games/{gameId}/moves` | Coups d'une partie (UCI) |

### WebSocket (token via `?token=<JWT>`)

| Canal | Description |
|---|---|
| `/ws/matchmaking` | File d'attente et matching |
| `/ws/game/{gameId}` | Gameplay temps réel |

## Conventions

- **Langue** : code en anglais, commentaires et messages utilisateur en français
- **Nommage providers** : `fooNotifierProvider` + `FooNotifier`
- **Identifiants** : format ULID (UserId permanent ≠ PlayerId par partie)
- **Winner CHECKMATE** : le camp à jouer dans la position finale est le perdant (`chess.turn == Color.BLACK` → blanc gagne)
- **Pas de `print()`** dans le code final (les `print` de debug dans `game_provider.dart` sont intentionnels pour le diagnostic)
- **Couverture cible** : ≥ 80 % (actuellement 87,4 %)

## Commandes utiles

```bash
# Régénérer le code (après modif @injectable ou @JsonSerializable)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'app
flutter run

# Analyser
flutter analyze
flutter format lib test
```
