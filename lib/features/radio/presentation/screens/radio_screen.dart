import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/sound_wave.dart';
import '../widgets/radio_dial.dart';
import '../widgets/radio_controls.dart';

class RadioScreen extends StatefulWidget {
  final String? streamUrl;
  final String? title;
  final double? frequency;

  const RadioScreen({
    super.key,
    this.streamUrl,
    this.title,
    this.frequency,
  });

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  bool _isPlaying = false;
  double _currentFrequency = 107.7;

  @override
  void initState() {
    super.initState();
    if (widget.frequency != null) {
      _currentFrequency = widget.frequency!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title ?? 'Radio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Station name
          if (widget.title != null)
            Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

          const SizedBox(height: 20),

          // Sound wave animation
          SoundWave(isPlaying: _isPlaying),

          const SizedBox(height: 30),

          // Radio dial
          RadioDial(frequency: _currentFrequency),

          const SizedBox(height: 30),

          // Connection status
          if (widget.streamUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPlaying
                    ? AppColors.liveGreen.withValues(alpha: 0.1)
                    : AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPlaying ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: _isPlaying ? AppColors.liveGreen : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPlaying ? 'Conectado' : 'Desconectado',
                    style: TextStyle(
                      color: _isPlaying ? AppColors.liveGreen : AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 30),

          // Controls
          RadioControls(
            isPlaying: _isPlaying,
            onPlayPause: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
              // TODO: Integrate with actual audio player using widget.streamUrl
            },
            onBackward: () {},
            onForward: () {},
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}