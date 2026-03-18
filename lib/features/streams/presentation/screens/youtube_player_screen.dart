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
    _initController();
  }

  @override
  void dispose() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  /// Extract YouTube video ID from URL
  String? _extractVideoId(String url) {
    // Handle various YouTube URL formats
    final patterns = [
      RegExp(r'(?:youtube\.com\/live\/)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtu\.be\/)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]+)'),
      RegExp(r'(?:youtube\.com\/v\/)([a-zA-Z0-9_-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  void _initController() {
    final videoId = _extractVideoId(widget.youtubeUrl);
    
    // Build an HTML page that embeds YouTube using an iframe
    // with special parameters to support live streams
    final embedUrl = videoId != null
        ? 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1&fs=1&enablejsapi=1'
        : widget.youtubeUrl;

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%;
      height: 100%;
      background-color: #000;
      overflow: hidden;
    }
    .container {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: none;
      position: absolute;
      top: 0;
      left: 0;
    }
    .fallback {
      display: none;
      color: #fff;
      text-align: center;
      padding: 20px;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    }
    .fallback h3 { margin-bottom: 10px; font-size: 16px; }
    .fallback p { font-size: 13px; color: #aaa; margin-bottom: 15px; }
    .fallback button {
      background: #FF0000;
      color: #fff;
      padding: 12px 24px;
      border-radius: 8px;
      border: none;
      font-weight: bold;
      font-size: 14px;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="container">
    <iframe 
      id="ytplayer"
      src="$embedUrl"
      allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
      allowfullscreen
      frameborder="0">
    </iframe>
    <div id="fallback" class="fallback">
      <h3>📺 Transmisión de YouTube</h3>
      <p>Si el video no se reproduce, ábrelo directamente en YouTube</p>
      <button onclick="window.open('${widget.youtubeUrl}', '_blank')">Abrir en YouTube</button>
    </div>
  </div>
  <script>
    // Monitor iframe for errors - if embed fails, show fallback after timeout
    var iframe = document.getElementById('ytplayer');
    var fallback = document.getElementById('fallback');
    
    // Check if iframe loaded correctly after 6 seconds
    setTimeout(function() {
      try {
        // postMessage to check if the player is responsive
        iframe.contentWindow.postMessage('{"event":"listening"}', '*');
      } catch(e) {
        // If we can't communicate with the iframe, show fallback
        fallback.style.display = 'block';
        iframe.style.display = 'none';
      }
    }, 6000);
  </script>
</body>
</html>
''';

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
          },
          onWebResourceError: (error) {
            debugPrint('YouTube WebView Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Allow YouTube and Google domains
            if (url.contains('youtube.com') ||
                url.contains('youtu.be') ||
                url.contains('googlevideo.com') ||
                url.contains('google.com') ||
                url.contains('gstatic.com') ||
                url.contains('ytimg.com') ||
                url.startsWith('data:') ||
                url.startsWith('about:') ||
                url.startsWith('blob:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html);
  }

  void _loadDirectYoutube() {
    // Fallback: load YouTube directly as a webpage
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
          },
          onWebResourceError: (error) {
            debugPrint('YouTube Direct Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.youtubeUrl));

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Recargar embed',
            onPressed: () {
              _initController();
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'embed') {
                _initController();
                setState(() {});
              } else if (value == 'direct') {
                _loadDirectYoutube();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'embed',
                child: Row(
                  children: [
                    Icon(Icons.smart_display, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reproductor Embed', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'direct',
                child: Row(
                  children: [
                    Icon(Icons.web, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Abrir YouTube Web', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
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
          // Video player area
          Expanded(
            flex: 3,
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
                          SizedBox(height: 16),
                          Text(
                            'Cargando transmisión...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom info section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.live_tv, size: 14, color: AppColors.liveRed),
                          SizedBox(width: 4),
                          Text(
                            'Transmisión en Vivo',
                            style: TextStyle(color: AppColors.liveRed, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('YouTube', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleFullScreen,
                        icon: const Icon(Icons.fullscreen, size: 20),
                        label: const Text('Pantalla Completa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _loadDirectYoutube,
                      icon: const Icon(Icons.web, size: 20),
                      label: const Text('Web'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
