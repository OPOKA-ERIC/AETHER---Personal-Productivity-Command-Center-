import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AetherColors {
  static const bg = Color(0xFF07050F);
  static const bgGradientEnd = Color(0xFF130E26);
  static const glass = Color(0xAA16112B);
  static const glassBorder = Color(0x12FFFFFF);
  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const textPrimary = Color(0xFFF3F1F8);
  static const textMuted = Color(0xFF9C97B8);
  static const textBright = Color(0xFFFFFFFF);

  static const categoryColors = {
    'coding': Color(0xFF06B6D4),
    'study': Color(0xFF8B5CF6),
    'exercise': Color(0xFF10B981),
    'leisure': Color(0xFFF59E0B),
    'urgent': Color(0xFFF43F5E),
    'personal': Color(0xFFA78BFA),
    'health': Color(0xFF34D399),
    'reading': Color(0xFFFB923C),
    'meeting': Color(0xFF38BDF8),
    'deep work': Color(0xFFC084FC),
  };

  static Color categoryColor(String cat) {
    final color = categoryColors[cat.toLowerCase()];
    if (color != null) return color;
    final hash = cat.toLowerCase().hashCode;
    final palette = [
      const Color(0xFF06B6D4), const Color(0xFF8B5CF6), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFFF43F5E), const Color(0xFFA78BFA),
      const Color(0xFF34D399), const Color(0xFFFB923C), const Color(0xFF38BDF8),
      const Color(0xFFC084FC), const Color(0xFFEC4899), const Color(0xFF14B8A6),
    ];
    return palette[hash.abs() % palette.length];
  }
}

class AetherTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AetherColors.bg,
      canvasColor: const Color(0xFF0C091A),
      colorScheme: const ColorScheme.dark(
        primary: AetherColors.purple,
        secondary: AetherColors.cyan,
        surface: AetherColors.glass,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28, fontWeight: FontWeight.w600,
          color: AetherColors.textBright, letterSpacing: -0.02,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: AetherColors.textPrimary, letterSpacing: -0.02,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500,
          color: AetherColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, color: AetherColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: AetherColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, color: AetherColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x80130E26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AetherColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AetherColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AetherColors.rose, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AetherColors.textMuted, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AetherColors.textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AetherColors.purple,
          foregroundColor: AetherColors.textBright,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AetherColors.glassBorder,
        thickness: 1,
      ),
    );
  }
}
