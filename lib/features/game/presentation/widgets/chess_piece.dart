import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessPiece extends StatelessWidget {
  final chess_lib.Piece piece;
  final double size;

  const ChessPiece({
    super.key,
    required this.piece,
    this.size = 48,
  });

  String _getPieceAssetPath() {
    final colorPrefix = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final pieceType = switch (piece.type) {
      chess_lib.PieceType.KING => 'K',
      chess_lib.PieceType.QUEEN => 'Q',
      chess_lib.PieceType.ROOK => 'R',
      chess_lib.PieceType.BISHOP => 'B',
      chess_lib.PieceType.KNIGHT => 'N',
      chess_lib.PieceType.PAWN => 'P',
      _ => '',
    };

    return 'assets/pieces/$colorPrefix$pieceType.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _getPieceAssetPath(),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
