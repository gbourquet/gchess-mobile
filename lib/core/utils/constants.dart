class AppConstants {
  // API Endpoints
  static const String authRegisterEndpoint = '/api/auth/register';
  static const String authLoginEndpoint = '/api/auth/login';
  // WebSocket Paths
  static const String matchmakingWsPath = '/ws/matchmaking';
  static String gameWsPath(String gameId) => '/ws/game/$gameId';
  static String spectateWsPath(String gameId) => '/ws/game/$gameId/spectate';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'cached_user';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // WebSocket
  static const int maxReconnectAttempts = 5;
  static const List<int> reconnectBackoffDelays = [1, 2, 4, 8, 30];

  // Chess
  static const List<String> promotionPieces = ['q', 'r', 'b', 'n'];

  // UI
  static const double boardPadding = 16.0;
  static const double pieceAnimationDuration = 300.0;
}
