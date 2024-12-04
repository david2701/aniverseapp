import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeType {
  midnightNebula,
  crimsonAnime,
  etherealPurple,
  deepOceanStream,
  neonTokyo,
  twilightCosmos,
  shadowRealm,
  cyberAnime,
  moonlitSilver,
  darkChroma,
  // New themes
  blazingPhoenix,    // Orange and black theme
  crimsonShadow,     // Red and black theme
  // Dark Modes
  dark,
  // Light Modes
  sakuraBlossom,     // Renovated light theme
  solarFlare,        // New energetic light theme
  serenityLight,     // New calm light theme
}

class ThemeManager {
  static ThemeType? getThemeType(String themeName) {
    String lowerThemeName = themeName.toLowerCase();
    for (ThemeType type in ThemeType.values) {
      if (type.toString().split('.').last.toLowerCase() == lowerThemeName) {
        return type;
      }
    }
    return null;
  }

  static LinearGradient createLinearGradient(
      {required Color begin,
        required Color end,
        Alignment startAlignment = Alignment.centerLeft,
        Alignment endAlignment = Alignment.centerRight}) {
    return LinearGradient(
      colors: [begin, end],
      begin: startAlignment,
      end: endAlignment,
    );
  }

  static ThemeData getTheme(ThemeType themeType) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return _createThemeData(
      colorScheme: _getColorScheme(themeType),
      textTheme: textTheme,
    );
  }

  static ThemeData _createThemeData(
      {required ColorScheme colorScheme, required TextTheme textTheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      extensions: [_createGradientExtension(colorScheme)],
    );
  }

  static ThemeExtension<GradientColors> _createGradientExtension(
      ColorScheme colorScheme) {
    return GradientColors(
      primaryGradient: createLinearGradient(
          begin: colorScheme.primary, end: colorScheme.secondary),
      secondaryGradient: createLinearGradient(
          begin: colorScheme.secondary, end: colorScheme.tertiary),
      tertiaryGradient: createLinearGradient(
          begin: colorScheme.tertiary, end: colorScheme.primary),
    );
  }

  static ColorScheme _getColorScheme(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.midnightNebula:
        return ColorScheme.dark(
          primary: Color(0xFF6A5ACD),      // Slate Blue
          secondary: Color(0xFF483D8B),    // Dark Slate Blue
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF121026),      // Deep Dark Blue-Purple
          onSurface: Color(0xFFE6E6FA),    // Lavender
          background: Color(0xFF0A0A1F),   // Darker Blue-Purple
          onBackground: Color(0xFFE6E6FA),  // Lavender
          error: Color(0xFFFF6B6B),        // Soft Red
          onError: Color(0xFFFFFFFF),      // White
          primaryContainer: Color(0xFF2A1F5F), // Deeper Purple
          onPrimaryContainer: Color(0xFFD1C4E9), // Light Purple
        );

      case ThemeType.crimsonAnime:
        return ColorScheme.dark(
          primary: Color(0xFFDC143C),      // Crimson
          secondary: Color(0xFF8B0000),    // Dark Red
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF1A0A0A),      // Very Dark Red-Black
          onSurface: Color(0xFFF5F5F5),    // White Smoke
          background: Color(0xFF0F0505),   // Darker Red-Black
          onBackground: Color(0xFFF8F8F8), // Off-White
          error: Color(0xFFFF4444),        // Bright Red
          onError: Color(0xFFFFFFFF),      // White
          primaryContainer: Color(0xFF2B0000), // Deep Red
          onPrimaryContainer: Color(0xFFFFCDD2), // Light Pink
        );

      case ThemeType.blazingPhoenix:
        return ColorScheme.dark(
          primary: Color(0xFFFF4500),      // Orange Red (acento principal)
          secondary: Color(0xFF993300),    // Dark Orange (acento secundario)
          tertiary: Color(0xFF662200),     // Very Dark Orange
          surface: Color(0xFF0F0905),      // Almost Black with slight orange tint
          onSurface: Color(0xFFFFF5E6), // Soft Orange-White
          error: Color(0xFFFF3300),        // Bright Orange-Red
          onError: Color(0xFF000000),      // Pure Black
          primaryContainer: Color(0xFF1A0F00), // Very Dark Orange-Black
          onPrimaryContainer: Color(0xFFFFAB40), // Light Orange
          outline: Color(0xFF2D1810),      // Dark Orange-Brown outline
        );

      case ThemeType.crimsonShadow:
        return ColorScheme.dark(
          primary: Color(0xFFDC1C1C),      // Bright Red (acento principal)
          secondary: Color(0xFF8B0000),    // Dark Red (acento secundario)
          tertiary: Color(0xFF590000),     // Very Dark Red
          surface: Color(0xFF0F0505),      // Almost Black with slight red tint
          onSurface: Color(0xFFFFF0F0), // Soft Red-White
          error: Color(0xFFFF1A1A),        // Bright Red
          onError: Color(0xFF000000),      // Pure Black
          primaryContainer: Color(0xFF1A0000), // Very Dark Red-Black
          onPrimaryContainer: Color(0xFFFF8080), // Light Red
          outline: Color(0xFF2D1515),      // Dark Red-Black outline
        );

    // Improved Light Themes
      case ThemeType.sakuraBlossom:
        return ColorScheme.light(
          primary: Color(0xFFFF69B4),      // Hot Pink
          secondary: Color(0xFFFF99CC),    // Soft Pink
          tertiary: Color(0xFFFFB7C5),     // Cherry Blossom Pink
          surface: Color(0xFFFFF0F5),      // Lavender Blush
          onSurface: Color(0xFF2D2D2D),    // Soft Black
          background: Color(0xFFFFF5F8),   // Lighter Pink-White
          onBackground: Color(0xFF1A1A1A), // Almost Black
          error: Color(0xFFE91E63),        // Pink Error
          onError: Color(0xFFFFFFFF),      // White
          primaryContainer: Color(0xFFFFD6E7), // Light Pink Container
          onPrimaryContainer: Color(0xFF4A154E), // Deep Purple
        );

      case ThemeType.solarFlare:
        return ColorScheme.light(
          primary: Color(0xFFFF6B00),      // Bright Orange
          secondary: Color(0xFFFF9E00),    // Golden Orange
          tertiary: Color(0xFFFFBF00),     // Amber
          surface: Color(0xFFFFFBF5),      // Cream White
          onSurface: Color(0xFF1F1F1F),    // Almost Black
          background: Color(0xFFFFF8EC),   // Soft Orange-White
          onBackground: Color(0xFF262626), // Dark Gray
          error: Color(0xFFFF3D00),        // Bright Orange-Red
          onError: Color(0xFFFFFFFF),      // White
          primaryContainer: Color(0xFFFFE0B2), // Light Orange Container
          onPrimaryContainer: Color(0xFF4E2500), // Deep Brown
        );

      case ThemeType.serenityLight:
        return ColorScheme.light(
          primary: Color(0xFF64B5F6),      // Light Blue
          secondary: Color(0xFF81D4FA),    // Lighter Blue
          tertiary: Color(0xFF4FC3F7),     // Sky Blue
          surface: Color(0xFFF8FDFF),      // Almost White
          onSurface: Color(0xFF202124),    // Dark Gray
          background: Color(0xFFF1F8FF),   // Very Light Blue
          onBackground: Color(0xFF202124), // Dark Gray
          error: Color(0xFF29B6F6),        // Blue Error
          onError: Color(0xFFFFFFFF),      // White
          primaryContainer: Color(0xFFE3F2FD), // Light Blue Container
          onPrimaryContainer: Color(0xFF1A237E), // Deep Blue
        );

      case ThemeType.dark:
        return ColorScheme.dark(
          primary: Color(0xFF1A1A1A),      // Almost Black
          secondary: Color(0xFF505050),    // Ultra Dark Gray
          tertiary: Color(0xFF0A0A0A),     // Deepest Black
          surface: Color(0xFF0C0C0C),      // Pitch Black
          onSurface: Color(0xFFE0E0E0),    // Light Gray
          background: Color(0xFF000000),   // Pure Black
          onBackground: Color(0xFFE0E0E0), // Light Gray
          error: Color(0xFFCF6679),        // Dark Red
          onError: Color(0xFF000000),      // Black
          primaryContainer: Color(0xFF2D2D2D), // Dark Gray Container
          onPrimaryContainer: Color(0xFFE0E0E0), // Light Gray
        );

      default:
        return ColorScheme.dark(
          primary: Color(0xFF1A1A1A),      // Almost Black
          secondary: Color(0xFF121212),    // Ultra Dark Gray
          tertiary: Color(0xFF0A0A0A),     // Deepest Black
          surface: Color(0xFF0C0C0C),      // Pitch Black
          onSurface: Color(0xFFE0E0E0),    // Light Gray
          background: Color(0xFF000000),   // Pure Black
          onBackground: Color(0xFFE0E0E0), // Light Gray
          error: Color(0xFFCF6679),        // Dark Red
          onError: Color(0xFF000000),      // Black
          primaryContainer: Color(0xFF2D2D2D), // Dark Gray Container
          onPrimaryContainer: Color(0xFFE0E0E0), // Light Gray
        );
    }
  }
}

class GradientColors extends ThemeExtension<GradientColors> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient tertiaryGradient;

  GradientColors({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.tertiaryGradient,
  });

  @override
  ThemeExtension<GradientColors> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    LinearGradient? tertiaryGradient,
  }) {
    return GradientColors(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      tertiaryGradient: tertiaryGradient ?? this.tertiaryGradient,
    );
  }

  @override
  ThemeExtension<GradientColors> lerp(
      ThemeExtension<GradientColors>? other,
      double t,
      ) {
    if (other is! GradientColors) {
      return this;
    }
    return GradientColors(
      primaryGradient:
      LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      secondaryGradient:
      LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
      tertiaryGradient:
      LinearGradient.lerp(tertiaryGradient, other.tertiaryGradient, t)!,
    );
  }
}