import 'package:flutter/material.dart';

class CyberTheme {
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFFBC13FE);
  static const Color gridColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF222222);

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: neonGreen,
    colorScheme: ColorScheme.dark(
      primary: neonGreen,
      secondary: neonCyan,
      surface: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
    ),
  );
}
