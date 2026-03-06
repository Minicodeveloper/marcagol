import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Controles de reproducción de la radio
class RadioControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onBackward;
  final VoidCallback onForward;

  const RadioControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onBackward,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Escala de frecuencias
        _buildFrequencyScale(),

        const SizedBox(height: 40),

        // Controles principales
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón -15s
            _buildControlButton(
              icon: Icons.replay_10,
              label: '-15',
              onTap: onBackward,
            ),

            const SizedBox(width: 40),

            // Botón Play/Pause (grande)
            GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFDC0032)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(width: 40),

            // Botón +30s
            _buildControlButton(
              icon: Icons.forward_30,
              label: '+30',
              onTap: onForward,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyScale() {
    return Container(
      height: 80,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Líneas verticales de frecuencia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(11, (index) {
              final freq = 90 + (index * 2);
              final isHighlight = freq % 5 == 0;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 2,
                    height: isHighlight ? 40 : 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  if (isHighlight)
                    Text(
                      '$freq',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                ],
              );
            }),
          ),

          // Indicador amarillo (cursor)
          Positioned(
            top: 0,
            child: Container(
              width: 3,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 55,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary,
              size: 28,
            ),
            Positioned(
              bottom: 8,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}