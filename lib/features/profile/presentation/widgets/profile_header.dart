import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final bool isLoggedIn;

  const ProfileHeader({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: isLoggedIn
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  )
                : const Icon(
                    Icons.person_outline,
                    size: 50,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            isLoggedIn ? 'Usuario Demo' : 'Iniciar Sesión',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (!isLoggedIn)
            ElevatedButton(
              onPressed: () {
                // TODO: Navegar a pantalla de login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('INGRESAR'),
            )
          else
            const Text(
              'usuario@example.com',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}