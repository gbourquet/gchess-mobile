# gChess Mobile

Application mobile Flutter pour jouer aux échecs en ligne, connectée au backend [gChess](https://shimmering-spirit-production.up.railway.app) via REST et WebSocket.

## Fonctionnalités

- **Authentification** — inscription, connexion, persistance JWT
- **Lobby** — sélection du contrôle du temps (Bullet, Blitz, Rapide, Classique)
- **Matchmaking** — file d'attente humain vs humain et humain vs bot
- **Partie en temps réel** via WebSocket
  - Échiquier interactif avec pièces SVG
  - Indicateurs de coups légaux (points verts)
  - **Pre-move** — préparer son coup pendant le tour adverse (points et cases oranges), joué automatiquement dès que le tour revient
  - Promotion de pion (choix de la pièce)
  - Horloge avec décompte en temps réel et incrément
  - Historique des coups navigable (mode révision)
  - Mise en évidence du dernier coup joué, roi en échec
  - Proposer / accepter / refuser la nulle
  - Abandon avec confirmation
  - Réclamation de timeout
- **Fin de partie** — écran de résultat (mat, pat, nulle, abandon, timeout)

## Architecture

Clean Architecture par feature, avec le pattern BLoC pour la gestion d'état.

```
lib/
├── config/
│   ├── app_config.dart       # URLs dev/prod, environnement
│   ├── routes.dart           # GoRouter + guards d'auth
│   └── theme.dart            # Couleurs et thème global
├── core/
│   ├── error/                # Exceptions et Failures (dartz Either)
│   ├── network/              # ApiClient (Dio), WebSocketClient
│   ├── storage/              # SecureStorage (JWT), PreferencesStorage
│   └── injection.dart        # GetIt + Injectable
└── features/
    ├── auth/                 # Inscription, connexion, persistance token
    ├── lobby/                # Sélection du contrôle du temps
    ├── matchmaking/          # File d'attente via WebSocket
    └── game/                 # Partie en temps réel
        ├── domain/
        │   ├── entities/     # ChessGame, ChessMove, Player, GameStatus
        │   ├── repositories/ # GameRepository + GameStreamEvent
        │   └── usecases/     # ConnectToGame, SendMove, DisconnectFromGame, ClaimTimeout
        ├── data/
        │   ├── datasources/  # GameWebSocketDataSource
        │   └── repositories/ # GameRepositoryImpl
        └── presentation/
            ├── bloc/         # GameBloc, GameEvent, GameState
            ├── screens/      # GameScreen
            └── widgets/      # ChessBoard, ChessSquare, ChessPiece, GameClock, MoveHistoryPanel
```

Chaque feature suit le découpage **domain → data → presentation** :
- **domain** : entités, interfaces de repository, use cases (indépendants du framework)
- **data** : implémentations concrètes, modèles JSON, data sources (REST/WS)
- **presentation** : BLoC + écrans + widgets Flutter

## Stack technique

| Domaine | Librairie |
|---|---|
| State management | `flutter_bloc` + `equatable` |
| Navigation | `go_router` |
| HTTP | `dio` |
| WebSocket | `web_socket_channel` |
| Logique échecs | `chess` |
| Injection de dépendances | `get_it` + `injectable` |
| Stockage sécurisé | `flutter_secure_storage` |
| Préférences | `shared_preferences` |
| Fonctionnel (Either) | `dartz` |
| Identifiants | `ulid` |
| Fonts | `google_fonts` (Fredoka) |
| SVG | `flutter_svg` |
| Sérialisation | `json_serializable` + `freezed` |

## Backend

Le backend gChess expose :
- **REST** (`/api/auth/register`, `/api/auth/login`, `/api/bots`) — authentification JWT
- **WebSocket** (`/ws/matchmaking`, `/ws/game/{gameId}`) — matchmaking et gameplay temps réel

Les identifiants sont au format ULID (UserId, PlayerId, GameId, BotId).

| Environnement | URL |
|---|---|
| Développement | `http://10.0.2.2:8080` (émulateur Android → localhost) |
| Production | `https://shimmering-spirit-production.up.railway.app` |

## Lancer le projet

```bash
# Installer les dépendances
flutter pub get

# Générer le code (injection, JSON)
dart run build_runner build --delete-conflicting-outputs

# Lancer sur émulateur ou device
flutter run
```

L'environnement est détecté automatiquement (`kDebugMode` → développement, release → production).
