import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Kiwi Green Palette
  static const Color primary = Color(0xFF22C55E); // Green-500 light fresh
  static const Color primaryDark = Color(0xFF16A34A); // Green-600
  static const Color primaryLight = Color(0xFFDCFCE7); // Green-50
  
  // Light Mode Colors
  static const Color background = Color(0xFFF8F9FA); // Kwanzu Light Background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color accent = Color(0xFFF59E0B); // Amber for highlights
  
  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121212); // Kwanzu Dark Background
  static const Color surfaceDark = Color(0xFF1E1E1E); // Kwanzu Dark Surface
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      brightness: Brightness.light,
      
      // Typography
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.cairo(color: textPrimary),
        bodyMedium: GoogleFonts.cairo(color: textSecondary),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),

      // Card Theme for soft rounded UI
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1), // subtle border
        ),
        margin: EdgeInsets.zero,
      ),

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      brightness: Brightness.dark,
      
      // Typography
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(color: textPrimaryDark, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.cairo(color: textPrimaryDark),
        bodyMedium: GoogleFonts.cairo(color: textSecondaryDark),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(color: textPrimaryDark, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: surfaceDark,
        background: backgroundDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
      ),
    );
  }
}
