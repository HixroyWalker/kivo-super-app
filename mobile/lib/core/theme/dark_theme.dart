import 'package:flutter/material.dart';

class KivoDarkTheme {
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF141C24);
  static const Color surfaceElevated = Color(0xFF1B2632);
  static const Color surfaceBorder = Color(0x1FFFFFFF);
  
  static const Color primaryEmerald = Color(0xFF00E676);
  static const Color primaryDark = Color(0xFF00B0FF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentRose = Color(0xFFFF1744);
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF90A4AE);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF18232F), Color(0xFF101720)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryEmerald,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        secondary: accentCyan,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: surfaceBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryEmerald.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: primaryEmerald,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryEmerald, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
      ),
    );
  }
}
