import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/app_config.dart';
import 'package:gchess_mobile/config/routes.dart';
import 'package:gchess_mobile/config/theme.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/core/network/api_client.dart';
import 'package:gchess_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gchess_mobile/features/auth/presentation/bloc/auth_event.dart';

/// Wraps the app with a two-finger tap detector that opens the debug menu.
/// Only active in debug builds (kDebugMode).
class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  int _activePointers = 0;
  bool _menuShown = false;
  OverlayEntry? _overlayEntry;

  void _onPointerDown(PointerDownEvent _) {
    _activePointers++;
    if (_activePointers >= 2 && !_menuShown) {
      _menuShown = true;
      _showDebugMenu();
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  void _showDebugMenu() {
    final navContext = AppRouter.navigatorKey.currentContext;
    if (navContext == null) {
      _menuShown = false;
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) => _DebugMenuOverlay(
        onDismiss: _hideDebugMenu,
        onEnvChanged: () {
          _hideDebugMenu();
          navContext.read<AuthBloc>().add(const LogoutRequested());
        },
      ),
    );

    // Access the overlay directly from the navigator state
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      _menuShown = false;
      return;
    }
    overlayState.insert(_overlayEntry!);
  }

  void _hideDebugMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _menuShown = false;
    _activePointers = 0;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay widget — backdrop + bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DebugMenuOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onEnvChanged;

  const _DebugMenuOverlay({required this.onDismiss, required this.onEnvChanged});

  @override
  State<_DebugMenuOverlay> createState() => _DebugMenuOverlayState();
}

class _DebugMenuOverlayState extends State<_DebugMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnim;
  late Environment _selected;

  @override
  void initState() {
    super.initState();
    _selected = AppConfig.environment;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  void _applyEnv(Environment env) {
    if (env == _selected) return;
    AppConfig.setEnvironment(env);
    getIt<ApiClient>().updateBaseUrl(AppConfig.baseUrl);
    _controller.reverse().then((_) => widget.onEnvChanged());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent backdrop
        GestureDetector(
          onTap: _dismiss,
          child: FadeTransition(
            opacity: _slideAnim,
            child: Container(color: Colors.black54),
          ),
        ),
        // Bottom sheet sliding up
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: Material(
              color: const Color(0xFF0D1F30),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(color: AppColors.neonCyan, width: 1),
                    left: BorderSide(color: AppColors.neonCyan, width: 1),
                    right: BorderSide(color: AppColors.neonCyan, width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.labelMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.bug_report,
                            color: AppColors.neonCyan, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'DEBUG — Environnement backend',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.baseUrl,
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: AppColors.labelMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _EnvTile(
                      label: 'Local (émulateur)',
                      subtitle: 'http://10.0.2.2:8080',
                      env: Environment.development,
                      selected: _selected,
                      onTap: () => _applyEnv(Environment.development),
                    ),
                    const SizedBox(height: 10),
                    _EnvTile(
                      label: 'Dev (Railway)',
                      subtitle: 'shimmering-spirit-production.up.railway.app',
                      env: Environment.production,
                      selected: _selected,
                      onTap: () => _applyEnv(Environment.production),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EnvTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Environment env;
  final Environment selected;
  final VoidCallback onTap;

  const _EnvTile({
    required this.label,
    required this.subtitle,
    required this.env,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = env == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.neonCyan.withValues(alpha: 0.1)
              : AppColors.bgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.neonCyan
                : AppColors.labelMuted.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isActive ? AppColors.neonCyan : AppColors.labelMuted,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isActive ? AppColors.neonCyan : AppColors.labelWhite,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: AppColors.labelMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.neonCyan, width: 1),
                ),
                child: Text(
                  'ACTIF',
                  style: GoogleFonts.orbitron(
                    fontSize: 8,
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
