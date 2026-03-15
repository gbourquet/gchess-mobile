import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/routes.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/providers/matchmaking_provider.dart';

class MatchmakingQueueScreen extends StatelessWidget {
  final MatchRequest request;

  const MatchmakingQueueScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return MatchmakingQueueView(request: request);
  }
}

class MatchmakingQueueView extends ConsumerStatefulWidget {
  final MatchRequest request;

  const MatchmakingQueueView({super.key, required this.request});

  @override
  ConsumerState<MatchmakingQueueView> createState() =>
      _MatchmakingQueueViewState();
}

class _MatchmakingQueueViewState extends ConsumerState<MatchmakingQueueView> {
  bool _hasJoinedQueue = false;

  String get _timeControlDisplay {
    if (widget.request.totalTimeMinutes == null ||
        widget.request.totalTimeMinutes == 0) {
      return 'Illimité';
    }
    final time = widget.request.totalTimeMinutes!;
    final inc = widget.request.incrementSeconds ?? 0;
    return '$time+$inc';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(matchmakingNotifierProvider.notifier).connect();
      }
    });
  }

  void _handleCancel() {
    context.pop(); // ref.onDispose gère la déconnexion
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(matchmakingNotifierProvider, (previous, next) {
      if (next is MatchmakingIdle && !_hasJoinedQueue) {
        _hasJoinedQueue = true;
        ref
            .read(matchmakingNotifierProvider.notifier)
            .joinQueue(widget.request);
      } else if (next is MatchFound) {
        context.go(
          AppRoutes.gameWithId(
            next.matchResult.gameId,
            next.matchResult.playerId,
          ),
        );
      } else if (next is MatchmakingError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () {
                _hasJoinedQueue = false;
                ref.read(matchmakingNotifierProvider.notifier).connect();
              },
            ),
          ),
        );
      }
    });

    final state = ref.watch(matchmakingNotifierProvider);

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
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: AppColors.labelMuted),
                        onPressed: _handleCancel,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Recherche $_timeControlDisplay',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.labelWhite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is MatchmakingConnecting)
                          _buildConnectingView()
                        else if (state is InQueue)
                          _buildQueueView(state.position)
                        else if (state is MatchmakingError)
                          _buildErrorView(state.message)
                        else
                          _buildConnectingView(),
                        const SizedBox(height: 48),
                        OutlinedButton.icon(
                          onPressed: _handleCancel,
                          icon: const Icon(Icons.close),
                          label: const Text('Annuler'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
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

  Widget _buildConnectingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: AppColors.neonCyan,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Connexion au matchmaking...',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            color: AppColors.labelWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueView(int position) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Column(
        key: ValueKey<int>(position),
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  value: null,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                  backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgCard,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 28, color: AppColors.neonCyan),
                    const SizedBox(height: 2),
                    Text(
                      '#$position',
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'En attente... ($_timeControlDisplay)',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: AppColors.labelWhite,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              position == 1
                  ? 'Vous êtes le prochain ! Une partie démarrera dès qu\'un autre joueur rejoindra.'
                  : 'Vous serez associé au prochain joueur disponible.',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: AppColors.labelMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _buildWaitingDots(),
        ],
      ),
    );
  }

  Widget _buildWaitingDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final opacity = ((value + i * 0.3) % 1.0).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.neonCyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildErrorView(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Erreur de connexion',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.labelWhite,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: AppColors.labelMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
