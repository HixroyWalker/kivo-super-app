import 'package:flutter/material.dart';

class KivoDarkTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF12181F),
      primaryColor: const Color(0xFF00C853),
      cardColor: const Color(0xFF1E2630),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E2630),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00C853),
        secondary: Color(0xFF64FFDA),
        surface: Color(0xFF1E2630),
        background: Color(0xFF12181F),
        onPrimary: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2630),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
