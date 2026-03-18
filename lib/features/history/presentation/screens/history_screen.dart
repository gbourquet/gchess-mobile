import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';
import 'package:gchess_mobile/features/history/presentation/providers/game_history_provider.dart';
import 'package:gchess_mobile/features/history/presentation/screens/game_review_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(gameHistoryNotifierProvider);

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
                Expanded(
                  child: records.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: records.length,
                          itemBuilder: (context, index) =>
                              _GameRecordTile(record: records[index]),
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              'Historique',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.labelWhite,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history,
              size: 64,
              color: AppColors.labelMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Aucune partie enregistrée',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: AppColors.labelMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos parties terminées apparaîtront ici.',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: AppColors.labelMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameRecordTile extends StatelessWidget {
  final GameRecord record;

  const _GameRecordTile({required this.record});

  String _resultLabel() {
    final r = record.result.toUpperCase();
    if (r.contains('CHECKMATE')) return 'Échec et mat';
    if (r.contains('STALEMATE')) return 'Pat';
    if (r.contains('DRAW')) return 'Nulle';
    if (r.contains('RESIGNED')) return 'Abandon';
    if (r.contains('TIMEOUT')) return 'Temps écoulé';
    return record.result;
  }

  String _outcomeLabel() {
    if (record.winner == null) return '½-½';
    if (record.winner == record.playerId) return 'Victoire';
    return 'Défaite';
  }

  Color _outcomeColor() {
    if (record.winner == null) return AppColors.neonCyan;
    if (record.winner == record.playerId) return AppColors.neonGold;
    return AppColors.clockDigitOpponent;
  }

  String _timeControlLabel() {
    if (record.totalTimeSeconds == null) return '';
    final mins = record.totalTimeSeconds! ~/ 60;
    final inc = record.incrementSeconds ?? 0;
    return inc > 0 ? '$mins+$inc' : '${mins}min';
  }

  String _dateLabel() {
    final d = record.playedAt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _moveCountLabel() {
    final count = (record.sanHistory.length / 2).ceil();
    return '$count coup${count > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final outcomeColor = _outcomeColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameReviewScreen(record: record),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Indicateur de couleur jouée
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: record.isPlayerWhite
                      ? const Color(0xFFE8D5A3)
                      : const Color(0xFF527A52),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${record.opponentUsername}',
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _resultLabel(),
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: AppColors.labelMuted,
                          ),
                        ),
                        if (_timeControlLabel().isNotEmpty) ...[
                          Text(
                            '  ·  ',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: AppColors.labelMuted,
                            ),
                          ),
                          Text(
                            _timeControlLabel(),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: AppColors.labelMuted,
                            ),
                          ),
                        ],
                        Text(
                          '  ·  ${_moveCountLabel()}',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: AppColors.labelMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: outcomeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: outcomeColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _outcomeLabel(),
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: outcomeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dateLabel(),
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      color: AppColors.labelMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: AppColors.labelMuted.withValues(alpha: 0.5),
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
