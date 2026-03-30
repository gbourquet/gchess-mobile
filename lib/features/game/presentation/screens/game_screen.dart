import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';
import 'package:gchess_mobile/features/game/presentation/providers/game_provider.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_board.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/game_clock.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/move_history_panel.dart';

class GameScreen extends StatelessWidget {
  final String gameId;
  final String playerId;

  const GameScreen({super.key, required this.gameId, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return GameView(gameId: gameId, playerId: playerId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background painter — dark chess room ambiance
// ─────────────────────────────────────────────────────────────────────────────

class _RoomBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF08131F), Color(0xFF0B1E30), Color(0xFF0A1828)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Side panels (teal room walls)
    final panelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0A3535).withValues(alpha: 0.8),
          const Color(0xFF0A3535).withValues(alpha: 0.3),
        ],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.1, size.width * 0.14, size.height * 0.8));

    // Left panel
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, size.height * 0.1, size.width * 0.14, size.height * 0.8),
        topRight: const Radius.circular(12),
        bottomRight: const Radius.circular(12),
      ),
      panelPaint,
    );

    // Right panel
    final rightPanelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          const Color(0xFF0A3535).withValues(alpha: 0.8),
          const Color(0xFF0A3535).withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(
          size.width * 0.86, size.height * 0.1, size.width * 0.14, size.height * 0.8));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
            size.width * 0.86, size.height * 0.1, size.width * 0.14, size.height * 0.8),
        topLeft: const Radius.circular(12),
        bottomLeft: const Radius.circular(12),
      ),
      rightPanelPaint,
    );

    // Neon lines
    final cyanLine = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(0, size.height * 0.1), Offset(size.width, size.height * 0.1), cyanLine);

    final pinkLine = Paint()
      ..color = const Color(0xFFFF2D9B).withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(0, size.height * 0.9), Offset(size.width, size.height * 0.9), pinkLine);

    // Trophy/ornament dots on side panels
    final dotPaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.07, size.height * (0.3 + i * 0.15)),
        4,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.93, size.height * (0.3 + i * 0.15)),
        4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// GameView
// ─────────────────────────────────────────────────────────────────────────────

class GameView extends ConsumerStatefulWidget {
  final String gameId;
  final String playerId;

