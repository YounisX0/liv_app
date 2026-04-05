import 'package:flutter/material.dart';

class LivTheme {
  // Brand colors (from cloud.html CSS vars)
  static const Color primary = Color(0xFF0B3D2E);   // deep green
  static const Color accent  = Color(0xFF1FB6A6);   // teal
  static const Color gold    = Color(0xFFD4AF37);   // luxury gold
  static const Color gold2   = Color(0xFFF2D27A);
  static const Color warn    = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color ok      = Color(0xFF16A34A);
  static const Color muted   = Color(0xFF64748B);
  static const Color bg      = Color(0xFFF7FAF8);
  static const Color card    = Colors.white;
  static const Color text    = Color(0xFF0F172A);
  static const Color line    = Color(0xFFE5E7EB);

  // Gateway screen colors (dark)
  static const Color darkBg     = Color(0xFF0A0F1A);
  static const Color darkCard   = Color(0xFF111827);
  static const Color darkAccent = Color(0xFF31D0AA);
  static const Color darkMuted  = Color(0xFF99ADCF);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: bg,
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkAccent,
      brightness: Brightness.dark,
      surface: darkBg,
    ),
    scaffoldBackgroundColor: darkBg,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
