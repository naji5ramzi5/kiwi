import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Luxurious Emerald & Crisp White Premium Palette
  static const Color primary = Color(0xFF047857); // Emerald 700 (More Premium)
  static const Color primaryDark = Color(0xFF064E3B); // Emerald 900
  static const Color primaryLight = Color(0xFF6EE7B7); // Emerald 300
  
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  
  static const Color background = Color(0xFFF8FAFC); // Crisp White/Slate 50
  static const Color surface = Colors.white; // Pure White
  static const Color sidebar = Color(0xFF022C22); // Very Dark Emerald for Sidebar
  
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  
  static const Color accent = Color(0xFFF59E0B); // Amber 500 for highlights
  static const Color error = Color(0xFFEF4444); // Red 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
    );
  }
}
