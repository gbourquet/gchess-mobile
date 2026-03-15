import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color bgDeep = Color(0xFF08131F);
  static const Color bgMid = Color(0xFF0D1E2E);
  static const Color bgPanel = Color(0xFF112030);
  static const Color bgTeal = Color(0xFF0A3535);
  static const Color bgCard = Color(0xFF0A1E30);

  // Neon accents
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2D9B);
  static const Color neonGold = Color(0xFFFFD700);

  // Player UI
  static const Color playerName = Color(0xFFFF8C00);
  static const Color playerTitle = Color(0xFF4EDA72);
  static const Color clockDigitPlayer = Color(0xFF00E5FF);
  static const Color clockDigitOpponent = Color(0xFFFF3333);
  static const Color clockBg = Color(0xFF040C18);

  // Board
  static const Color boardBorderDark = Color(0xFF6A4010);
  static const Color boardBorderLight = Color(0xFFB8852A);
  static const Color lightSquare = Color(0xFFE8D5A3);
  static const Color darkSquare = Color(0xFF527A52);
  static const Color selectedSquare = Color(0xFFFFD700);
  static const Color legalMoveEmpty = Color(0x9900E676);
  static const Color legalMoveCapture = Color(0xCC00E676);
  static const Color lastMoveHighlight = Color(0x70FFD700);
  static const Color checkSquare = Color(0xFFFF4444);
  static const Color preMoveSquare = Color(0xFFFF8C00);
  static const Color preMoveHighlight = Color(0x70FF8C00);

  // Labels
  static const Color labelWhite = Colors.white;
  static const Color labelMuted = Color(0xFF8899AA);
  static const Color coordLabel = Color(0xFFE8D5A3);

  // Action buttons
  static const Color actionBg = Color(0xFF0A2030);
  static const Color actionBorder = Color(0xFF00E5FF);
}

class AppTheme {
  static TextTheme _buildTextTheme() {
    return GoogleFonts.fredokaTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.labelWhite),
        displayMedium: TextStyle(color: AppColors.labelWhite),
        displaySmall: TextStyle(color: AppColors.labelWhite),
        headlineLarge: TextStyle(color: AppColors.labelWhite),
        headlineMedium: TextStyle(color: AppColors.labelWhite),
        headlineSmall: TextStyle(color: AppColors.labelWhite),
        titleLarge: TextStyle(color: AppColors.labelWhite),
        titleMedium: TextStyle(color: AppColors.labelWhite),
        titleSmall: TextStyle(color: AppColors.labelMuted),
        bodyLarge: TextStyle(color: AppColors.labelWhite),
        bodyMedium: TextStyle(color: AppColors.labelWhite),
        bodySmall: TextStyle(color: AppColors.labelMuted),
        labelLarge: TextStyle(color: AppColors.labelWhite),
        labelMedium: TextStyle(color: AppColors.labelMuted),
        labelSmall: TextStyle(color: AppColors.labelMuted),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonPink,
        surface: AppColors.bgPanel,
        error: Color(0xFFFF4444),
        onPrimary: AppColors.bgDeep,
        onSecondary: AppColors.labelWhite,
        onSurface: AppColors.labelWhite,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        foregroundColor: AppColors.labelWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.labelWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neonCyan,
          side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neonCyan,
          textStyle: GoogleFonts.fredoka(fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.labelMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.labelMuted.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.labelMuted),
        hintStyle: const TextStyle(color: AppColors.labelMuted),
        prefixIconColor: AppColors.labelMuted,
        suffixIconColor: AppColors.labelMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.3)),
        ),
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.labelWhite,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.labelMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgPanel,
        contentTextStyle: const TextStyle(color: AppColors.labelWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
