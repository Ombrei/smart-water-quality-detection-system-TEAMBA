import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1A6B8A);
  static const Color primaryLight = Color(0xFF3F8DA8);
  static const Color primaryDark = Color(0xFF0D4F6B);
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentWarm = Color(0xFF4CAF50);

  // Status Colors
  static const Color statusGood = Color(0xFF00C9A7);
  static const Color statusWarn = Color(0xFFFFB300);
  static const Color statusDanger = Color(0xFFE53935);

  // Neutrals
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7C93);
  static const Color divider = Color(0xFFE8EDF2);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A6B8A), Color(0xFF0D4F6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF3F8DA8), Color(0xFF1A6B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        useMaterial3: true,
      );
}

// Sensor card config
class SensorInfo {
  final String label;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final Color color;
  final bool isGood;

  const SensorInfo({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.color,
    required this.isGood,
  });
}
