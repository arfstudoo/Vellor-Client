import 'package:flutter/material.dart';

class VellorColors {
  static const Color background = Color(0xFF08080A);
  static const Color surface = Color(0xFF0F0F14);
  static const Color surfaceElevated = Color(0xFF15151D);
  static const Color surfaceBorder = Color(0xFF1E1E28);
  static const Color surfaceBorderSubtle = Color(0xFF171720);

  static const Color redPrimary = Color(0xFFE50914);
  static const Color redBright = Color(0xFFFF2E3D);
  static const Color redGlow = Color(0x22E50914);
  static const Color redSubtle = Color(0xFF1E0A0D);

  static const Color textPrimary = Color(0xFFEDEDF0);
  static const Color textSecondary = Color(0xFF888894);
  static const Color textMuted = Color(0xFF4C4C58);

  static const Color greenPing = Color(0xFF10B981);
  static const Color yellowPing = Color(0xFFF59E0B);
  static const Color redPing = Color(0xFFEF4444);
}

typedef TunyxColors = VellorColors;

class VellorTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VellorColors.background,
      primaryColor: VellorColors.redPrimary,
      colorScheme: const ColorScheme.dark(
        primary: VellorColors.redPrimary,
        secondary: VellorColors.redBright,
        surface: VellorColors.surface,
        onSurface: VellorColors.textPrimary,
      ),
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: VellorColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: VellorColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: VellorColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: VellorColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

typedef TunyxTheme = VellorTheme;
