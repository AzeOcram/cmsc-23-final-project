// FILE LOCATION: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — olive green & lemongrass / sunflower
  static const Color forestDeep = Color(0xFF2D4A1E); // deep forest green
  static const Color oliveGreen = Color(0xFF6B7C3A); // main olive
  static const Color lemongrass = Color(0xFF8FA84A); // lemongrass accent
  static const Color meadow = Color(0xFFB5C96A); // lighter grass
  static const Color sunflowerGold = Color(0xFFE8C44A); // sunflower yellow
  static const Color sunflowerDeep = Color(0xFFD4A017); // sunflower center
  static const Color petalCream = Color(0xFFFFF8DC); // light petal background
  static const Color barkBrown = Color(0xFF5C4033); // warm brown for text
  static const Color soilDark = Color(0xFF1A2A0E); // almost black-green

  // Neutrals
  static const Color cream = Color(0xFFF9F5E8);
  static const Color lightMoss = Color(0xFFE8EDD6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);

  // Gradients
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestDeep, oliveGreen, lemongrass],
  );

  static const LinearGradient sunflowerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sunflowerGold, sunflowerDeep],
  );

  static const LinearGradient meadowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [petalCream, lightMoss, meadow],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.oliveGreen,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.lemongrass,
        onPrimaryContainer: AppColors.forestDeep,
        secondary: AppColors.sunflowerGold,
        onSecondary: AppColors.barkBrown,
        secondaryContainer: AppColors.petalCream,
        onSecondaryContainer: AppColors.barkBrown,
        surface: AppColors.cream,
        onSurface: AppColors.barkBrown,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.forestDeep,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.forestDeep,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.forestDeep,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.forestDeep,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.forestDeep,
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.forestDeep,
        ),
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: AppColors.barkBrown),
        bodyMedium: GoogleFonts.lato(fontSize: 14, color: AppColors.barkBrown),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightMoss.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.lemongrass.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.lemongrass.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.oliveGreen, width: 2),
        ),
        labelStyle: GoogleFonts.lato(color: AppColors.oliveGreen),
        hintStyle: GoogleFonts.lato(
          color: AppColors.oliveGreen.withOpacity(0.5),
        ),
        prefixIconColor: AppColors.oliveGreen,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oliveGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.oliveGreen,
          side: const BorderSide(color: AppColors.oliveGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestDeep,
        foregroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.oliveGreen.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightMoss,
        selectedColor: AppColors.oliveGreen,
        labelStyle: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Dark theme (optional feature)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.lemongrass,
        onPrimary: AppColors.soilDark,
        primaryContainer: AppColors.oliveGreen,
        onPrimaryContainer: AppColors.cream,
        secondary: AppColors.sunflowerGold,
        onSecondary: AppColors.soilDark,
        secondaryContainer: AppColors.barkBrown,
        onSecondaryContainer: AppColors.cream,
        surface: const Color(0xFF1E2A10),
        onSurface: AppColors.cream,
        error: const Color(0xFFCF6679),
        onError: AppColors.soilDark,
      ),
      scaffoldBackgroundColor: const Color(0xFF141E0A),
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: AppColors.lightMoss),
        bodyMedium: GoogleFonts.lato(fontSize: 14, color: AppColors.lightMoss),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1A07),
        foregroundColor: AppColors.cream,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
      ),
    );
  }
}
