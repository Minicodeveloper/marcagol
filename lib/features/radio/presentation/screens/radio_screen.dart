import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/sound_wave.dart';
import '../widgets/radio_dial.dart';
import '../widgets/radio_controls.dart';

/// Pantalla de Radio FM
/// TODO: Integrar con servicio de streaming real
class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  bool _isPlaying = false;
  double _frequency = 107.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'MG',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('MARCA GOL', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Mostrar opciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),

          // Onda de sonido
          SoundWave(isPlaying: _isPlaying),

          const SizedBox(height: 40),

          // Dial con frecuencia
          RadioDial(frequency: _frequency),

          const SizedBox(height: 60),

          // Controles
          RadioControls(
            isPlaying: _isPlaying,
            onPlayPause: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
              // TODO: Reproducir/pausar radio
            },
            onBackward: () {
              // TODO: Retroceder 15 segundos
            },
            onForward: () {
              // TODO: Adelantar 30 segundos
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }
}