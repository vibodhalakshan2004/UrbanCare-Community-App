import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

<<<<<<< HEAD
  static const Color bgDark = Color(0xFF080808);
  static const Color bgLight = Color(0xFFF8FAFC); // Very light slate/blue
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color textMutedLight = Color(0xFF64748B);

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0F172A), // Dark slate
        secondary: Color(0xFF16A34A), // Green
        surface: Colors.white, // White cards
        onSurface: Color(0xFF0F172A), // Text color is dark
        onSurfaceVariant: textMutedLight, // Muted text
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        hintStyle: const TextStyle(color: textMutedLight),
      ),
    );
  }
=======
  static const Color bg = Color(0xFF080808);
  static const Color card = Color(0x14000000);
  static const Color border = Color(0x24FFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
>>>>>>> origin/main

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
<<<<<<< HEAD
      scaffoldBackgroundColor: bgDark,
=======
      scaffoldBackgroundColor: bg,
>>>>>>> origin/main
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFF4ADE80),
        surface: Color(0xFF111111),
<<<<<<< HEAD
        onSurface: Colors.white, // Text color is white
        onSurfaceVariant: textMutedDark, // Muted text
=======
>>>>>>> origin/main
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.03),
        elevation: 0,
        shape: RoundedRectangleBorder(
<<<<<<< HEAD
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
=======
          side: const BorderSide(color: border),
>>>>>>> origin/main
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
=======
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
>>>>>>> origin/main
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x66FFFFFF)),
        ),
<<<<<<< HEAD
        hintStyle: const TextStyle(color: textMutedDark),
=======
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
>>>>>>> origin/main
      ),
    );
  }
}
<<<<<<< HEAD

/// Extension to quickly get colors that adapt perfectly to light/dark modes
extension AdaptiveTheme on BuildContext {
  /// Base contrast color (dark slate in light mode, white in dark mode)
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  
  /// Muted text color that adapts
  Color get onSurfaceVariant => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Standard border color for cards/containers
  Color get borderColor => onSurface.withValues(alpha: 0.1);

  /// Subtle background fill for containers/chips
  Color get fill04 => onSurface.withValues(alpha: 0.04);
  Color get fill08 => onSurface.withValues(alpha: 0.08);
}

=======
>>>>>>> origin/main
