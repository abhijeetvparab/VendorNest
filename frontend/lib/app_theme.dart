import 'package:flutter/material.dart';

class AppTheme {
  // Primary: Teal
  static const Color violet      = Color(0xFF0F766E); // teal-700 (primary)
  static const Color violetDark  = Color(0xFF0D9488); // teal-600
  static const Color purple      = Color(0xFF134E4A); // teal-900
  static const Color pink        = Color(0xFFF59E0B); // amber-400 (accent)
  static const Color fuchsia     = Color(0xFFD97706); // amber-600
  static const Color cyan        = Color(0xFF0891B2); // cyan-600 (kept for variety)
  static const Color emerald     = Color(0xFF059669); // emerald (status: approved)
  static const Color amber       = Color(0xFFF59E0B); // amber-400
  static const Color rose        = Color(0xFFE11D48); // rose (errors)

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF042F2E), Color(0xFF134E4A), Color(0xFF0F766E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Map<String, Color> roleColors = {
    'Admin':    Color(0xFF0F766E), // teal
    'Vendor':   Color(0xFFF59E0B), // amber
    'Customer': Color(0xFF0891B2), // cyan
  };

  static const Map<String, Color> statusColors = {
    'Active':   Color(0xFF059669),
    'Inactive': Color(0xFF6B7280),
    'Pending':  Color(0xFFF59E0B),
    'Approved': Color(0xFF059669),
    'Rejected': Color(0xFFDC2626),
  };

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
    ),
  );
}
