import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color mediumGreen = Color(0xFF388E3C);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color backgroundGreen = Color(0xFFE8F5E9);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: mediumGreen,
        secondary: lightGreen,
      ),
      scaffoldBackgroundColor: backgroundGreen,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      useMaterial3: true,
    );
  }
}