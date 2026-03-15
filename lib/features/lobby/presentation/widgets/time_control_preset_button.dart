import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gchess_mobile/config/theme.dart';

class TimeControlPresetButton extends StatelessWidget {
  final String timeControl;
  final String label;
  final VoidCallback onTap;

  const TimeControlPresetButton({
    super.key,
    required this.timeControl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeControl,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.neonCyan,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.fredoka(
                fontSize: 11,
                color: AppColors.playerTitle,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
