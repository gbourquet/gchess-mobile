import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_piece.dart';

class ChessSquare extends StatelessWidget {
  final int row;
  final int col;
  final chess_lib.Piece? piece;
  final bool isLightSquare;
  final bool isSelected;
  final bool isLegalMove;
  final bool isLastMoveFrom;
  final bool isLastMoveTo;
  final bool isCheck;
  final bool isPreMoveFrom;
  final bool isPreMoveTo;
  final bool isPreMoveLegal;
  final VoidCallback? onTap;

  const ChessSquare({
    super.key,
    required this.row,
    required this.col,
    this.piece,
    required this.isLightSquare,
    this.isSelected = false,
    this.isLegalMove = false,
    this.isPreMoveLegal = false,
    this.isLastMoveFrom = false,
    this.isLastMoveTo = false,
    this.isCheck = false,
    this.isPreMoveFrom = false,
    this.isPreMoveTo = false,
    this.onTap,
  });

  Color _getBaseColor() {
    if (isCheck) return AppColors.checkSquare;
    if (isSelected) return AppColors.selectedSquare;
    if (isPreMoveFrom || isPreMoveTo) return AppColors.preMoveSquare;
    if (isLastMoveFrom || isLastMoveTo) {
      return isLightSquare
          ? AppColors.lightSquare.withValues(alpha: 0.6)
          : AppColors.darkSquare.withValues(alpha: 0.6);
    }
    return isLightSquare ? AppColors.lightSquare : AppColors.darkSquare;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: _getBaseColor(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Last move tint overlay
            if (isLastMoveFrom || isLastMoveTo)
              Container(color: AppColors.lastMoveHighlight),

            // Piece
            if (piece != null)
              Center(child: ChessPiece(piece: piece!)),

            // Legal move: empty square — dot
            if (isLegalMove && piece == null)
              Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.legalMoveEmpty,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.legalMoveEmpty,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // Legal move: capture — ring
            if (isLegalMove && piece != null)
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.legalMoveCapture,
                      width: 3,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Pre-move legal: empty square — orange dot
            if (isPreMoveLegal && piece == null)
              Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.preMoveSquare,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.preMoveSquare,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // Pre-move legal: capture — orange ring
            if (isPreMoveLegal && piece != null)
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.preMoveSquare,
                      width: 3,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
