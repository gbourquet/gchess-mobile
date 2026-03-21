import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';

class MoveHistoryPanel extends StatefulWidget {
  final List<String> sanHistory;
  final int reviewIndex; // live game: -1=live ; review: -1=initial position
  final Function(int index) onMoveSelected;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;
  final VoidCallback onReturnToLive;
  // Optional: time spent per move in ms (null = not available)
  final List<int?>? moveTimes;
  // false in review mode: -1 means "initial position", no LIVE concept
  final bool isGameMode;

  const MoveHistoryPanel({
    super.key,
    required this.sanHistory,
    required this.reviewIndex,
    required this.onMoveSelected,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    required this.onReturnToLive,
    this.moveTimes,
    this.isGameMode = true,
  });

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  final ScrollController _scrollController = ScrollController();

  // In game mode: -1 = live (latest move highlighted)
  // In review mode: -1 = initial position (no move highlighted)
  bool get _isLive => widget.isGameMode && widget.reviewIndex == -1;

  int get _activeIndex {
    if (_isLive) return widget.sanHistory.length - 1;
    return widget.reviewIndex; // -1 means no active move in review mode
  }

  @override
  void didUpdateWidget(MoveHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reviewIndex != widget.reviewIndex ||
        oldWidget.sanHistory.length != widget.sanHistory.length) {
      _autoScroll();
    }
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sanHistory.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 58,
            child: total == 0
                ? Center(
                    child: Text(
                      'Aucun coup joué',
                      style: GoogleFonts.fredoka(
                        color: AppColors.labelMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: _buildMoveItems(),
                    ),
                  ),
          ),
          Divider(
            height: 1,
            color: AppColors.neonCyan.withValues(alpha: 0.12),
          ),
          _buildNavBar(total),
        ],
      ),
    );
  }

  List<Widget> _buildMoveItems() {
    final items = <Widget>[];
    final pairCount = (widget.sanHistory.length / 2).ceil();

    for (int pair = 0; pair < pairCount; pair++) {
      final wi = pair * 2;
      final bi = wi + 1;
      final hasBlack = bi < widget.sanHistory.length;

      items.add(_MovePair(
        moveNumber: pair + 1,
        whiteSan: widget.sanHistory[wi],
        blackSan: hasBlack ? widget.sanHistory[bi] : null,
        isWhiteActive: _activeIndex == wi,
        isBlackActive: hasBlack && _activeIndex == bi,
        onWhiteTap: () => widget.onMoveSelected(wi),
        onBlackTap: hasBlack ? () => widget.onMoveSelected(bi) : null,
        whiteTimeMs: widget.moveTimes != null && wi < widget.moveTimes!.length
            ? widget.moveTimes![wi]
            : null,
        blackTimeMs: hasBlack &&
                widget.moveTimes != null &&
                bi < widget.moveTimes!.length
            ? widget.moveTimes![bi]
            : null,
      ));
    }
    return items;
  }

  Widget _buildNavBar(int total) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          _NavBtn(icon: Icons.first_page_rounded, onTap: widget.onFirst),
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: widget.onPrevious),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isGameMode
                ? (_isLive
                    ? Text(
                        key: const ValueKey('live-text'),
                        total == 0 ? '—' : 'Coup $total',
                        style: GoogleFonts.fredoka(
                          color: AppColors.labelMuted,
                          fontSize: 11,
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('live-btn'),
                        onTap: widget.onReturnToLive,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.neonCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PulsingDot(),
                              const SizedBox(width: 5),
                              Text(
                                'Coup ${widget.reviewIndex + 1} · LIVE',
                                style: GoogleFonts.fredoka(
                                  color: AppColors.neonCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                : Text(
                    key: ValueKey('review-pos-${widget.reviewIndex}'),
                    widget.reviewIndex < 0
                        ? 'Départ'
                        : 'Coup ${widget.reviewIndex + 1}',
                    style: GoogleFonts.fredoka(
                      color: AppColors.labelMuted,
                      fontSize: 11,
                    ),
                  ),
          ),
          const Spacer(),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: widget.onNext),
          _NavBtn(icon: Icons.last_page_rounded, onTap: widget.onLast),
        ],
      ),
    );
  }
}

class _MovePair extends StatelessWidget {
  final int moveNumber;
  final String whiteSan;
  final String? blackSan;
  final bool isWhiteActive;
  final bool isBlackActive;
  final VoidCallback onWhiteTap;
  final VoidCallback? onBlackTap;
  final int? whiteTimeMs;
  final int? blackTimeMs;

  const _MovePair({
    required this.moveNumber,
    required this.whiteSan,
    this.blackSan,
    required this.isWhiteActive,
    required this.isBlackActive,
    required this.onWhiteTap,
    this.onBlackTap,
    this.whiteTimeMs,
    this.blackTimeMs,
  });

  Widget _moveChip(
      String san, bool isActive, VoidCallback onTap, int? timeMs) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.neonCyan.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive
              ? Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.6), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              san,
              style: GoogleFonts.fredoka(
                color: isActive ? AppColors.neonCyan : AppColors.labelWhite,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive && timeMs != null)
              Text(
                _formatTimeMs(timeMs),
                style: GoogleFonts.fredoka(
                  color: AppColors.neonCyan.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeMs(int ms) {
    if (ms >= 60000) {
      final m = ms ~/ 60000;
      final s = (ms % 60000) ~/ 1000;
      return '${m}m${s.toString().padLeft(2, '0')}s';
    }
    final s = ms ~/ 1000;
    final tenths = (ms % 1000) ~/ 100;
    return '$s.${tenths}s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 2),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$moveNumber.',
              style: GoogleFonts.fredoka(
                color: AppColors.labelMuted,
                fontSize: 11,
              ),
            ),
            _moveChip(whiteSan, isWhiteActive, onWhiteTap, whiteTimeMs),
            if (blackSan != null) ...[
              Text(
                ' ',
                style: TextStyle(
                    color: AppColors.labelMuted.withValues(alpha: 0.5),
                    fontSize: 11),
              ),
              _moveChip(blackSan!, isBlackActive, onBlackTap!, blackTimeMs),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          color: AppColors.labelMuted,
          size: 22,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.neonCyan,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
