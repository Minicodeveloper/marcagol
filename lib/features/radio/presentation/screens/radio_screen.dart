import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  YoutubePlayerController? _youtubeController;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    if (widget.frequency != null) {
      _currentFrequency = widget.frequency!;
    }
    
    // Check if it's a YouTube URL
    if (widget.streamUrl != null) {
      final isYoutube = widget.streamUrl!.contains('youtube.com') || widget.streamUrl!.contains('youtu.be');
      
      if (isYoutube) {
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
          _isPlaying = true;
        }
      } else {
        // Not YouTube - Use WebView for Facebook, etc.
        String finalUrl = widget.streamUrl!;
        final isFacebook = finalUrl.contains('facebook.com') || finalUrl.contains('fb.watch') || finalUrl.contains('fb.gg');
        if (isFacebook) {
          // Normalize: replace mobile with desktop
          finalUrl = finalUrl.replaceAll('m.facebook.com', 'www.facebook.com');
          finalUrl = 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(finalUrl)}&show_text=false&t=0&autoplay=true';
        }

        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
          ..loadRequest(Uri.parse(finalUrl));
        _isPlaying = true;
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
          
          // Invisible WebView player for Facebook, etc.
          if (_webController != null)
            SizedBox(
              width: 1,
              height: 1,
              child: WebViewWidget(controller: _webController!),
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
                  if (_webController != null && widget.streamUrl != null) {
                    _webController!.loadRequest(Uri.parse(widget.streamUrl!));
                  }
                } else {
                  _youtubeController?.pause();
                  _webController?.loadRequest(Uri.parse('about:blank'));
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