import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radiusCard = 12.0;
  static const double radiusElement = 8.0;
  static const double radiusSmall = 4.0;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onPrimaryContainer: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      onSecondaryContainer: AppColors.textOnPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      onSurface: isDark ? Colors.white : AppColors.textPrimary,
      surfaceContainerHighest: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      onSurfaceVariant: isDark ? Colors.white70 : AppColors.textSecondary,
      outline: isDark ? Colors.white24 : AppColors.border,
      outlineVariant: isDark ? Colors.white12 : AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? Colors.white : AppColors.textPrimary,
      onInverseSurface: isDark ? AppColors.textPrimary : Colors.white,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      fontFamily: null, // SF Pro sur iOS, Roboto sur Android (défaut système)

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: isDark ? Colors.white12 : AppColors.border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusElement),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusElement),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusElement),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusElement),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusElement),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusElement),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textDisabled,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? Colors.white38 : AppColors.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.white38 : AppColors.textDisabled,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textSecondary,
          fontSize: 12,
        ),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xDEFFFFFF) : AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xDEFFFFFF) : AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white38 : AppColors.textDisabled,
        ),
      ),
    );
  }
}
