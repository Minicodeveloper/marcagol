import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  final String title;

  const YoutubePlayerScreen({
    super.key,
    required this.youtubeUrl,
    required this.title,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadYoutubeDirect();
  }

  @override
  void dispose() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  String? _extractVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com\/live\/)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtu\.be\/)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// JS to clean YouTube page: hide everything EXCEPT the video player area
  /// The video keeps its natural size, we just remove surrounding YouTube UI
  String get _cleanupScript => '''
    (function() {
      var style = document.createElement('style');
      style.textContent = `
        html, body { 
          margin: 0 !important; padding: 0 !important; 
          background: #000 !important; overflow: hidden !important;
        }
        
        /* Hide all YouTube chrome except video */
        ytm-mobile-topbar-renderer, header, #masthead-container,
        ytm-pivot-bar-renderer, .pivot-bar, #bottom-bar,
        ytm-popup-container, .ytm-app-install-banner,
        [class*="install-banner"], [class*="app-banner"],
        .mealbar-promo-renderer, .companion-ad-container,
        ytm-item-section-renderer, .related-video,
        ytm-compact-video-renderer, #related,
        .watch-below-the-player, ytm-video-description-header-renderer,
        ytm-engagement-panel-section-list-renderer,
        ytm-comment-section-renderer, .slim-video-metadata-section,
        ytm-slim-video-metadata-section-renderer,
        .related-chips-slot-wrapper, .ytm-autonav-bar,
        .c3-companion-top, [class*="topbar"] {
          display: none !important; height: 0 !important; 
          max-height: 0 !important; overflow: hidden !important;
        }
        
        /* Make the body only show the player, no scroll */
        body > *:not(#player):not(.player-container):not(#player-container-id):not(ytm-app):not(#app) {
          display: none !important;
        }
      `;
      document.head.appendChild(style);
      
      var attempts = 0;
      var cleanup = setInterval(function() {
        attempts++;
        
        // Remove non-player elements from DOM
        var toRemove = [
          'ytm-mobile-topbar-renderer', 'header', '#masthead-container',
          'ytm-pivot-bar-renderer', '.pivot-bar', '#bottom-bar',
          'ytm-popup-container', '.ytm-app-install-banner',
          '.mealbar-promo-renderer', '.companion-ad-container',
          'ytm-video-description-header-renderer',
          'ytm-engagement-panel-section-list-renderer',
          'ytm-comment-section-renderer',
          'ytm-slim-video-metadata-section-renderer',
          '.related-chips-slot-wrapper',
          'ytm-item-section-renderer',
          '.watch-below-the-player'
        ];
        toRemove.forEach(function(sel) {
          document.querySelectorAll(sel).forEach(function(el) { el.remove(); });
        });
        
        // Dismiss popups
        document.querySelectorAll('[aria-label="Dismiss"], [aria-label="Descartar"], .dismiss-button, .close-button').forEach(function(btn) { 
          try { btn.click(); } catch(e) {} 
        });
        
        // After 15 seconds, slow down cleanup
        if (attempts > 30) {
          clearInterval(cleanup);
          setInterval(function() {
            document.querySelectorAll('ytm-popup-container, .ytm-app-install-banner, [class*="install-banner"]').forEach(function(el) { el.remove(); });
          }, 2000);
        }
      }, 500);
    })();
  ''';

  /// Load YouTube mobile page directly - most reliable for live streams
  void _loadYoutubeDirect() {
    String url = widget.youtubeUrl.trim();
    url = url.replaceAll('www.youtube.com', 'm.youtube.com');
    if (!url.contains('m.youtube.com')) {
      final videoId = _extractVideoId(url);
      if (videoId != null) {
        url = 'https://m.youtube.com/watch?v=$videoId';
      }
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _controller.runJavaScript(_cleanupScript);
          },
          onWebResourceError: (error) {
            debugPrint('YouTube Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            final reqUrl = request.url;
            if (reqUrl.contains('play.google.com') || 
                reqUrl.contains('apps.apple.com') ||
                reqUrl.contains('intent://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    if (mounted) setState(() {});
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  onPressed: _toggleFullScreen,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Recargar',
            onPressed: _loadYoutubeDirect,
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.liveRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text('EN VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video area - fixed 16:9 aspect ratio
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.red),
                            SizedBox(height: 12),
                            Text('Cargando transmisión...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // App's own UI below the video
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.liveRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: AppColors.liveRed),
                              SizedBox(width: 6),
                              Text('Transmisión en Vivo',
                                  style: TextStyle(color: AppColors.liveRed, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_fill, size: 14, color: Colors.red),
                              SizedBox(width: 6),
                              Text('YouTube', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fullscreen button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleFullScreen,
                        icon: const Icon(Icons.fullscreen, size: 22),
                        label: const Text('Pantalla Completa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.white54),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Toca el video para reproducir. Usa pantalla completa para una mejor experiencia.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
