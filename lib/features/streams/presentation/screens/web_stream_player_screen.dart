import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class WebStreamPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebStreamPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebStreamPlayerScreen> createState() => _WebStreamPlayerScreenState();
}

class _WebStreamPlayerScreenState extends State<WebStreamPlayerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _resolvedUrl;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  @override
  void dispose() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  bool _isFacebookUrl(String url) {
    return url.contains('facebook.com') || url.contains('fb.watch') || url.contains('fb.gg');
  }

  bool _needsResolving(String url) {
    return url.contains('/share/v/') ||
        url.contains('/share/') ||
        url.contains('fb.watch/') ||
        url.contains('l.facebook.com/');
  }

  Future<String> _resolveFacebookShareUrl(String shareUrl) async {
    try {
      final client = http.Client();
      try {
        var currentUrl = shareUrl;
        for (int i = 0; i < 5; i++) {
          final request = http.Request('GET', Uri.parse(currentUrl));
          request.followRedirects = false;
          request.headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';
          final streamedResponse = await client.send(request);
          if (streamedResponse.statusCode >= 300 && streamedResponse.statusCode < 400) {
            final location = streamedResponse.headers['location'];
            if (location != null && location.isNotEmpty) {
              if (location.startsWith('/')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              } else {
                currentUrl = location;
              }
              continue;
            }
          }
          break;
        }
        return currentUrl;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error resolving Facebook URL: $e');
      return shareUrl;
    }
  }

  /// Normaliza la URL de Facebook para usarla con el plugin de video embebido
  String _normalizeFacebookUrl(String url) {
    String cleanUrl = url.replaceAll('m.facebook.com', 'www.facebook.com');
    // Quitar query params que puedan interferir
    try {
      final uri = Uri.parse(cleanUrl);
      cleanUrl = '${uri.scheme}://${uri.host}${uri.path}';
    } catch (_) {}
    // Asegurar que tenga www
    if (cleanUrl.contains('facebook.com') && !cleanUrl.contains('www.facebook.com')) {
      cleanUrl = cleanUrl.replaceFirst('facebook.com', 'www.facebook.com');
    }
    return cleanUrl;
  }

  Future<void> _initializeStream() async {
    setState(() {
      _isLoading = true;
    });

    String urlToUse = widget.url.trim();

    if (_isFacebookUrl(urlToUse)) {
      if (_needsResolving(urlToUse)) {
        debugPrint('Resolving Facebook share URL: $urlToUse');
        urlToUse = await _resolveFacebookShareUrl(urlToUse);
        debugPrint('Resolved to: $urlToUse');
      }
      _resolvedUrl = urlToUse;
      _loadFacebookEmbedded(urlToUse);
    } else {
      _resolvedUrl = urlToUse;
      _loadDirectWebView(urlToUse);
    }
  }

  /// Carga el video de Facebook usando el Facebook Video Plugin (embed oficial)
  /// Este método NO requiere login porque usa la API oficial de embebido de Facebook
  void _loadFacebookEmbedded(String url) {
    final normalizedUrl = _normalizeFacebookUrl(url);
    final encodedUrl = Uri.encodeComponent(normalizedUrl);

    // HTML que usa el Facebook Video Plugin - forma oficial de embeber videos de FB
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
      background: #000;
      overflow: hidden;
    }
    .video-container {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #000;
    }
    .video-container iframe {
      width: 100%;
      height: 100%;
      border: none;
    }
    .fb-video {
      width: 100% !important;
    }
    .fb-video > span {
      width: 100% !important;
    }
    .fb-video iframe {
      width: 100% !important;
    }
    /* Fallback message */
    .fallback {
      display: none;
      color: #fff;
      text-align: center;
      padding: 20px;
      font-family: -apple-system, sans-serif;
    }
    .fallback h3 {
      margin-bottom: 10px;
      font-size: 16px;
    }
    .fallback p {
      font-size: 13px;
      color: #aaa;
      margin-bottom: 15px;
    }
    .fallback a {
      display: inline-block;
      padding: 10px 24px;
      background: #1877F2;
      color: #fff;
      text-decoration: none;
      border-radius: 8px;
      font-weight: bold;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://www.facebook.com/plugins/video.php?href=$encodedUrl&show_text=false&autoplay=true&allowFullScreen=true&mute=false"
      style="width:100%;height:100%;border:none;overflow:hidden"
      scrolling="no"
      frameborder="0"
      allowfullscreen="true"
      allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share; fullscreen"
      allowFullScreen="true">
    </iframe>
  </div>
  <div class="fallback" id="fallback">
    <h3>📺 Transmisión de Facebook</h3>
    <p>Si el video no carga, ábrelo directamente en Facebook</p>
    <a href="$normalizedUrl" target="_blank">Abrir en Facebook</a>
  </div>
  <script>
    // Si el iframe falla por alguna razón, mostrar fallback después de 10 segundos
    setTimeout(function() {
      var iframe = document.querySelector('iframe');
      if (iframe) {
        try {
          // Check if iframe loaded (cross-origin will throw)
          var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
          if (!iframeDoc || iframeDoc.body.innerHTML.length < 100) {
            document.querySelector('.video-container').style.display = 'none';
            document.getElementById('fallback').style.display = 'block';
          }
        } catch(e) {
          // Cross-origin - iframe loaded something (which is good)
        }
      }
    }, 10000);
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
            debugPrint('FB Embed Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            final reqUrl = request.url;
            // Permitir navegación al plugin de Facebook y al video
            if (reqUrl.contains('facebook.com/plugins/') ||
                reqUrl.contains('facebook.com/v') ||
                reqUrl.contains('fbcdn.net') ||
                reqUrl.contains('fbsbx.com') ||
                reqUrl.startsWith('about:') ||
                reqUrl.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            // Bloquear redirects a login
            if (reqUrl.contains('/login') || reqUrl.contains('login.php')) {
              return NavigationDecision.prevent;
            }
            // Bloquear app stores
            if (reqUrl.contains('play.google.com') ||
                reqUrl.contains('apps.apple.com') ||
                reqUrl.contains('intent://')) {
              return NavigationDecision.prevent;
            }
            // Permitir todo lo demás dentro del iframe
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html);

    if (mounted) setState(() {});
  }

  /// Direct web loading for non-Facebook URLs
  void _loadDirectWebView(String url) {
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
            debugPrint('Web Error: ${error.description}');
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

  Future<void> _openInExternalApp() async {
    final url = _resolvedUrl ?? widget.url;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    final isFb = _isFacebookUrl(widget.url);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Recargar',
            onPressed: _initializeStream,
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
          // Video area - 16:9 ratio
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
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: isFb ? const Color(0xFF1877F2) : AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            const Text('Conectando con la transmisión...',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // App UI below video
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
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                        if (isFb)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.facebook, size: 14, color: Color(0xFF1877F2)),
                                SizedBox(width: 6),
                                Text('Facebook Live',
                                    style: TextStyle(color: Color(0xFF1877F2), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fullscreen
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleFullScreen,
                        icon: const Icon(Icons.fullscreen, size: 22),
                        label: const Text('Pantalla Completa',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Open externally
                    if (isFb)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openInExternalApp,
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: const Text('Abrir en Facebook', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1877F2),
                            side: const BorderSide(color: Color(0xFF1877F2)),
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
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.white54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isFb
                                  ? 'Toca ▶ para reproducir. Si no carga, usa "Abrir en Facebook".'
                                  : 'Toca el video para reproducir.',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
