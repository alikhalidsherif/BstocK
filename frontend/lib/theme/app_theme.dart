import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_schemes.dart';
import 'app_typography.dart';
import 'semantic_colors.dart';

class AppThemes {
  static ThemeData get lightTheme =>
      _buildTheme(AppColorSchemes.light, SemanticColors.light);

  static ThemeData get darkTheme =>
      _buildTheme(AppColorSchemes.dark, SemanticColors.dark);

  static ThemeData _buildTheme(
      ColorScheme colors, SemanticColors semanticColors) {
    final textTheme = AppTypography.build(colors);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.onBackground,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onBackground,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colors.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: colors.brightness == Brightness.light
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: colors.surfaceTint,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        shadowColor: colors.shadow.withOpacity(0.14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: colors.outline.withOpacity(0.35), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: colors.outline.withOpacity(0.32), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.3),
        ),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.surfaceVariant
                : colors.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurfaceVariant
                : colors.onPrimary,
          ),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(colors.primary),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? colors.outline.withOpacity(0.4)
                  : colors.primary,
              width: 1.2,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
          foregroundColor: WidgetStateProperty.all(colors.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        labelStyle: textTheme.labelMedium!.copyWith(color: colors.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: colors.primary.withOpacity(0.12),
        secondarySelectedColor: colors.primary.withOpacity(0.2),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface.withOpacity(0.92),
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        space: 24,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: colors.surface,
        iconColor: colors.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: colors.onSurface),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colors.primary.withOpacity(0.6),
        ),
        trackColor: WidgetStateProperty.all(colors.surfaceVariant),
        radius: const Radius.circular(999),
      ),
      iconTheme: IconThemeData(color: colors.primary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.surfaceVariant,
      ),
      extensions: [semanticColors],
    );
  }
}

