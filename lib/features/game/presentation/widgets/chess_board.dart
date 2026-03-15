import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_square.dart';

class ChessBoard extends StatefulWidget {
  final chess_lib.Chess chess;
  final String positionFen;
  final bool isPlayerWhite;
  final Function(String from, String to, String? promotion)? onMove;
  final Function(String from, String to, String? promotion)? onPreMove;
  final String? lastMoveFrom;
  final String? lastMoveTo;

  const ChessBoard({
    super.key,
    required this.chess,
    required this.positionFen,
    required this.isPlayerWhite,
    this.onMove,
    this.onPreMove,
    this.lastMoveFrom,
    this.lastMoveTo,
  });

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  String? _selectedSquare;
  List<String> _legalMoves = [];
  String? _preMoveFrom;
  String? _preMoveTo;

  @override
  void didUpdateWidget(ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear pre-move selection when position changes
    if (oldWidget.positionFen != widget.positionFen) {
      _preMoveFrom = null;
      _preMoveTo = null;
      _legalMoves = [];
    }
    // Clear pre-move if pre-move callback was removed (e.g. review mode)
    if (widget.onPreMove == null) {
      _preMoveFrom = null;
      _preMoveTo = null;
      _legalMoves = [];
    }
  }

  static const TextStyle _coordStyle = TextStyle(
    color: AppColors.coordLabel,
    fontSize: 9,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final files = widget.isPlayerWhite
        ? ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
        : ['H', 'G', 'F', 'E', 'D', 'C', 'B', 'A'];
    final ranks = widget.isPlayerWhite
        ? ['8', '7', '6', '5', '4', '3', '2', '1']
        : ['1', '2', '3', '4', '5', '6', '7', '8'];

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.boardBorderDark,
              AppColors.boardBorderLight,
              AppColors.boardBorderDark,
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _buildFileLabelRow(files),
            Expanded(
              child: Row(
                children: [
                  _buildRankLabelColumn(ranks),
                  Expanded(child: _buildGrid()),
                  _buildRankLabelColumn(ranks),
                ],
              ),
            ),
            _buildFileLabelRow(files),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLabelRow(List<String> files) {
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          const SizedBox(width: 14),
          for (final f in files)
            Expanded(
              child: Center(child: Text(f, style: _coordStyle)),
            ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildRankLabelColumn(List<String> ranks) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          for (final r in ranks)
            Expanded(
              child: Center(child: Text(r, style: _coordStyle)),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final row = index ~/ 8;
        final col = index % 8;

        final displayRow = widget.isPlayerWhite ? row : 7 - row;
        final displayCol = widget.isPlayerWhite ? col : 7 - col;

        final square = _getSquareName(displayRow, displayCol);
        final piece = widget.chess.get(square);
        final isLightSquare = (displayRow + displayCol) % 2 == 0;

        final isSelected = _selectedSquare == square;
        final isInPreMoveSelection = _preMoveFrom != null && _preMoveTo == null;
        final isLegalMove = !isInPreMoveSelection && _legalMoves.contains(square);
        final isPreMoveLegal = isInPreMoveSelection && _legalMoves.contains(square);
        final isLastMoveFrom = widget.lastMoveFrom == square;
        final isLastMoveTo = widget.lastMoveTo == square;
        final isPreMoveFrom = _preMoveFrom == square;
        final isPreMoveTo = _preMoveTo == square;

        final isCheck = piece?.type == chess_lib.PieceType.KING &&
            piece?.color == widget.chess.turn &&
            widget.chess.in_check;

        return ChessSquare(
          row: displayRow,
          col: displayCol,
          piece: piece,
          isLightSquare: isLightSquare,
          isSelected: isSelected,
          isLegalMove: isLegalMove,
          isPreMoveLegal: isPreMoveLegal,
          isLastMoveFrom: isLastMoveFrom,
          isLastMoveTo: isLastMoveTo,
          isCheck: isCheck,
          isPreMoveFrom: isPreMoveFrom,
          isPreMoveTo: isPreMoveTo,
          onTap: () => _onSquareTapped(square),
        );
      },
    );
  }

  String _getSquareName(int row, int col) {
    const files = 'abcdefgh';
    final rank = 8 - row;
    final file = files[col];
    return '$file$rank';
  }

  void _onSquareTapped(String square) {
    final playerColor =
        widget.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    final isPlayerTurn = widget.chess.turn == playerColor;

    if (!isPlayerTurn) {
      _onSquareTappedPreMove(square, playerColor);
      return;
    }

    if (_selectedSquare == null) {
      final piece = widget.chess.get(square);
      if (piece != null && piece.color == playerColor) {
        setState(() {
          _selectedSquare = square;
          _legalMoves = _getLegalMovesForSquare(square);
        });
      }
    } else {
      if (_legalMoves.contains(square)) {
        _makeMove(_selectedSquare!, square);
      } else {
        final piece = widget.chess.get(square);
        if (piece != null && piece.color == playerColor) {
          setState(() {
            _selectedSquare = square;
            _legalMoves = _getLegalMovesForSquare(square);
          });
        } else {
          setState(() {
            _selectedSquare = null;
            _legalMoves = [];
          });
        }
      }
    }
  }

  void _onSquareTappedPreMove(String square, chess_lib.Color playerColor) {
    if (widget.onPreMove == null) return;

    if (_preMoveFrom == null) {
      // Select source: must be player's own piece
      final piece = widget.chess.get(square);
      if (piece != null && piece.color == playerColor) {
        setState(() {
          _preMoveFrom = square;
          _preMoveTo = null;
          _legalMoves = _getPreMoveLegalMovesForSquare(square);
        });
      }
    } else {
      if (square == _preMoveFrom) {
        // Deselect
        setState(() {
          _preMoveFrom = null;
          _preMoveTo = null;
          _legalMoves = [];
        });
      } else {
        final piece = widget.chess.get(square);
        if (piece != null && piece.color == playerColor) {
          // Switch source to another own piece
          setState(() {
            _preMoveFrom = square;
            _preMoveTo = null;
            _legalMoves = _getPreMoveLegalMovesForSquare(square);
          });
        } else if (_legalMoves.contains(square)) {
          // Valid pre-move destination
          _executePreMove(_preMoveFrom!, square);
        } else {
          // Tapped an empty/opponent square outside legal destinations — cancel
          setState(() {
            _preMoveFrom = null;
            _preMoveTo = null;
            _legalMoves = [];
          });
        }
      }
    }
  }

  List<String> _getLegalMovesForSquare(String square) {
    final moves = widget.chess.moves({'square': square, 'verbose': true});
    return moves.map((move) => move['to'] as String).toList();
  }

  // Compute legal moves for a square as if it were the player's turn,
  // by loading the same position with the turn flipped.
  List<String> _getPreMoveLegalMovesForSquare(String square) {
    final parts = widget.chess.fen.split(' ');
    parts[1] = widget.isPlayerWhite ? 'w' : 'b';
    final flippedChess = chess_lib.Chess();
    flippedChess.load(parts.join(' '));
    final moves = flippedChess.moves({'square': square, 'verbose': true});
    return moves.map((move) => move['to'] as String).toList();
  }

  void _makeMove(String from, String to) {
    final piece = widget.chess.get(from);
    final isPromotion = piece != null &&
        piece.type == chess_lib.PieceType.PAWN &&
        ((piece.color == chess_lib.Color.WHITE && to[1] == '8') ||
            (piece.color == chess_lib.Color.BLACK && to[1] == '1'));

    if (isPromotion) {
      _showPromotionDialog(from, to);
    } else {
      _executMove(from, to, null);
    }
  }

  void _showPromotionDialog(String from, String to) {
    final colorPrefix = widget.isPlayerWhite ? 'w' : 'b';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Promote Pawn'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionOption(
                  context, 'QUEEN', 'Q', from, to, colorPrefix),
              _buildPromotionOption(context, 'ROOK', 'R', from, to, colorPrefix),
              _buildPromotionOption(
                  context, 'BISHOP', 'B', from, to, colorPrefix),
              _buildPromotionOption(
                  context, 'KNIGHT', 'N', from, to, colorPrefix),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionOption(
    BuildContext context,
    String promotionType,
    String pieceType,
    String from,
    String to,
    String colorPrefix,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _executMove(from, to, promotionType);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          'assets/pieces/$colorPrefix$pieceType.svg',
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _executMove(String from, String to, String? promotion) {
    setState(() {
      _selectedSquare = null;
      _legalMoves = [];
    });
    widget.onMove?.call(from, to, promotion);
  }

  void _executePreMove(String from, String to) {
    final piece = widget.chess.get(from);
    final isPromotion = piece != null &&
        piece.type == chess_lib.PieceType.PAWN &&
        ((piece.color == chess_lib.Color.WHITE && to[1] == '8') ||
            (piece.color == chess_lib.Color.BLACK && to[1] == '1'));

    setState(() {
      _preMoveFrom = from;
      _preMoveTo = to;
      _legalMoves = [];
    });
    // Auto-promote to queen for pre-moves
    widget.onPreMove?.call(from, to, isPromotion ? 'QUEEN' : null);
  }
}