  const GameView({super.key, required this.gameId, required this.playerId});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with WidgetsBindingObserver {
  final chess_lib.Chess _chess = chess_lib.Chess();
  String? _lastShownDrawOfferId;
  Timer? _clockTimer;
  DateTime? _backgroundedAt;

  final List<String> _sanHistory = [];
  final List<String> _fenHistory = [];
  List<String> _uciHistory = [];
  int _reviewIndex = -1;
  ChessMove? _preMove;

  bool get _isReviewing => _reviewIndex >= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startClockTimer();
    // Connexion après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(gameNotifierProvider.notifier).connect(widget.gameId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    // La déconnexion WebSocket est gérée par ref.onDispose dans GameNotifier
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      default:
        break;
    }
  }

  void _onAppResumed() {
    if (_backgroundedAt == null) return;
    final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
    _backgroundedAt = null;
    if (elapsed <= 0) return;

    final currentState = ref.read(gameNotifierProvider);
    if (currentState is! GameActive) return;
    if (_isReviewing) return;

    final isWhiteTurn = currentState.game.currentSide == 'WHITE';
    final moveCount = currentState.game.moveHistory.length;
    final clockStarted = isWhiteTurn ? moveCount >= 1 : moveCount >= 2;
    if (!clockStarted) return;

    for (int i = 0; i < elapsed; i++) {
      ref.read(gameNotifierProvider.notifier).tickClock(isWhiteTurn);
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final state = ref.read(gameNotifierProvider);
      if (state is GameActive && !_isReviewing) {
        final isWhiteTurn = state.game.currentSide == 'WHITE';

        if (state.whiteTimeRemainingMs != null &&
            state.blackTimeRemainingMs != null) {
          final time = isWhiteTurn
              ? state.whiteTimeRemainingMs!
              : state.blackTimeRemainingMs!;

          final moveCount = state.game.moveHistory.length;
          final clockStarted =
              isWhiteTurn ? moveCount >= 1 : moveCount >= 2;

          if (time > 0 && clockStarted) {
            ref.read(gameNotifierProvider.notifier).tickClock(isWhiteTurn);
          }
        }
      }
    });
  }

  void _updateHistory(List<String> uciMoves) {
    if (uciMoves.length == _uciHistory.length) return;

    final replayChess = chess_lib.Chess();
    final newSan = <String>[];
    final newFen = <String>[];

    for (final uci in uciMoves) {
      final parts = uci.split('-');
      if (parts.length < 2) continue;
      final from = parts[0];
      final to = parts[1];

      String san = uci;
      final verboseMoves = replayChess.moves({'square': from, 'verbose': true});
      for (final m in verboseMoves) {
        if (m is Map && m['to'] == to) {
          san = m['san'] as String? ?? uci;
          break;
        }
      }

      final success = replayChess.move({'from': from, 'to': to});
      if (success) {
        newSan.add(san);
        newFen.add(replayChess.fen);
      }
    }

    setState(() {
      _uciHistory = List.from(uciMoves);
      _sanHistory
        ..clear()
        ..addAll(newSan);
      _fenHistory
        ..clear()
        ..addAll(newFen);
    });
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= _fenHistory.length) return;
    setState(() => _reviewIndex = index);
  }

  void _returnToLive() => setState(() => _reviewIndex = -1);
  void _navigateFirst() {
    if (_fenHistory.isNotEmpty) _navigateTo(0);
  }

  void _navigatePrevious() {
    if (_isReviewing) {
      if (_reviewIndex > 0) {
        _navigateTo(_reviewIndex - 1);
      }
    } else if (_fenHistory.isNotEmpty) {
      _navigateTo(_fenHistory.length - 1);
    }
  }

  void _navigateNext() {
    if (!_isReviewing) return;
    if (_reviewIndex < _fenHistory.length - 1) {
      _navigateTo(_reviewIndex + 1);
    } else {
      _returnToLive();
    }
  }

  void _navigateLast() => _returnToLive();

  void _tryFirePreMove(GameActive state) {
    if (_preMove == null) return;
    final isPlayerWhite =
        state.game.whitePlayer.playerId == widget.playerId;
    final playerSide = isPlayerWhite ? 'WHITE' : 'BLACK';
    if (state.game.currentSide != playerSide) return;

    final preMove = _preMove!;
    setState(() => _preMove = null);

    // Valider la légalité dans la nouvelle position
    final chess = chess_lib.Chess();
    chess.load(state.game.positionFen);
    final moves = chess.moves({'square': preMove.from, 'verbose': true});
    final isLegal = moves.any(
      (m) => m is Map && m['to'] == preMove.to,
    );
    if (isLegal) {
      ref.read(gameNotifierProvider.notifier).makeMove(preMove);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute pour les side effects (dialogs, snackbars, historique)
    ref.listen(gameNotifierProvider, (previous, current) {
      // Ignorer si seulement les horloges ont changé
      if (previous is GameActive &&
          current is GameActive &&
          previous.game == current.game) {
        return;
      }

      if (current is GameActive) {
        _updateHistory(current.game.moveHistory);
        _tryFirePreMove(current);
      }
      if (current is GameEnded) {
        setState(() => _preMove = null);
      }
      if (current is GameError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final state = ref.watch(gameNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _RoomBackgroundPainter()),
          ),
          SafeArea(
            child: _buildContent(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameState state) {
    if (state is GameLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      );
    } else if (state is GameEnded) {
      _chess.load(state.game.positionFen);
      final isPlayerWhite =
          state.game.whitePlayer.playerId == widget.playerId;
      return _buildGameEndedView(context, state, isPlayerWhite);
    } else if (state is GameActive) {
      final isPlayerWhite =
          state.game.whitePlayer.playerId == widget.playerId;

      final String fenToDisplay =
          _isReviewing && _fenHistory.isNotEmpty
              ? _fenHistory[_reviewIndex]
              : state.game.positionFen;
      _chess.load(fenToDisplay);

      String? displayLastFrom;
      String? displayLastTo;
      if (_isReviewing &&
          _reviewIndex >= 0 &&
          _reviewIndex < _uciHistory.length) {
        final parts = _uciHistory[_reviewIndex].split('-');
        if (parts.length >= 2) {
          displayLastFrom = parts[0];
          displayLastTo = parts[1];
        }
      } else {
        displayLastFrom = state.lastMoveFrom;
        displayLastTo = state.lastMoveTo;
      }

      if (!_isReviewing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.pendingDrawOfferId != null &&
              _lastShownDrawOfferId != state.pendingDrawOfferId) {
            _lastShownDrawOfferId = state.pendingDrawOfferId;
            _showDrawOfferDialog(context, state.pendingDrawOfferId!);
          } else if (state.pendingDrawOfferId == null) {
            _lastShownDrawOfferId = null;
          }
        });
      }

      return Column(
        children: [
          _buildHeader(),
          _IsolatedGameClock(
            isWhite: !isPlayerWhite,
            isPlayerWhite: isPlayerWhite,
            isReviewing: _isReviewing,
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: ChessBoard(
                      chess: _chess,
                      positionFen: fenToDisplay,
                      isPlayerWhite: isPlayerWhite,
                      onMove: _isReviewing
                          ? null
                          : (from, to, promotion) {
                              ref
                                  .read(gameNotifierProvider.notifier)
                                  .makeMove(
                                    ChessMove(
                                      from: from,
                                      to: to,
                                      promotion: promotion,
                                    ),
                                  );
                            },
                      onPreMove: _isReviewing
                          ? null
                          : (from, to, promotion) {
                              setState(() {
                                _preMove = ChessMove(
                                  from: from,
                                  to: to,
                                  promotion: promotion,
                                );
                              });
                            },
                      lastMoveFrom: displayLastFrom,
                      lastMoveTo: displayLastTo,
                    ),
                  ),
                ),
                if (_isReviewing)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history,
                                color: AppColors.neonCyan, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'Historique',
                              style: GoogleFonts.fredoka(
                                color: AppColors.neonCyan,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _IsolatedGameClock(
            isWhite: isPlayerWhite,
            isPlayerWhite: isPlayerWhite,
            isReviewing: _isReviewing,
          ),
          MoveHistoryPanel(
            sanHistory: _sanHistory,
            reviewIndex: _reviewIndex,
            onMoveSelected: _navigateTo,
            onFirst: _navigateFirst,
            onPrevious: _navigatePrevious,
            onNext: _navigateNext,
            onLast: _navigateLast,
            onReturnToLive: _returnToLive,
          ),
          _buildActionBar(context, state),
        ],
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppColors.neonCyan),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _ActionIconButton(
            icon: Icons.menu,
            onPressed: () {},
          ),
          Expanded(
            child: Center(
              child: _GameTitle(),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Action bar ───────────────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context, GameActive state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.more_horiz,
            label: 'OPTIONS',
            onPressed: () => _showSettingsSheet(context, state),
          ),
          _ActionButton(
            icon: Icons.arrow_back_ios_new,
            label: 'RETOUR',
            onPressed: _navigatePrevious,
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, GameActive state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.neonCyan, width: 1),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.labelMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isReviewing
                    ? null
                    : () {
                        Navigator.pop(sheetCtx);
                        _confirmResign(context);
                      },
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Abandonner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isReviewing || state.hasOfferedDraw)
                    ? null
                    : () {
                        Navigator.pop(sheetCtx);
                        _confirmOfferDraw(context);
                      },
                icon: const Icon(Icons.handshake, size: 18),
                label: Text(
                    state.hasOfferedDraw ? 'Nulle proposée' : 'Proposer nulle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      state.hasOfferedDraw ? Colors.grey.shade700 : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmResign(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Abandonner'),
          content: const Text(
              'Voulez-vous vraiment abandonner ? Vous perdrez la partie.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(gameNotifierProvider.notifier).resign();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Abandonner'),
            ),
          ],
        );
      },
    );
  }

  void _confirmOfferDraw(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Proposer nulle'),
          content: const Text(
              'Voulez-vous proposer la nulle à votre adversaire ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(gameNotifierProvider.notifier).offerDraw();
              },
              child: const Text('Proposer'),
            ),
          ],
        );
      },
    );
  }

  void _showDrawOfferDialog(BuildContext context, String offeredByPlayerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.handshake, color: AppColors.neonCyan),
              SizedBox(width: 8),
              Text('Nulle proposée'),
            ],
          ),
          content: const Text(
              'Votre adversaire propose la nulle. Acceptez-vous ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(gameNotifierProvider.notifier).rejectDraw();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(gameNotifierProvider.notifier).acceptDraw();
              },
              child: const Text('Accepter'),
            ),
          ],
        );
      },
    );
  }

  // ── Game Ended ───────────────────────────────────────────────────────────────

  Widget _buildGameEndedView(
    BuildContext context,
    GameEnded state,
    bool isPlayerWhite,
  ) {
    String resultTitle;
    String resultDescription;
    IconData resultIcon;
    Color resultColor;

    final result = state.result.toUpperCase();

    if (result.contains('CHECKMATE')) {
      resultTitle = 'Échec et mat !';
      resultDescription = _getCheckmateDescription(state.game, widget.playerId);
      resultIcon = Icons.emoji_events;
      resultColor = AppColors.neonGold;
    } else if (result.contains('STALEMATE')) {
      resultTitle = 'Pat';
      resultDescription = 'La partie se termine par un pat.';
      resultIcon = Icons.handshake;
      resultColor = AppColors.neonCyan;
    } else if (result.contains('DRAW')) {
      resultTitle = 'Nulle';
      resultDescription = 'La partie se termine par une nulle.';
      resultIcon = Icons.handshake;
      resultColor = AppColors.neonCyan;
    } else if (result.contains('RESIGNED')) {
      final userWon = state.game.winner != null &&
          state.game.winner == widget.playerId;
      resultTitle = userWon ? 'Victoire !' : 'Abandon';
      resultDescription = userWon
          ? 'Votre adversaire a abandonné la partie.'
          : 'Vous avez abandonné la partie.';
      resultIcon = userWon ? Icons.emoji_events : Icons.flag;
      resultColor = userWon ? AppColors.neonGold : AppColors.clockDigitOpponent;
    } else if (result.contains('TIMEOUT')) {
      resultTitle = 'Temps écoulé';
      resultDescription = _getTimeoutDescription(state.game, widget.playerId);
      resultIcon = Icons.timer;
      resultColor = AppColors.clockDigitOpponent;
    } else {
      resultTitle = 'Fin de partie';
      resultDescription = 'Résultat : $result';
      resultIcon = Icons.info;
      resultColor = AppColors.labelMuted;
    }

    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _RoomBackgroundPainter())),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildGameClockEnded(state.game, !isPlayerWhite),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Opacity(
                          opacity: 0.3,
                          child: ChessBoard(
                            chess: _chess,
                            positionFen: state.game.positionFen,
                            isPlayerWhite: isPlayerWhite,
                            onMove: null,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.bgPanel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: resultColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: resultColor.withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(resultIcon, size: 56, color: resultColor),
                            const SizedBox(height: 12),
                            Text(
                              resultTitle,
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: resultColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              resultDescription,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.labelMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/lobby'),
                              icon: const Icon(Icons.home),
                              label: const Text('Retour au lobby'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildGameClockEnded(state.game, isPlayerWhite),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameClockEnded(dynamic game, bool isWhite) {
    final player = isWhite ? game.whitePlayer : game.blackPlayer;
    final timeMs =
        isWhite ? game.whiteTimeRemainingMs : game.blackTimeRemainingMs;

    return GameClock(
      timeRemainingMs: timeMs,
      isCurrentTurn: false,
      isWhite: isWhite,
      playerName: player.username,
      playerColor: isWhite ? 'White' : 'Black',
    );
  }

  String _getCheckmateDescription(dynamic game, String playerId) {
    final currentSide = game.currentSide;
    final playerWon =
        (currentSide == 'WHITE' && playerId == game.blackPlayer.playerId) ||
        (currentSide == 'BLACK' && playerId == game.whitePlayer.playerId);
    return playerWon
        ? 'Félicitations ! Vous avez gagné par échec et mat !'
        : 'Vous avez perdu par échec et mat.';
  }

  String _getTimeoutDescription(dynamic game, String playerId) {
    final currentSide = game.currentSide;
    final playerWon =
        (currentSide == 'WHITE' && playerId == game.blackPlayer.playerId) ||
        (currentSide == 'BLACK' && playerId == game.whitePlayer.playerId);
    return playerWon
        ? 'Votre adversaire est à court de temps. Vous gagnez !'
        : 'Vous êtes à court de temps. Vous perdez.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolated clock widget — se reconstruit uniquement sur changement de tour
// ─────────────────────────────────────────────────────────────────────────────

class _IsolatedGameClock extends ConsumerWidget {
  final bool isWhite;
  final bool isPlayerWhite;
  final bool isReviewing;

  const _IsolatedGameClock({
    required this.isWhite,
    required this.isPlayerWhite,
    required this.isReviewing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ne se reconstruit que sur changement de tour ou de nom de joueur
    final data = ref.watch(gameNotifierProvider.select((state) {
      if (state is! GameActive) return null;
      return _ClockShellData(
        currentSide: state.game.currentSide,
        whiteUsername: state.game.whitePlayer.username,
        blackUsername: state.game.blackPlayer.username,
      );
    }));

    if (data == null) return const SizedBox.shrink();

    final playerName =
        isWhite ? data.whiteUsername : data.blackUsername;
    final isWhiteTurn = data.currentSide == 'WHITE';
    final isCurrentTurn = (isWhite == isWhiteTurn) && !isReviewing;

    return GameClock(
      isCurrentTurn: isCurrentTurn,
      isWhite: isWhite,
      playerName: playerName,
      playerColor: isWhite ? 'White' : 'Black',
    );
  }
}

class _ClockShellData {
  final String currentSide;
  final String whiteUsername;
  final String blackUsername;

  const _ClockShellData({
    required this.currentSide,
    required this.whiteUsername,
    required this.blackUsername,
  });

  @override
  bool operator ==(Object other) =>
      other is _ClockShellData &&
      currentSide == other.currentSide &&
      whiteUsername == other.whiteUsername &&
      blackUsername == other.blackUsername;

  @override
  int get hashCode =>
      Object.hash(currentSide, whiteUsername, blackUsername);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _GameTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'g',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCyan,
            ),
          ),
          TextSpan(
            text: 'Chess',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.labelWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Icon(icon, color: AppColors.labelWhite, size: 22),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.actionBg,
            border: Border.all(
              color: active
                  ? AppColors.neonCyan
                  : AppColors.labelMuted.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: active ? AppColors.neonCyan : AppColors.labelMuted,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10,
            color: active ? AppColors.labelWhite : AppColors.labelMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
