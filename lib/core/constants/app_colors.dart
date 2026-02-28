import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primary = Color(0xFFDC0032);
  static const Color secondary = Color(0xFFFFFFFF);
  
  // Colores de fondo
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF2A2A2A);
  static const Color bottomNavBackground = Color(0xFF0D0D0D);
  
  // Colores de acento
  static const Color liveRed = Color(0xFFFF4444);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFDC0032), Color(0xFF8B0020)],
  );
  
  static const LinearGradient inactiveGradient = LinearGradient(
    colors: [Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
  );
}