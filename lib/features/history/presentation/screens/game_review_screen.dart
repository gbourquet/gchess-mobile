import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_board.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/move_history_panel.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

class GameReviewScreen extends StatefulWidget {
  final GameRecord record;

  const GameReviewScreen({super.key, required this.record});

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  final chess_lib.Chess _chess = chess_lib.Chess();
  // -1 = position initiale (avant le premier coup)
  int _reviewIndex = -1;

  static const _initialFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  GameRecord get _record => widget.record;

  // Computed clock times per position: index 0 = before any move, index k = after move k
  List<(int white, int black)>? _clockStates;

  @override
  void initState() {
    super.initState();
    _computeClocks();
  }

  void _computeClocks() {
    final total = _record.totalTimeSeconds;
    final increment = _record.incrementSeconds ?? 0;
    final times = _record.moveTimes;
    if (total == null || total == 0 || times == null || times.isEmpty) return;

    final startMs = total * 1000;
    final incrementMs = increment * 1000;

    var whiteMs = startMs;
    var blackMs = startMs;
    final states = <(int, int)>[(whiteMs, blackMs)];

    for (int i = 0; i < times.length; i++) {
      final spent = times[i] ?? 0;
      if (i.isEven) {
        whiteMs = (whiteMs - spent + incrementMs).clamp(0, startMs);
      } else {
        blackMs = (blackMs - spent + incrementMs).clamp(0, startMs);
      }
      states.add((whiteMs, blackMs));
    }
    _clockStates = states;
  }

  String get _currentFen {
    if (_reviewIndex < 0) return _initialFen;
    if (_reviewIndex >= _record.fenHistory.length) return _record.finalFen;
    return _record.fenHistory[_reviewIndex];
  }

  String? get _lastMoveFrom {
    if (_reviewIndex < 0 || _reviewIndex >= _record.uciHistory.length) {
      return null;
    }
    final parts = _record.uciHistory[_reviewIndex].split('-');
    return parts.isNotEmpty ? parts[0] : null;
  }

  String? get _lastMoveTo {
    if (_reviewIndex < 0 || _reviewIndex >= _record.uciHistory.length) {
      return null;
    }
    final parts = _record.uciHistory[_reviewIndex].split('-');
    return parts.length >= 2 ? parts[1] : null;
  }

  // Clock at current position.
  // When full clock states are computed (moveTimes available): accurate per-move values.
  // When only start/end times are known: show start time at initial, end time at final.
  (int white, int black)? get _currentClock {
    // Case 1: full per-move data available
    final states = _clockStates;
    if (states != null) {
      final idx = _reviewIndex + 1; // 0 = initial, k = after move k-1
      if (idx >= 0 && idx < states.length) return states[idx];
      return null;
    }

    // Case 2: no per-move data — show start / end times only
    final total = _record.totalTimeSeconds;
    final wFinal = _record.whiteTimeRemainingMs;
    final bFinal = _record.blackTimeRemainingMs;

    if (_reviewIndex < 0 && total != null && total > 0) {
      // Initial position: both at full starting time
      final startMs = total * 1000;
      return (startMs, startMs);
    }
    final isAtEnd = _reviewIndex >= _record.fenHistory.length - 1;
    if (isAtEnd && wFinal != null && bFinal != null) {
      // Final position: show actual remaining times
      return (wFinal, bFinal);
    }

    // Intermediate positions without per-move data: no clock
    return null;
  }

  void _navigateTo(int index) {
    if (index < -1 || index >= _record.fenHistory.length) return;
    setState(() => _reviewIndex = index);
  }

  void _navigateFirst() => setState(() => _reviewIndex = -1);

  void _navigateLast() =>
      setState(() => _reviewIndex = _record.fenHistory.length - 1);

  void _navigatePrevious() {
    if (_reviewIndex > -1) setState(() => _reviewIndex--);
  }

  void _navigateNext() {
    if (_reviewIndex < _record.fenHistory.length - 1) {
      setState(() => _reviewIndex++);
    }
  }

  String _resultLabel() {
    final r = _record.result.toUpperCase();
    if (r.contains('CHECKMATE')) return 'Échec et mat';
    if (r.contains('STALEMATE')) return 'Pat';
    if (r.contains('DRAW')) return 'Nulle';
    if (r.contains('RESIGNED')) return 'Abandon';
    if (r.contains('TIMEOUT')) return 'Temps écoulé';
    return _record.result;
  }

