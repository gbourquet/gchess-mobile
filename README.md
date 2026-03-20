# gChess Mobile

Application mobile Flutter pour jouer aux échecs en ligne, connectée au backend [gChess](https://github.com/gbourquet/gChess) via REST et WebSocket.

## Fonctionnalités

- **Authentification** — inscription, connexion, déconnexion, persistance JWT
- **Lobby** — sélection du contrôle du temps (Bullet, Blitz, Rapide, Classique, Personnalisé) avec menu hamburger
- **Historique** — liste des parties terminées chargée depuis le backend, avec revue sur l'échiquier
- **Matchmaking** — file d'attente humain vs humain et humain vs bot (matching instantané)
- **Partie en temps réel** via WebSocket
  - Échiquier interactif avec pièces SVG
  - Indicateurs de coups légaux (points verts)
  - **Pre-move** — préparer son coup pendant le tour adverse (points et cases oranges), joué automatiquement dès que le tour revient
  - Promotion de pion (choix de la pièce via dialog)
  - Horloge avec décompte local 1 Hz + synchronisation WebSocket, alertes visuelles (orange < 60 s, rouge < 10 s, pulsation < 5 s)
  - Historique des coups navigable (mode révision, horloge suspendue)
  - Mise en évidence du dernier coup joué, roi en échec
  - Proposer / accepter / refuser la nulle
  - Abandon avec confirmation
  - Réclamation de timeout
- **Fin de partie** — écran de résultat (mat, pat, nulle, abandon, timeout)
- **Revue de partie** — rejouer une partie coup par coup depuis l'historique

## Architecture

Clean Architecture par feature, avec **Riverpod v3** pour la gestion d'état.

```
lib/
├── config/
│   ├── app_config.dart        # URLs dev/prod, gestion d'environnement
│   ├── router_provider.dart   # GoRouter + guards d'authentification
│   ├── routes.dart            # Constantes de routes
│   └── theme.dart             # Couleurs et thème global (AppColors)
├── core/
│   ├── debug/                 # Overlay de debug (switch d'environnement)
│   ├── error/                 # Exceptions et Failures (dartz Either)
│   ├── network/               # ApiClient (Dio + JWT interceptor), WebSocketClient
│   ├── storage/               # SecureStorage (JWT/credentials), PreferencesStorage
│   └── injection.dart         # GetIt + Injectable
└── features/
    ├── auth/                  # Inscription, connexion, persistance token
    │   ├── domain/            # User, AuthRepository, use cases (Login/Register/Logout/GetCurrentUser)
    │   ├── data/              # Models JSON, AuthRemoteDataSource, AuthLocalDataSource
    │   └── presentation/      # AuthNotifier (AsyncNotifier), LoginScreen, RegisterScreen
    ├── lobby/                 # Sélection du contrôle du temps
    │   └── presentation/      # LobbyScreen, TimeControlPresetButton, CustomGameDialog
    ├── matchmaking/           # File d'attente via WebSocket /ws/matchmaking
    │   ├── domain/            # MatchRequest, MatchmakingRepository
    │   ├── data/              # MatchmakingWebSocketDataSource
    │   └── presentation/      # MatchmakingNotifier, MatchmakingQueueScreen
    ├── game/                  # Partie en temps réel via WebSocket /ws/game/{gameId}
    │   ├── domain/
    │   │   ├── entities/      # ChessGame, ChessMove, Player, GameStatus
    │   │   ├── repositories/  # GameRepository + GameStreamEvent (sealed events)
    │   │   └── usecases/      # ConnectToGame, SendMove, ClaimTimeout
    │   ├── data/
    │   │   ├── datasources/   # GameWebSocketDataSource
    │   │   └── repositories/  # GameRepositoryImpl
    │   └── presentation/
    │       ├── bloc/          # GameState (GameInitial/Loading/Active/Ended/Error)
    │       ├── providers/     # GameNotifier (Notifier autoDispose)
    │       ├── screens/       # GameScreen
    │       └── widgets/       # ChessBoard, ChessSquare, ChessPiece, GameClock, MoveHistoryPanel
    └── history/               # Historique des parties terminées
        ├── domain/
        │   └── entities/      # GameRecord (métadonnées + histories SAN/FEN/UCI)
        ├── data/
        │   ├── datasources/   # HistoryRemoteDataSource (GET /api/history/games et /moves)
        │   ├── models/        # GameSummaryDTO, MoveSummaryDTO
        │   └── repositories/  # HistoryRemoteRepository (reconstruction SAN/FEN, calcul winner)
        └── presentation/
            ├── providers/     # GameHistoryNotifier (AsyncNotifier)
            └── screens/       # HistoryScreen, GameReviewScreen
```

Chaque feature suit le découpage **domain → data → presentation** :
- **domain** : entités, interfaces de repository, use cases (zéro dépendance framework)
- **data** : implémentations concrètes, modèles JSON, data sources (REST/WebSocket)
- **presentation** : Notifiers Riverpod + écrans + widgets Flutter

## Stack technique

| Domaine | Librairie | Version |
|---|---|---|
| State management | `flutter_riverpod` | ^3.3.1 |
| Navigation | `go_router` | ^17.0.0 |
| HTTP | `dio` | ^5.9.0 |
| WebSocket | `web_socket_channel` | ^3.0.3 |
| Logique échecs | `chess` | ^0.8.1 |
| Injection de dépendances | `get_it` + `injectable` | ^9.2.0 / ^2.7.1 |
| Stockage sécurisé | `flutter_secure_storage` | ^9.2.4 |
| Préférences | `shared_preferences` | ^2.5.3 |
| Fonctionnel (Either) | `dartz` | ^0.10.1 |
| Identifiants | `ulid` | ^2.0.0 |
| Fonts | `google_fonts` (Fredoka) | ^6.2.1 |
| SVG | `flutter_svg` | ^2.0.10 |
| Sérialisation | `json_serializable` + `freezed` | ^6.9.0 / ^3.2.3 |
| Tests | `mocktail` | ^1.0.4 |

## Backend

Le backend gChess expose :

**REST** (authentification + historique) :

| Endpoint | Description |
|---|---|
| `POST /api/auth/register` | Inscription — renvoie `UserDTO` |
| `POST /api/auth/login` | Connexion — renvoie `LoginResponse` (token JWT + user) |
| `GET /api/history/games` | Liste des parties du joueur connecté |
| `GET /api/history/games/{gameId}/moves` | Coups d'une partie (format UCI) |

**WebSocket** (temps réel) :

| Canal | Description |
|---|---|
| `/ws/matchmaking` | File d'attente et matching (humain et bot) |
| `/ws/game/{gameId}` | Gameplay — coups, synchro état, horloge |

L'authentification WebSocket se fait via le paramètre de query `?token=<JWT>`.

Les identifiants sont au format ULID (UserId, PlayerId, GameId, BotId).

| Environnement | URL |
|---|---|
| Développement | `http://10.0.2.2:8080` (émulateur Android) / `http://localhost:8080` (iOS) |
| Production | `https://shimmering-spirit-production.up.railway.app` |

L'environnement est sélectionnable via l'overlay de debug (triple tap + double tap simultané en mode debug).

## Lancer le projet

```bash
# Installer les dépendances
flutter pub get

# Générer le code (injection, JSON)
dart run build_runner build --delete-conflicting-outputs

# Lancer sur émulateur ou device
flutter run
```

## Tests

```bash
# Tous les tests
flutter test

# Avec rapport de couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html   # macOS
xdg-open coverage/html/index.html  # Linux

# Tests d'un seul fichier
flutter test test/features/game/presentation/providers/game_provider_test.dart
```

**État actuel** : 686 tests, 87,4 % de couverture de lignes.

### Organisation des tests

```
test/
├── core/
│   └── debug/                     # DebugOverlay, AppConfig
└── features/
    ├── auth/                       # User, AuthRepository, use cases, providers
    ├── game/
    │   ├── domain/                 # ChessGame, ChessMove, GameStatus
    │   ├── presentation/
    │   │   ├── bloc/               # GameState
    │   │   ├── providers/          # GameNotifier (50+ tests)
    │   │   └── screens/            # GameScreen widget tests
    │   └── data/                   # WebSocket data source
    ├── history/
    │   ├── domain/                 # GameRecord
    │   ├── data/
    │   │   ├── models/             # GameSummaryDTO, MoveSummaryDTO
    │   │   └── repositories/       # HistoryRemoteRepository
    │   └── presentation/
    │       ├── providers/          # GameHistoryNotifier
    │       └── screens/            # HistoryScreen, GameReviewScreen
    └── matchmaking/                # MatchmakingNotifier
```

Les mocks sont écrits manuellement (interfaces de repository) ou via `mocktail` pour les classes concrètes.

## Décisions techniques

### Riverpod v3 — `Notifier` et `AsyncNotifier`

Toute la gestion d'état utilise Riverpod v3 :
- `GameNotifier extends Notifier<GameState>` (autoDispose) — vit le temps de l'écran de jeu
- `AuthNotifier extends AsyncNotifier<User?>` — keepAlive, vit toute la durée de l'app
- `GameHistoryNotifier extends AsyncNotifier<List<GameRecord>>` — chargement asynchrone depuis le backend
- `MatchmakingNotifier extends AsyncNotifier<MatchmakingState>` — file d'attente

### Historique — chargement paresseux des coups

L'écran d'historique charge la liste des parties en résumé (`GET /api/history/games`). Quand l'utilisateur tape une tuile, les coups sont chargés à la demande (`GET /api/history/games/{gameId}/moves`), puis rejoués avec la bibliothèque `chess` pour reconstruire les histories SAN et FEN nécessaires à la revue.

Le winner est calculé localement pour CHECKMATE (le camp à jouer dans la position finale est le perdant). Pour RESIGNED et TIMEOUT, il n'est pas déterminable depuis l'API (affiché `"-"`).

### Horloge locale + synchro WebSocket

Le décompte de l'horloge est géré localement par un `Timer.periodic` d'1 Hz. À chaque coup reçu via WebSocket (`MoveExecuted`), les temps restants sont resynchronisés depuis le serveur. En mode révision, l'horloge est suspendue.

### JWT et refresh automatique

Le `JwtInterceptor` de Dio injecte le token sur chaque requête REST. Sur une réponse 401, il tente un re-login avec les credentials stockés dans `SecureStorage`. Si le re-login échoue, les credentials sont effacés.

### Pre-move

Quand ce n'est pas le tour du joueur, il peut enregistrer un coup anticipé. Dès que le tour revient (détecté via `MoveExecuted`), la légalité est re-vérifiée dans la nouvelle position et le coup est envoyé automatiquement s'il est toujours légal.
