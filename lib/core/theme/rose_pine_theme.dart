import 'package:flutter/material.dart';

/// Vibrant Rosé Pine Design System & Pastel Themes
class RosePineColors {
  // Vibrant Rosé Pine Dawn (Light - Default)
  static const Color dawnBase = Color(0xFFFBF7F2);
  static const Color dawnSurface = Color(0xFFFFFFFF);
  static const Color dawnOverlay = Color(0xFFF3EBE1);
  static const Color dawnMuted = Color(0xFF8C869E);
  static const Color dawnSubtle = Color(0xFF676180);
  static const Color dawnText = Color(0xFF383256);
  static const Color dawnLove = Color(0xFFE63956); // Vibrant berry / error / weak
  static const Color dawnGold = Color(0xFFF59E0B); // Vibrant warm amber / streak
  static const Color dawnRose = Color(0xFFF43F5E); // Punchy rose coral
  static const Color dawnPine = Color(0xFF1680A6); // Saturated rich teal-pine CTA
  static const Color dawnFoam = Color(0xFF06B6D4); // Vibrant cyan-azure timer
  static const Color dawnIris = Color(0xFF8B5CF6); // Vibrant electric amethyst AI

  // Vibrant Rosé Pine Main (Dark)
  static const Color darkBase = Color(0xFF161420);
  static const Color darkSurface = Color(0xFF1E1B2E);
  static const Color darkOverlay = Color(0xFF2B263F);
  static const Color darkMuted = Color(0xFF7B7596);
  static const Color darkSubtle = Color(0xFFA59EC2);
  static const Color darkText = Color(0xFFF5F3FF);
  static const Color darkLove = Color(0xFFFF4D6D);
  static const Color darkGold = Color(0xFFFFB703);
  static const Color darkRose = Color(0xFFFB7185);
  static const Color darkPine = Color(0xFF22D3EE);
  static const Color darkFoam = Color(0xFF38BDF8);
  static const Color darkIris = Color(0xFFA78BFA);

  // Vibrant Pastel Companion Themes
  static const Map<String, PastelPalette> pastels = {
    'rose_pine': PastelPalette(
      name: 'Rosé Pine',
      primary: dawnPine,
      secondary: dawnIris,
      accent: dawnRose,
    ),
    'catppuccin_mocha': PastelPalette(
      name: 'Catppuccin Mocha',
      primary: Color(0xFFCBA6F7), // Mauve
      secondary: Color(0xFF74C7EC), // Sapphire
      accent: Color(0xFFFAB387), // Peach
    ),
    'catppuccin_latte': PastelPalette(
      name: 'Catppuccin Latte',
      primary: Color(0xFF8839EF), // Mauve
      secondary: Color(0xFF209FB5), // Sapphire
      accent: Color(0xFFFE640B), // Peach
    ),
    'sage_matcha': PastelPalette(
      name: 'Sage Matcha',
      primary: Color(0xFF15803D),
      secondary: Color(0xFF22C55E),
      accent: Color(0xFF86EFAC),
    ),
    'glacier_sky': PastelPalette(
      name: 'Glacier Sky',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF38BDF8),
      accent: Color(0xFFBAE6FD),
    ),
    'lavender_mist': PastelPalette(
      name: 'Lavender Mist',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFA78BFA),
      accent: Color(0xFFDDD6FE),
    ),
    'warm_apricot': PastelPalette(
      name: 'Warm Apricot',
      primary: Color(0xFFEA580C),
      secondary: Color(0xFFFB923C),
      accent: Color(0xFFFED7AA),
    ),
    'honey_butter': PastelPalette(
      name: 'Honey Butter',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFFBBF24),
      accent: Color(0xFFFDE68A),
    ),
  };
}

class PastelPalette {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;

  const PastelPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

class AppTheme {
  static ThemeData lightTheme({String paletteKey = 'rose_pine'}) {
    final palette = RosePineColors.pastels[paletteKey] ??
        RosePineColors.pastels['rose_pine']!;

    final isCatppuccin = paletteKey == 'catppuccin_latte';
    final baseBg = isCatppuccin ? const Color(0xFFEFF1F5) : RosePineColors.dawnBase;
    final surfaceBg = isCatppuccin ? const Color(0xFFFFFFFF) : RosePineColors.dawnSurface;
    final textColor = isCatppuccin ? const Color(0xFF4C4F69) : RosePineColors.dawnText;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: baseBg,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.secondary,
        surface: surfaceBg,
        onSurface: textColor,
        error: RosePineColors.dawnLove,
      ),
      fontFamily: 'DINCond',
      cardTheme: CardThemeData(
        color: surfaceBg,
        elevation: 1,
        shadowColor: palette.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.primary.withValues(alpha: 0.14),
            width: 1.5,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: baseBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isCatppuccin ? const Color(0xFFE6E9EF) : RosePineColors.dawnOverlay).withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isCatppuccin ? const Color(0xFFCCD0DA) : RosePineColors.dawnOverlay),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isCatppuccin ? const Color(0xFFCCD0DA) : RosePineColors.dawnOverlay),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData darkTheme({String paletteKey = 'rose_pine'}) {
    final palette = RosePineColors.pastels[paletteKey] ??
        RosePineColors.pastels['rose_pine']!;

    final isCatppuccin = paletteKey == 'catppuccin_mocha';
    final baseBg = isCatppuccin ? const Color(0xFF1E1E2E) : RosePineColors.darkBase;
    final surfaceBg = isCatppuccin ? const Color(0xFF313244) : RosePineColors.darkSurface;
    final textColor = isCatppuccin ? const Color(0xFFCDD6F4) : RosePineColors.darkText;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: baseBg,
      colorScheme: ColorScheme.dark(
        primary: palette.primary == RosePineColors.dawnPine ? RosePineColors.darkPine : palette.primary,
        onPrimary: baseBg,
        secondary: palette.secondary == RosePineColors.dawnIris ? RosePineColors.darkIris : palette.secondary,
        surface: surfaceBg,
        onSurface: textColor,
        error: RosePineColors.darkLove,
      ),
      fontFamily: 'DINCond',
      cardTheme: CardThemeData(
        color: surfaceBg,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.secondary.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RosePineColors.darkBase,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: RosePineColors.darkText),
        titleTextStyle: TextStyle(
          color: RosePineColors.darkText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RosePineColors.darkOverlay.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RosePineColors.darkOverlay),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RosePineColors.darkOverlay),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
