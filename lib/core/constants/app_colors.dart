import 'package:flutter/material.dart';

class AppColors {
  // Colores principales del diseño Figma
  static const Color primary = Color(0xFFDC0032); // Rojo MARCA GOL
  static const Color secondary = Color(0xFFFFD700); // Amarillo botones
  static const Color accent = Color(0xFFFFC107); // Amarillo "Ver Más Live"
  
  // Colores de fondo (ahora claro)
  static const Color background = Color(0xFFF5F5F5); // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF); // Blanco
  static const Color cardBackground = Color(0xFFFFFFFF); // Blanco
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  
  // Estado Live
  static const Color liveGreen = Color(0xFF4CAF50);
  static const Color liveRed = Color(0xFFFF4444);
  
  // Gradientes (por si se necesitan)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFDC0032), Color(0xFF8B0020)],
  );
}