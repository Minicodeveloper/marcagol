import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/sound_wave.dart';
import '../widgets/radio_dial.dart';
import '../widgets/radio_controls.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.frequency != null) {
      _currentFrequency = widget.frequency!;
    }
    
    // Check if it's a YouTube URL
    if (widget.streamUrl != null && 
        (widget.streamUrl!.contains('youtube.com') || widget.streamUrl!.contains('youtu.be'))) {
      final videoId = YoutubePlayer.convertUrlToId(widget.streamUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: true,
          ),
        );
        _isPlaying = true; // Empieza automáticamente
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          // Invisible YouTube player for audio
          if (_youtubeController != null)
            SizedBox(
              width: 1,
              height: 1,
              child: YoutubePlayer(
                controller: _youtubeController!,
              ),
            ),
          
          Column(
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
                if (_isPlaying) {
                  _youtubeController?.play();
                } else {
                  _youtubeController?.pause();
                }
              });
            },
            onBackward: () {},
            onForward: () {},
          ),

          const SizedBox(height: 20),
        ],
      ),
      ],
      ),
    );
  }
}