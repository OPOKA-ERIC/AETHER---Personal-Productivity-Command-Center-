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
    'personal': Color(0xFFEC4899),
    'health': Color(0xFF10B981),
    'reading': Color(0xFF6366F1),
    'meeting': Color(0xFFF97316),
    'deep work': Color(0xFF8B5CF6),
  };

  static Color categoryColor(String cat) =>
      categoryColors[cat.toLowerCase()] ?? textMuted;
}

class AetherTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AetherColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AetherColors.purple,
        secondary: AetherColors.cyan,
        surface: AetherColors.glass,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
          letterSpacing: -0.02,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AetherColors.textPrimary,
          letterSpacing: -0.02,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AetherColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AetherColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AetherColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AetherColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AetherColors.textBright,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AetherColors.glass,
        indicatorColor: AetherColors.purple.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              color: AetherColors.purple,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            color: AetherColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AetherColors.purple);
          }
          return const IconThemeData(color: AetherColors.textMuted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AetherColors.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AetherColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AetherColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AetherColors.purple, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AetherColors.textMuted),
        hintStyle: GoogleFonts.inter(color: AetherColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AetherColors.purple,
          foregroundColor: AetherColors.textBright,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1530),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AetherColors.glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1530),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AetherColors.glassBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AetherColors.glass,
        labelStyle: GoogleFonts.inter(color: AetherColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AetherColors.glassBorder),
        ),
      ),
    );
  }
}
