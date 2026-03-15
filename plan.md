# Plan de développement - Application Flutter gChess

## Vue d'ensemble

Application mobile Flutter (Android/iOS) pour jouer aux échecs en ligne, avec authentification JWT, parties contre bots et matchmaking humain en temps réel via WebSocket.

**Architecture**: Clean Architecture + BLoC
**Backend**: Serveur Kotlin existant (../gChess)
**Design**: Interface personnalisée multi-plateforme
**Durée estimée**: 15 jours

## Structure du projet

```
lib/
├── main.dart                          # Point d'entrée, DI setup
├── config/
│   ├── app_config.dart               # URLs API (dev/prod)
│   ├── routes.dart                   # GoRouter navigation
│   └── theme.dart                    # Thème Material custom
├── core/
│   ├── error/
│   │   ├── failures.dart             # Types d'échecs (ServerFailure, NetworkFailure, etc.)
│   │   └── exceptions.dart           # Types d'exceptions
│   ├── network/
│   │   ├── api_client.dart           # Client Dio avec intercepteurs JWT
│   │   ├── websocket_client.dart     # Gestionnaire WebSocket générique
│   │   └── network_info.dart         # Vérification connectivité
│   ├── storage/
│   │   ├── secure_storage.dart       # Stockage tokens JWT
│   │   └── preferences_storage.dart  # Préférences utilisateur
│   ├── utils/
│   │   ├── validators.dart           # Validation email, username, etc.
│   │   └── constants.dart            # Constantes app
│   └── injection.dart                # Container GetIt DI
└── features/
    ├── auth/                         # Authentification
    │   ├── domain/
    │   │   ├── entities/user.dart
    │   │   ├── repositories/auth_repository.dart (interface)
    │   │   └── usecases/
    │   │       ├── register_user.dart
    │   │       ├── login_user.dart
    │   │       ├── logout_user.dart
    │   │       └── get_current_user.dart
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── user_model.dart
    │   │   │   ├── register_request.dart
    │   │   │   ├── login_request.dart
    │   │   │   └── login_response.dart
    │   │   ├── datasources/
    │   │   │   ├── auth_remote_data_source.dart
    │   │   │   └── auth_local_data_source.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── auth_bloc.dart
    │       │   ├── auth_event.dart
    │       │   └── auth_state.dart
    │       └── screens/
    │           ├── login_screen.dart
    │           └── register_screen.dart
    ├── bots/                         # Gestion bots
    │   ├── domain/
    │   │   ├── entities/bot.dart
    │   │   ├── repositories/bot_repository.dart
    │   │   └── usecases/
    │   │       ├── get_all_bots.dart
    │   │       └── get_bot_by_id.dart
    │   ├── data/
    │   │   ├── models/bot_model.dart
    │   │   ├── datasources/bot_remote_data_source.dart
    │   │   └── repositories/bot_repository_impl.dart
    │   └── presentation/
    │       ├── bloc/bot_list_bloc.dart
    │       └── screens/bot_selection_screen.dart
    ├── matchmaking/                  # Matchmaking temps réel
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── match_request.dart
    │   │   │   └── match_result.dart
    │   │   ├── repositories/matchmaking_repository.dart
    │   │   └── usecases/
    │   │       ├── join_matchmaking_queue.dart
    │   │       ├── leave_matchmaking_queue.dart
    │   │       └── request_bot_match.dart
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── match_request_model.dart
    │   │   │   ├── match_found_model.dart
    │   │   │   └── queue_position_model.dart
    │   │   ├── datasources/
    │   │   │   └── matchmaking_websocket_data_source.dart
    │   │   └── repositories/
    │   │       └── matchmaking_repository_impl.dart
    │   └── presentation/
    │       ├── bloc/matchmaking_bloc.dart
    │       └── screens/
    │           ├── play_selection_screen.dart
    │           └── matchmaking_queue_screen.dart
    └── game/                         # Jeu d'échecs
        ├── domain/
        │   ├── entities/
        │   │   ├── chess_game.dart
        │   │   ├── chess_move.dart
        │   │   ├── player.dart
        │   │   └── game_status.dart (enum)
        │   ├── repositories/game_repository.dart
        │   └── usecases/
        │       ├── connect_to_game.dart
        │       ├── send_move.dart
        │       └── disconnect_from_game.dart
        ├── data/
        │   ├── models/
        │   │   ├── chess_game_model.dart
        │   │   ├── move_attempt_message.dart
        │   │   ├── move_executed_message.dart
        │   │   └── game_state_sync_message.dart
        │   ├── datasources/
        │   │   └── game_websocket_data_source.dart
        │   └── repositories/
        │       └── game_repository_impl.dart
        └── presentation/
            ├── bloc/game_bloc.dart
            └── screens/game_screen.dart
            └── widgets/
                ├── chess_board.dart
                ├── chess_square.dart
                ├── chess_piece.dart
                ├── move_history_panel.dart
                └── player_info_card.dart
```