  String _outcomeLabel() {
    if (_record.winner == null) return '½ - ½';
    if (_record.winner == _record.playerId) return 'Victoire';
    return 'Défaite';
  }

  Color _outcomeColor() {
    if (_record.winner == null) return AppColors.neonCyan;
    if (_record.winner == _record.playerId) return AppColors.neonGold;
    return AppColors.clockDigitOpponent;
  }

  String _timeControlLabel() {
    if (_record.totalTimeSeconds == null) return '';
    final mins = _record.totalTimeSeconds! ~/ 60;
    final inc = _record.incrementSeconds ?? 0;
    return inc > 0 ? '$mins+$inc' : '${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    _chess.load(_currentFen);

    final clock = _currentClock;
    // Determine whose clock goes where based on orientation
    final int? topClockMs;
    final int? bottomClockMs;
    final String topLabel;
    final String bottomLabel;
    final bool topIsWhite;

    if (_record.isPlayerWhite) {
      // Player is white: black is on top, white is on bottom
      topClockMs = clock?.$2;
      bottomClockMs = clock?.$1;
      topLabel = _record.blackUsername;
      bottomLabel = _record.whiteUsername;
      topIsWhite = false;
    } else {
      // Player is black: white is on top, black is on bottom
      topClockMs = clock?.$1;
      bottomClockMs = clock?.$2;
      topLabel = _record.whiteUsername;
      bottomLabel = _record.blackUsername;
      topIsWhite = true;
    }

    // Whether there is any time data to show clocks at all
    final hasTotalTime = _record.totalTimeSeconds != null &&
        _record.totalTimeSeconds! > 0;
    final hasFinalTimes = _record.whiteTimeRemainingMs != null &&
        _record.blackTimeRemainingMs != null;
    final showClocks = hasTotalTime || hasFinalTimes;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF08131F), Color(0xFF0B1E30)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildGameInfo(),
                if (showClocks)
                  _ReviewClock(
                    username: topLabel,
                    timeMs: topClockMs,
                    isWhite: topIsWhite,
                    isTop: true,
                  ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ChessBoard(
                        chess: _chess,
                        positionFen: _currentFen,
                        isPlayerWhite: _record.isPlayerWhite,
                        onMove: null,
                        lastMoveFrom: _lastMoveFrom,
                        lastMoveTo: _lastMoveTo,
                      ),
                    ),
                  ),
                ),
                if (showClocks)
                  _ReviewClock(
                    username: bottomLabel,
                    timeMs: bottomClockMs,
                    isWhite: !topIsWhite,
                    isTop: false,
                  ),
                MoveHistoryPanel(
                  sanHistory: _record.sanHistory,
                  reviewIndex: _reviewIndex,
                  onMoveSelected: _navigateTo,
                  onFirst: _navigateFirst,
                  onPrevious: _navigatePrevious,
                  onNext: _navigateNext,
                  onLast: _navigateLast,
                  onReturnToLive: _navigateLast,
                  moveTimes: _record.moveTimes,
                  isGameMode: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.labelMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Analyse de partie',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.labelWhite,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    final tc = _timeControlLabel();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_record.whiteUsername} vs ${_record.blackUsername}',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: AppColors.labelWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _resultLabel(),
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    color: AppColors.labelMuted,
                  ),
                ),
              ],
            ),
          ),
          if (tc.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3)),
              ),
              child: Text(
                tc,
                style: GoogleFonts.fredoka(
                    fontSize: 13, color: AppColors.neonCyan),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _outcomeColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: _outcomeColor().withValues(alpha: 0.5)),
            ),
            child: Text(
              _outcomeLabel(),
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _outcomeColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewClock extends StatelessWidget {
  final String username;
  final int? timeMs;
  final bool isWhite;
  final bool isTop;

  const _ReviewClock({
    required this.username,
    required this.timeMs,
    required this.isWhite,
    required this.isTop,
  });

  String _format(int ms) {
    final totalSeconds = ms ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pieceColor =
        isWhite ? const Color(0xFFE8D5A3) : const Color(0xFF527A52);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              username,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                color: AppColors.labelWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (timeMs != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: pieceColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                _format(timeMs!),
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: pieceColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
