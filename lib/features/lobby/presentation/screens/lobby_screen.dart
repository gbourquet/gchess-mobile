import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/routes.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/lobby/presentation/widgets/custom_game_dialog.dart';
import 'package:gchess_mobile/features/lobby/presentation/widgets/time_control_preset_button.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // Subtle gradient background
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
                _buildHeader(context, ref),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildSectionHeader(context, '⚡ Bullet'),
                        const SizedBox(height: 10),
                        _buildBulletPresets(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, '🔥 Blitz'),
                        const SizedBox(height: 10),
                        _buildBlitzPresets(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, '⏱ Rapide'),
                        const SizedBox(height: 10),
                        _buildRapidPresets(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, '♟ Classique'),
                        const SizedBox(height: 10),
                        _buildClassicalPresets(context),
                        const SizedBox(height: 24),
                        _buildCustomGameButton(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'g',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonCyan,
                  ),
                ),
                TextSpan(
                  text: 'Chess',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.labelWhite,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.labelMuted),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.labelWhite,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBulletPresets(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        TimeControlPresetButton(
          timeControl: '1+0',
          label: 'Bullet',
          onTap: () => _navigateToMatchmaking(context, 1, 0),
        ),
        TimeControlPresetButton(
          timeControl: '2+0',
          label: 'Bullet',
          onTap: () => _navigateToMatchmaking(context, 2, 0),
        ),
        TimeControlPresetButton(
          timeControl: '2+1',
          label: 'Bullet',
          onTap: () => _navigateToMatchmaking(context, 2, 1),
        ),
      ],
    );
  }

  Widget _buildBlitzPresets(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        TimeControlPresetButton(
          timeControl: '3+0',
          label: 'Blitz',
          onTap: () => _navigateToMatchmaking(context, 3, 0),
        ),
        TimeControlPresetButton(
          timeControl: '3+2',
          label: 'Blitz',
          onTap: () => _navigateToMatchmaking(context, 3, 2),
        ),
        TimeControlPresetButton(
          timeControl: '5+0',
          label: 'Blitz',
          onTap: () => _navigateToMatchmaking(context, 5, 0),
        ),
        TimeControlPresetButton(
          timeControl: '5+3',
          label: 'Blitz',
          onTap: () => _navigateToMatchmaking(context, 5, 3),
        ),
      ],
    );
  }

  Widget _buildRapidPresets(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        TimeControlPresetButton(
          timeControl: '10+0',
          label: 'Rapide',
          onTap: () => _navigateToMatchmaking(context, 10, 0),
        ),
        TimeControlPresetButton(
          timeControl: '10+5',
          label: 'Rapide',
          onTap: () => _navigateToMatchmaking(context, 10, 5),
        ),
        TimeControlPresetButton(
          timeControl: '15+10',
          label: 'Rapide',
          onTap: () => _navigateToMatchmaking(context, 15, 10),
        ),
      ],
    );
  }

  Widget _buildClassicalPresets(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        TimeControlPresetButton(
          timeControl: '30+0',
          label: 'Classique',
          onTap: () => _navigateToMatchmaking(context, 30, 0),
        ),
        TimeControlPresetButton(
          timeControl: '30+20',
          label: 'Classique',
          onTap: () => _navigateToMatchmaking(context, 30, 20),
        ),
      ],
    );
  }

  Widget _buildCustomGameButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showCustomGameDialog(context),
      icon: const Icon(Icons.tune),
      label: const Text('Partie personnalisée'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _navigateToMatchmaking(
    BuildContext context,
    int totalTimeMinutes,
    int incrementSeconds,
  ) {
    final request = MatchRequest(
      totalTimeMinutes: totalTimeMinutes,
      incrementSeconds: incrementSeconds,
    );
    context.push(AppRoutes.matchmaking, extra: request);
  }

  void _showCustomGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomGameDialog(
        onStartGame: (time, increment) {
          _navigateToMatchmaking(context, time, increment);
        },
      ),
    );
  }
}
