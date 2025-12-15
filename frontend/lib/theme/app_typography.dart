import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme build(ColorScheme colors) {
    final display = GoogleFonts.sora;
    final body = GoogleFonts.epilogue;

    return TextTheme(
      displayLarge: display(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      displayMedium: display(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
      ),
      headlineMedium: display(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.18,
      ),
      titleLarge: display(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.2,
      ),
      titleMedium: display(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.24,
      ),
      titleSmall: display(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.24,
      ),
      bodyLarge: body(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodyMedium: body(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.45,
      ),
      bodySmall: body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      labelLarge: body(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 1.2,
      ),
      labelMedium: body(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
      ),
      labelSmall: body(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
      ),
    ).apply(
      bodyColor: colors.onBackground,
      displayColor: colors.onBackground,
    );
  }
}

