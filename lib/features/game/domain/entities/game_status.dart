enum GameStatus {
  active,
  checkmate,
  stalemate,
  draw,
  resigned,
  timeout,
}

extension GameStatusExtension on GameStatus {
  static GameStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return GameStatus.active;
      case 'CHECKMATE':
        return GameStatus.checkmate;
      case 'STALEMATE':
        return GameStatus.stalemate;
      case 'DRAW':
        return GameStatus.draw;
      case 'RESIGNED':
        return GameStatus.resigned;
      case 'TIMEOUT':
        return GameStatus.timeout;
      default:
        return GameStatus.active;
    }
  }

  String toApiString() {
    return toString().split('.').last.toUpperCase();
  }
}