## Dépendances principales (pubspec.yaml)

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Networking
  dio: ^5.4.0
  web_socket_channel: ^2.4.0

  # Chess Logic (CRITIQUE - moteur d'échecs complet)
  chess: ^0.9.1

  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2

  # Utils
  dartz: ^0.10.1           # Either<Failure, Success>
  go_router: ^12.1.3       # Navigation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  ulid: ^2.0.0             # Format IDs backend

dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  injectable_generator: ^2.4.1
  mocktail: ^1.0.1
  bloc_test: ^9.1.5
```

## Phases d'implémentation

### Phase 0: Fondations (Jours 1-2)

**Objectif**: Infrastructure de base du projet.

**Tâches**:
1. Initialiser projet Flutter: `flutter create gchess_mobile --org com.gchess --platforms android,ios`
2. Créer structure de dossiers selon Clean Architecture
3. Configurer `pubspec.yaml` avec toutes les dépendances
4. Implémenter infrastructure core:
   - **`lib/core/injection.dart`**: Container GetIt pour DI
   - **`lib/core/network/api_client.dart`**: Client Dio avec intercepteur JWT
   - **`lib/core/network/websocket_client.dart`**: Gestionnaire WebSocket générique
   - **`lib/core/storage/secure_storage.dart`**: Wrapper flutter_secure_storage pour tokens
   - **`lib/core/error/failures.dart`**: Hiérarchie des erreurs (ServerFailure, NetworkFailure, etc.)
   - **`lib/config/app_config.dart`**: URLs backend (dev: http://localhost:8080, prod: TBD)
   - **`lib/config/routes.dart`**: Configuration GoRouter
   - **`lib/config/theme.dart`**: Thème Material custom

**Détails techniques clés**:

**Intercepteur JWT (api_client.dart)**:
```dart
class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expiré - déclencher logout
    }
    handler.next(err);
  }
}
```

**Client WebSocket (websocket_client.dart)**:
- Reconnexion automatique avec backoff exponentiel
- Stream broadcast pour messages
- Support connexions multiples (matchmaking + game)
- Gestion heartbeat

**Fichiers critiques**:
- `/home/gbourquet/projets/gchess-phone/lib/core/injection.dart`
- `/home/gbourquet/projets/gchess-phone/lib/core/network/api_client.dart`
- `/home/gbourquet/projets/gchess-phone/lib/core/network/websocket_client.dart`
- `/home/gbourquet/projets/gchess-phone/lib/config/app_config.dart`

---

### Phase 1: Authentification (Jours 3-5)

**Objectif**: Registration, login, logout, persistance session JWT.

**APIs utilisées**:
- `POST /api/auth/register` (username, email, password) → UserDTO
- `POST /api/auth/login` (username, password) → LoginResponse (token, user)

**Architecture en couches**:

**1. Domain Layer (Jour 3)**:
- Entity: `User` (id, username, email)
- Repository interface: `AuthRepository`
  - `Future<Either<Failure, User>> register(String username, String email, String password)`
  - `Future<Either<Failure, User>> login(String username, String password)`
  - `Future<Either<Failure, void>> logout()`
  - `Future<Either<Failure, User?>> getCurrentUser()`
- Use cases: `RegisterUser`, `LoginUser`, `LogoutUser`, `GetCurrentUser`

**2. Data Layer (Jours 3-4)**:
- Models: `UserModel`, `RegisterRequest`, `LoginRequest`, `LoginResponse` (avec json_serializable)
- `AuthRemoteDataSource`: Appels Dio vers `/api/auth/*`
- `AuthLocalDataSource`: Sauvegarde/récupération token (SecureStorage) + user (SharedPreferences)
- `AuthRepositoryImpl`: Implémentation avec gestion erreurs (try-catch → Either<Failure, Success>)

**3. Presentation Layer (Jours 4-5)**:
- **`AuthBloc`** avec états:
  - `AuthInitial`, `AuthLoading`, `AuthAuthenticated(User)`, `AuthUnauthenticated`, `AuthError(message)`
- Events: `LoginRequested`, `RegisterRequested`, `LogoutRequested`, `AuthCheckRequested`
- **`LoginScreen`**: Form avec username/password, validation, BlocConsumer
- **`RegisterScreen`**: Form avec username/email/password
- Splash screen: vérifie token au démarrage (`AuthCheckRequested`)

**Navigation**:
- Token valide → `/home`
- Token invalide/absent → `/login`

**Fichiers critiques**:
- `/home/gbourquet/projets/gchess-phone/lib/features/auth/domain/repositories/auth_repository.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/auth/data/datasources/auth_local_data_source.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/auth/presentation/bloc/auth_bloc.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/auth/presentation/screens/login_screen.dart`

---

### Phase 2: Parties contre bots (Jours 6-9)

**Objectif**: Sélection bot, match instantané, jeu d'échecs fonctionnel.

#### Jour 6: Sélection des bots

**APIs**:
- `GET /api/bots` → List<BotDTO>
- `GET /api/bots/{id}` → BotDTO

**Implémentation**:
- Domain: Entity `Bot` (id, name, difficulty, description)
- Data: `BotRemoteDataSource` avec appels Dio
- Presentation: `BotListBloc` + `BotSelectionScreen` (grid/list de bots)

#### Jour 7: Matchmaking bot

**WebSocket**: `/ws/matchmaking`

**Flow**:
1. User sélectionne bot → navigate to matchmaking
2. App envoie message `JoinQueue` avec `{type: "JoinQueue", bot: true, botId: "...", playerColor: "WHITE"}`
3. Backend répond `MatchFound` avec `{gameId, playerId, yourColor, opponentUserId}`
4. Navigate to `GameScreen` avec gameId

**Implémentation**:
- Domain: `MatchRequest`, `MatchResult` entities
- Data: **`MatchmakingWebSocketDataSource`**
  - Connecte à `/ws/matchmaking?token=JWT`
  - Envoie/reçoit messages JSON
  - Stream de events (MatchFound, MatchmakingError)
- Repository: `MatchmakingRepositoryImpl` expose stream
- Presentation: `MatchmakingBloc` subscribe au stream, emit states

**Fichier critique**:
- `/home/gbourquet/projets/gchess-phone/lib/features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart`

#### Jour 8: Échiquier interactif

**Widgets**:
- **`ChessBoard`**: GridView 8x8, utilise package `chess` pour état
- **`ChessSquare`**: Container avec couleur light/dark, highlighting
- **`ChessPiece`**: Widget pièce (Unicode ou assets SVG)

**Interaction**:
- **Tap-tap**: Tap source → highlight legal moves → tap destination → send move
- Promotion: Dialog si pion atteint 8ème rangée

**Package chess**:
```dart
import 'package:chess/chess.dart' as chess_lib;

final chess = chess_lib.Chess();
chess.load(fenString);  // Charger position FEN
final moves = chess.moves(); // Coups légaux
chess.move({'from': 'e2', 'to': 'e4'}); // Jouer coup
```

**Fichier critique**:
- `/home/gbourquet/projets/gchess-phone/lib/features/game/presentation/widgets/chess_board.dart`

#### Jour 9: WebSocket gameplay

**WebSocket**: `/ws/game/{gameId}`

**Messages**:
- Client → Server: `MoveAttempt {type, from, to, promotion?}`
- Server → Client:
  - `GameStateSync {gameId, positionFen, moveHistory, gameStatus, currentSide, ...}` (à la connexion)
  - `MoveExecuted {move, newPositionFen, gameStatus, currentSide, isCheck}`
  - `MoveRejected {reason}`

**Implémentation**:
- Domain: `ChessGame`, `ChessMove`, `GameStatus` (enum)
- Data: **`GameWebSocketDataSource`**
  - Connecte à `/ws/game/{gameId}?token=JWT`
  - Parse messages JSON → domain entities
  - Stream de game events
- Presentation: **`GameBloc`**
  - Subscribe au stream game events
  - États: `GameLoading`, `GameActive(fen, status, ...)`, `GameEnded(result)`
  - Sur `MoveExecuted`: update FEN, re-render board
  - Sur move bot: animate automatiquement
- **`GameScreen`**: ChessBoard + PlayerInfoCard + MoveHistoryPanel + GameStatusOverlay

**Logic**:
```dart
class GameBloc extends Bloc<GameEvent, GameState> {
  final chess_lib.Chess _chess = chess_lib.Chess();

  void _onMoveExecuted(MoveExecutedMessage msg) {
    _chess.load(msg.newPositionFen);
    emit(GameActive(
      fen: msg.newPositionFen,
      gameStatus: msg.gameStatus,
      legalMoves: _chess.moves(),
    ));
  }
}
```

**Orientation board**: Blanc en bas si player=white, noir en bas si player=black.

**Fichiers critiques**:
- `/home/gbourquet/projets/gchess-phone/lib/features/game/data/datasources/game_websocket_data_source.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/game/presentation/bloc/game_bloc.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/game/presentation/screens/game_screen.dart`

---

### Phase 3: Matchmaking humain (Jours 10-12)

**Objectif**: Queue FIFO pour parties humain vs humain.

**WebSocket**: `/ws/matchmaking` (même que bots)

#### Jour 10-11: UI queue + gestion états

**Flow**:
1. User tap "Play vs Human" → `PlaySelectionScreen`
2. Join queue: envoie `JoinQueue {type: "JoinQueue", bot: false}`
3. Backend envoie `QueuePositionUpdate {position: 1, 2, 3...}`
4. `MatchmakingQueueScreen` affiche position + animation attente
5. Backend envoie `MatchFound` → navigate to `GameScreen`

**Implémentation**:
- Réutiliser `MatchmakingWebSocketDataSource` (déjà créé)
- **`MatchmakingBloc`** gère:
  - Events: `JoinHumanQueue`, `LeaveQueue`, `QueuePositionUpdated`, `MatchFoundEvent`
  - États: `MatchmakingIdle`, `InQueue(position)`, `MatchFound(gameId, playerId, color)`, `MatchmakingError`
- **`MatchmakingQueueScreen`**:
  - Affiche position en queue
  - Bouton "Cancel" → `LeaveQueue` → close WebSocket
- Gestion lifecycle: cancel subscription dans `bloc.close()`

#### Jour 12: Tests intégration

- Test flow complet: join queue → position updates → match found → game start
- Test cancellation
- Test erreurs réseau

**Fichiers critiques**:
- `/home/gbourquet/projets/gchess-phone/lib/features/matchmaking/presentation/screens/matchmaking_queue_screen.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/matchmaking/presentation/bloc/matchmaking_bloc.dart`

---

### Phase 4: Polish & production (Jours 13-15)

**Objectif**: UX professionnelle, gestion erreurs, déploiement.

#### Jour 13: Reconnexion & états d'erreur

**Reconnexion WebSocket**:
- Backoff exponentiel: 1s, 2s, 4s, 8s, max 30s
- Overlay "Reconnecting..." pendant tentatives
- Sur reconnexion game: receive `GameStateSync` pour resync
- Messages `PlayerDisconnected`/`PlayerReconnected`: afficher indicateur

**États de chargement**:
- Spinners pour: login, bot list, matchmaking connection, game connection
- Messages d'erreur contextuels
- Boutons retry où approprié

**Fichiers à modifier**:
- `/home/gbourquet/projets/gchess-phone/lib/core/network/websocket_client.dart` (améliorer reconnexion)
- Tous les screens: ajouter LoadingIndicator, ErrorMessage widgets

#### Jour 14: Fin de partie & animations

**Game end**:
- Sur `gameStatus: CHECKMATE/STALEMATE/DRAW`: overlay avec résultat
- Boutons "Rematch" (→ play selection) et "Exit" (→ home)

**Animations**:
- Animate mouvement pièce lors `MoveExecuted`
- Highlight last move (from/to squares)
- Highlight king si isCheck=true
- (Optionnel) Sons pour moves

**Fichiers**:
- `/home/gbourquet/projets/gchess-phone/lib/features/game/presentation/widgets/game_status_overlay.dart`
- `/home/gbourquet/projets/gchess-phone/lib/features/game/presentation/widgets/chess_board.dart` (animations)

#### Jour 15: Navigation & déploiement

**GoRouter routes**:
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/splash'),
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => PlaySelectionScreen()),
    GoRoute(path: '/bots', builder: (_, __) => BotSelectionScreen()),
    GoRoute(path: '/matchmaking', builder: (_, __) => MatchmakingQueueScreen()),
    GoRoute(path: '/game/:gameId', builder: (_, state) => GameScreen(
      gameId: state.pathParameters['gameId']!,
    )),
  ],
  redirect: (context, state) {
    // Auth guard: redirect to /login si non authentifié
  },
);
```

**Configuration déploiement**:
- Android: Configurer signing keystore
- iOS: Provisioning profiles
- App icons + splash screens
- Backend URL prod dans `app_config.dart`

**Build**:
```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Android (Play Store)
flutter build ipa --release        # iOS
```

**Fichiers**:
- `/home/gbourquet/projets/gchess-phone/lib/config/routes.dart`
- `/home/gbourquet/projets/gchess-phone/android/app/build.gradle` (signing)

---

## Décisions techniques critiques

### 1. Package `chess: ^0.9.1`
- **Rôle**: Moteur d'échecs complet (parse FEN, génère coups légaux, détecte échec/mat)
- **Pourquoi**: Évite d'implémenter logique complexe, règles FIDE garanties
- **Usage**: Backend envoie FEN, client utilise `chess` pour render + validation locale (optionnel, UX)

### 2. Architecture Clean + BLoC
- **Couches**: Domain (entities, repos, usecases) → Data (models, datasources) → Presentation (blocs, screens)
- **BLoC**: Event-driven, testable, fit naturel pour WebSocket streams
- **Either<Failure, Success>**: Pattern fonctionnel pour gestion erreurs explicite

### 3. WebSocket lifecycle
- **Matchmaking**: Connecte à `/ws/matchmaking`, ferme lors `MatchFound`
- **Game**: Connecte à `/ws/game/{gameId}`, reste ouvert pendant partie
- **Reconnexion**: Automatique avec backoff, resync via `GameStateSync`

### 4. JWT storage
- Tokens dans `flutter_secure_storage` (encrypted)
- Dio interceptor injecte `Authorization: Bearer <token>` automatiquement
- WebSocket: token en query param `?token=<token>`
- Expiration 24h: gérer 401 → logout + redirect login

### 5. Input moves
- **Primaire**: Tap-tap (tap source → highlight legal moves → tap destination)
- **Promotion**: Dialog pour choisir pièce (Queen/Rook/Bishop/Knight)
- Board orientation: flip selon couleur joueur

---

## Scope MVP

### ✅ Inclus
- Registration, login, logout, session persistence
- Liste bots, sélection, match instantané
- Matchmaking humain avec queue FIFO
- Jeu d'échecs temps réel (WebSocket)
- Validation moves, détection échec/mat
- Historique moves affiché
- Reconnexion automatique
- Gestion erreurs et loading states
- Animations moves de base
- UI Material custom

### ❌ Exclu (post-MVP)
- Mode spectateur (backend ready, pas UI)
- Historique parties jouées
- Time controls (blitz, rapid)
- Chat in-game
- Analyse parties (engine)
- Puzzles/training
- Système d'amis
- Classement Elo
- Notifications push
- PGN export/import

---

## Commandes utiles

```bash
# Init projet
flutter create gchess_mobile --org com.gchess --platforms android,ios

# Code generation (après modif models/freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# Tests
flutter test
flutter test --coverage

# Analyse
flutter analyze
flutter format lib test

# Build
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release  # Play Store
flutter build ipa --release         # iOS

# Run
flutter run -d <device-id>
```

---

## Tests

**Unit tests**:
- Use cases: mock repositories
- Repositories: mock data sources
- BLoCs: `bloc_test` package

**Widget tests**:
- Screens: mock BLoCs, test rendering selon états
- Chess board: test interaction tap, drag

**Integration tests**:
- Flow complet auth
- Flow complet bot game
- Flow complet human matchmaking + game

---

## Fichiers les plus critiques

1. **`lib/core/network/websocket_client.dart`**
   - Gère toutes connexions WebSocket, reconnexion, lifecycle

2. **`lib/features/game/data/datasources/game_websocket_data_source.dart`**
   - Protocole WebSocket `/ws/game/{gameId}`, parsing messages

3. **`lib/features/game/presentation/bloc/game_bloc.dart`**
   - State management central du jeu, intègre `chess` package + WebSocket

4. **`lib/features/game/presentation/widgets/chess_board.dart`**
   - UI échiquier interactif, rendering FEN, input moves

5. **`lib/core/injection.dart`**
   - Dependency injection, wire toutes les couches

6. **`lib/features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart`**
   - Protocole WebSocket `/ws/matchmaking`, gestion queue

---

## Notes importantes

- Backend existant dans `../gChess` doit être lancé localement (port 8080)
- JWT valide 24h, pas de refresh token dans MVP
- IDs au format ULID (UserId, PlayerId, GameId, BotId)
- Bot usernames commencent par "bot_" (identifier bots vs humains)
- FEN string = format standard pour position échiquier
- Matchmaking bot = instantané, matchmaking humain = queue FIFO

---

## Résultat attendu

Application Flutter fonctionnelle permettant de:
1. Créer compte / se connecter
2. Choisir "Jouer contre bot" ou "Jouer contre humain"
3. Si bot: sélectionner bot → partie immédiate
4. Si humain: rejoindre queue → voir position → match trouvé → partie
5. Jouer aux échecs en temps réel avec validation moves
6. Voir résultat partie (échec et mat, pat, nulle)
7. Revenir au menu principal

Target: APK < 20MB, 60fps gameplay, < 500ms move latency.
