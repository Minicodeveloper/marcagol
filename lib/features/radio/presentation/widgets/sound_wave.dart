import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget que muestra la onda de sonido animada
class SoundWave extends StatelessWidget {
  final bool isPlaying;

  const SoundWave({
    super.key,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(40, (index) {
          final height = _getBarHeight(index);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 2,
            height: isPlaying ? height : 2,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  double _getBarHeight(int index) {
    // Crear patrón de onda
    final pattern = [10.0, 25.0, 45.0, 60.0, 45.0, 25.0, 10.0];
    return pattern[index % pattern.length];
  }
}