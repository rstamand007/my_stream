import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme Configuration
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.backgroundLight,
          onSurface: AppColors.textPrimaryLight,
          surfaceContainer: AppColors.surfaceLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.primary,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        extensions: [
          const AppThemeExtension(
            surfaceAlternative: Color(0xFFF1F5F9),
            onSurfaceAlternative: Color(0xFF475569),
            success: AppColors.success,
            error: AppColors.error,
            warning: AppColors.warning,
          ),
        ],
      );

  // Dark Theme Configuration
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.backgroundDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainer: AppColors.surfaceDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.primary,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        extensions: [
          const AppThemeExtension(
            surfaceAlternative: AppColors.surfaceLightDark,
            onSurfaceAlternative: AppColors.textSecondaryDark,
            success: AppColors.success,
            error: AppColors.error,
            warning: AppColors.warning,
          ),
        ],
      );
}

// Custom Theme Extension for non-standard Design Tokens
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.surfaceAlternative,
    required this.onSurfaceAlternative,
    required this.success,
    required this.error,
    required this.warning,
  });

  final Color? surfaceAlternative;
  final Color? onSurfaceAlternative;
  final Color? success;
  final Color? error;
  final Color? warning;

  @override
  AppThemeExtension copyWith({
    Color? surfaceAlternative,
    Color? onSurfaceAlternative,
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return AppThemeExtension(
      surfaceAlternative: surfaceAlternative ?? this.surfaceAlternative,
      onSurfaceAlternative: onSurfaceAlternative ?? this.onSurfaceAlternative,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      surfaceAlternative: Color.lerp(surfaceAlternative, other.surfaceAlternative, t),
      onSurfaceAlternative: Color.lerp(onSurfaceAlternative, other.onSurfaceAlternative, t),
      success: Color.lerp(success, other.success, t),
      error: Color.lerp(error, other.error, t),
      warning: Color.lerp(warning, other.warning, t),
    );
  }
}
