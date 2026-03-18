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
  // -1 = position finale
  int _reviewIndex = -1;

  GameRecord get _record => widget.record;

  String get _currentFen {
    if (_reviewIndex < 0 || _record.fenHistory.isEmpty) {
      return _record.finalFen;
    }
    return _record.fenHistory[_reviewIndex];
  }

  String? get _lastMoveFrom {
    final idx = _reviewIndex < 0 ? _record.uciHistory.length - 1 : _reviewIndex;
    if (idx < 0 || idx >= _record.uciHistory.length) return null;
    final parts = _record.uciHistory[idx].split('-');
    return parts.isNotEmpty ? parts[0] : null;
  }

  String? get _lastMoveTo {
    final idx = _reviewIndex < 0 ? _record.uciHistory.length - 1 : _reviewIndex;
    if (idx < 0 || idx >= _record.uciHistory.length) return null;
    final parts = _record.uciHistory[idx].split('-');
    return parts.length >= 2 ? parts[1] : null;
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= _record.fenHistory.length) return;
    setState(() => _reviewIndex = index);
  }

  void _navigateFirst() {
    if (_record.fenHistory.isNotEmpty) _navigateTo(0);
  }

  void _navigateLast() => setState(() => _reviewIndex = -1);

  void _navigatePrevious() {
    if (_reviewIndex == -1) {
      if (_record.fenHistory.isNotEmpty) {
        _navigateTo(_record.fenHistory.length - 1);
      }
    } else if (_reviewIndex > 0) {
      _navigateTo(_reviewIndex - 1);
    }
  }

  void _navigateNext() {
    if (_reviewIndex == -1) return;
    if (_reviewIndex < _record.fenHistory.length - 1) {
      _navigateTo(_reviewIndex + 1);
    } else {
      _navigateLast();
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

  int get _panelReviewIndex =>
      _reviewIndex >= 0 ? _reviewIndex : _record.sanHistory.length - 1;

  @override
  Widget build(BuildContext context) {
    _chess.load(_currentFen);

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
                MoveHistoryPanel(
                  sanHistory: _record.sanHistory,
                  reviewIndex: _panelReviewIndex,
                  onMoveSelected: _navigateTo,
                  onFirst: _navigateFirst,
                  onPrevious: _navigatePrevious,
                  onNext: _navigateNext,
                  onLast: _navigateLast,
                  onReturnToLive: _navigateLast,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _outcomeColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _outcomeColor().withValues(alpha: 0.5)),
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
