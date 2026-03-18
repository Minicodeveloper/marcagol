import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (basados en el logo MARCA gol)
  static const Color primary = Color(0xFFD41920);       // Rojo MARCA
  static const Color secondary = Color(0xFFFFCC00);      // Amarillo/Gold "gol"
  static const Color accent = Color(0xFFFF6D00);         // Anaranjado fuerte
  static const Color accentLight = Color(0xFFFF9100);    // Anaranjado claro
  
  // Colores de fondo
  static const Color background = Color(0xFFF8F5F0);    // Crema cálido
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  
  // Estado Live
  static const Color liveGreen = Color(0xFF2ECC40);
  static const Color liveRed = Color(0xFFFF4136);
  
  // Admin
  static const Color adminOrange = Color(0xFFFF6D00);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD41920), Color(0xFF8B0000)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
  );
  
  static const LinearGradient inactiveGradient = LinearGradient(
    colors: [Color(0xFF666666), Color(0xFF444444)],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFCC00), Color(0xFFFF9100)],
  );
  
  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
  );

  // Warm dark gradient for headers
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C1810), Color(0xFF1A1A1A)],
  );
}