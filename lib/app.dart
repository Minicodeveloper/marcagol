import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/new_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marca Gol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Nuevo tema claro
      home: const NewHomeScreen(), // Nueva pantalla
    );
  }
}