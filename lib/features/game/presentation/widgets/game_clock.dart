import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_bloc.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';

/// Shell statique : avatar + player info + conteneur de l'horloge.
/// Ne se reconstruit que sur changement de tour ou de nom — jamais sur les ticks.
/// Le temps lui-même est rendu par [_ClockTimeDisplay] via BlocSelector.
class GameClock extends StatelessWidget {
  final bool isCurrentTurn;
  final bool isWhite;
  final String playerName;
  final String playerColor;

  /// Temps statique optionnel — utilisé uniquement pour la vue de fin de partie
  /// où il n'y a plus de BlocSelector actif.
  final int? timeRemainingMs;

  const GameClock({
    super.key,
    required this.isCurrentTurn,
    required this.isWhite,
    required this.playerName,
    required this.playerColor,
    this.timeRemainingMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.bgMid,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(child: _buildPlayerInfo()),
          _ClockTimeDisplay(
            isWhite: isWhite,
            isCurrentTurn: isCurrentTurn,
            staticTimeMs: timeRemainingMs,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    const double slotSize = 64; // taille fixe du slot — ne change jamais
    final double avatarSize = isCurrentTurn ? 58 : 50;
    final Color bgColor =
        isWhite ? const Color(0xFF2A3A50) : const Color(0xFF1A2535);

    return SizedBox(
      width: slotSize,
      height: slotSize,
      child: Center(
        child: Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: isCurrentTurn ? AppColors.neonCyan : AppColors.labelMuted,
              width: isCurrentTurn ? 2.5 : 1.5,
            ),
            boxShadow: isCurrentTurn
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.6),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
              style: GoogleFonts.fredoka(
                fontSize: isCurrentTurn ? 24 : 20,
                fontWeight: FontWeight.w600,
                color:
                    isCurrentTurn ? AppColors.neonCyan : AppColors.labelMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playerName.toUpperCase(),
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.playerName,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          isWhite ? 'JOUEUR BLANC' : 'JOUEUR NOIR',
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.playerTitle,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seul ce widget se reconstruit à chaque tick d'horloge.
// ─────────────────────────────────────────────────────────────────────────────

class _ClockTimeDisplay extends StatelessWidget {
  final bool isWhite;
  final bool isCurrentTurn;

  /// Fourni uniquement pour la vue fin de partie (pas de BlocSelector).
  final int? staticTimeMs;

  const _ClockTimeDisplay({
    required this.isWhite,
    required this.isCurrentTurn,
    this.staticTimeMs,
  });

  static String _formatTime(int ms) {
    if (ms <= 0) return '0:00';
    final totalSeconds = (ms / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static Color _clockColor(int ms, bool isCurrentTurn) {
    if (ms <= 10000) return AppColors.clockDigitOpponent;
    if (ms <= 60000) return const Color(0xFFFF8C00);
    return isCurrentTurn
        ? AppColors.clockDigitPlayer
        : AppColors.clockDigitOpponent;
  }

  Widget _buildBox(int timeMs) {
    final color = _clockColor(timeMs, isCurrentTurn);
    final timeStr = _formatTime(timeMs);
    final isPulsing = isCurrentTurn && timeMs > 0 && timeMs <= 5000;

    final box = SizedBox(
      width: 120,
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.clockBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                timeStr,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'TEMPS RESTANT',
            style: GoogleFonts.fredoka(
              fontSize: 9,
              color: AppColors.labelMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );

    if (isPulsing) {
      return TweenAnimationBuilder<double>(
        key: const ValueKey('pulse'),
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: 0.7 + value * 0.3, child: child),
        ),
        onEnd: () {},
        child: box,
      );
    }
    return box;
  }

  @override
  Widget build(BuildContext context) {
    // Fin de partie : temps statique, pas de BlocSelector
    if (staticTimeMs != null) {
      return _buildBox(staticTimeMs!);
    }

    // Partie active : seul ce BlocSelector se reconstruit chaque seconde
    return BlocSelector<GameBloc, GameState, int?>(
      selector: (state) => state is GameActive
          ? (isWhite ? state.whiteTimeRemainingMs : state.blackTimeRemainingMs)
          : null,
      builder: (context, timeMs) {
        if (timeMs == null) return const SizedBox.shrink();
        return _buildBox(timeMs);
      },
    );
  }
}
