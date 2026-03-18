import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
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
  bool _hasError = false;
  String? _resolvedUrl;
  bool _isFullScreen = false;
  String _currentMode = 'direct'; // direct, plugin, sdk

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

  /// Resolves Facebook share/redirect links to final URL
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

  String _normalizeFacebookUrl(String url) {
    String cleanUrl = url.replaceAll('m.facebook.com', 'www.facebook.com');
    try {
      final uri = Uri.parse(cleanUrl);
      cleanUrl = '${uri.scheme}://${uri.host}${uri.path}';
    } catch (_) {}
    return cleanUrl;
  }

  Future<void> _initializeStream() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    String urlToUse = widget.url.trim();

    if (_isFacebookUrl(urlToUse)) {
      // Resolve share links first
      if (_needsResolving(urlToUse)) {
        debugPrint('Resolving Facebook share URL: $urlToUse');
        urlToUse = await _resolveFacebookShareUrl(urlToUse);
        debugPrint('Resolved to: $urlToUse');
      }
      _resolvedUrl = urlToUse;

      // DEFAULT: Load Facebook page directly in WebView (most reliable)
      _loadDirectWebView(urlToUse);
      _currentMode = 'direct';
    } else {
      _resolvedUrl = urlToUse;
      _loadDirectWebView(urlToUse);
      _currentMode = 'direct';
    }
  }

  /// MÉTODO PRINCIPAL: Carga la página de Facebook directamente como página web
  /// Este es el método más confiable para Facebook Lives
  void _loadDirectWebView(String url) {
    // For Facebook, use the mobile URL for a cleaner experience
    String loadUrl = url;
    if (_isFacebookUrl(url)) {
      // Convert to mobile version for better video experience on phones
      loadUrl = url.replaceAll('www.facebook.com', 'm.facebook.com');
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
            // For Facebook: inject JS to auto-click play and hide headers
            if (_isFacebookUrl(url)) {
              _controller.runJavaScript('''
                // Hide Facebook navigation bars for cleaner view
                try {
                  var header = document.querySelector('[data-sigil="MTopBlueBarHeader"]');
                  if (header) header.style.display = 'none';
                  var footer = document.querySelector('#page_footer');
                  if (footer) footer.style.display = 'none';
                  // Try to click play button if visible
                  var playBtn = document.querySelector('[data-sigil="playInlineVideo"]');
                  if (playBtn) playBtn.click();
                } catch(e) {}
              ''');
            }
          },
          onWebResourceError: (error) {
            debugPrint('Web Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loadUrl));

    _currentMode = 'direct';
    if (mounted) setState(() {});
  }

  /// Facebook Plugin embed (video.php iframe)
  void _loadFacebookPluginEmbed(String videoUrl) {
    final normalizedUrl = _normalizeFacebookUrl(videoUrl);
    final encodedUrl = Uri.encodeComponent(normalizedUrl);
    final pluginUrl =
        'https://www.facebook.com/plugins/video.php?href=$encodedUrl&show_text=false&t=0&autoplay=true&mute=false';

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
            debugPrint('Web Error (plugin): ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(pluginUrl));

    _currentMode = 'plugin';
    if (mounted) setState(() {});
  }

  /// Facebook SDK embed (fb-video div)
  void _loadFacebookSDKEmbed(String videoUrl) {
    final normalizedUrl = _normalizeFacebookUrl(videoUrl);

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .container { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
    .fb-video { width: 100% !important; }
    .fb-video > span, .fb-video > span > iframe { width: 100% !important; min-height: 250px; }
    .fallback { display: none; color: #fff; text-align: center; padding: 20px; font-family: sans-serif; }
    .fallback h3 { margin-bottom: 10px; }
    .fallback a { display: inline-block; background: #1877f2; color: #fff; padding: 10px 24px; border-radius: 8px; text-decoration: none; font-weight: bold; }
    .loading { color: #fff; text-align: center; font-family: sans-serif; }
    .spinner { width: 30px; height: 30px; border: 3px solid rgba(255,255,255,0.2); border-top: 3px solid #1877f2; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 12px; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="container">
    <div id="loading" class="loading"><div class="spinner"></div><p>Cargando...</p></div>
    <div id="fb-root"></div>
    <div class="fb-video" data-href="$normalizedUrl" data-width="auto" data-allowfullscreen="true" data-autoplay="true" data-show-text="false"></div>
    <div id="fallback" class="fallback">
      <h3>📺 Transmisión en Vivo</h3>
      <p style="font-size:13px;color:#aaa;margin-bottom:15px">No se pudo cargar el embed</p>
      <a href="$normalizedUrl" target="_blank">Abrir en Facebook</a>
    </div>
  </div>
  <script>
    (function(d, s, id) {
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) return;
      js = d.createElement(s); js.id = id;
      js.src = "https://connect.facebook.net/es_LA/sdk.js#xfbml=1&version=v21.0";
      js.onload = function() { document.getElementById('loading').style.display = 'none'; };
      js.onerror = function() {
        document.getElementById('loading').style.display = 'none';
        document.getElementById('fallback').style.display = 'block';
      };
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));
    setTimeout(function() {
      var fbVideo = document.querySelector('.fb-video > span');
      if (!fbVideo || fbVideo.children.length === 0) {
        document.getElementById('loading').style.display = 'none';
        document.getElementById('fallback').style.display = 'block';
      }
    }, 8000);
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
            debugPrint('Web Error (SDK): ${error.description}');
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html);

    _currentMode = 'sdk';
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

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'direct': return 'Página Web';
      case 'plugin': return 'Plugin Embed';
      case 'sdk': return 'SDK Embed';
      default: return mode;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Recargar',
            onPressed: () {
              final url = _resolvedUrl ?? widget.url;
              switch (_currentMode) {
                case 'direct':
                  _loadDirectWebView(url);
                  break;
                case 'plugin':
                  _loadFacebookPluginEmbed(url);
                  break;
                case 'sdk':
                  _loadFacebookSDKEmbed(url);
                  break;
              }
            },
          ),
          if (isFb)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'Cambiar modo de reproducción',
              onSelected: (value) {
                final url = _resolvedUrl ?? widget.url;
                switch (value) {
                  case 'direct':
                    _loadDirectWebView(url);
                    break;
                  case 'plugin':
                    _loadFacebookPluginEmbed(url);
                    break;
                  case 'sdk':
                    _loadFacebookSDKEmbed(url);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'direct',
                  child: Row(
                    children: [
                      Icon(Icons.web, size: 18, color: _currentMode == 'direct' ? AppColors.liveGreen : Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Página Web (Recomendado)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _currentMode == 'direct' ? FontWeight.bold : FontWeight.normal,
                          color: _currentMode == 'direct' ? AppColors.liveGreen : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'plugin',
                  child: Row(
                    children: [
                      Icon(Icons.video_library, size: 18, color: _currentMode == 'plugin' ? AppColors.liveGreen : Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Plugin Embed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _currentMode == 'plugin' ? FontWeight.bold : FontWeight.normal,
                          color: _currentMode == 'plugin' ? AppColors.liveGreen : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sdk',
                  child: Row(
                    children: [
                      Icon(Icons.smart_display, size: 18, color: _currentMode == 'sdk' ? AppColors.liveGreen : Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'SDK Embed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _currentMode == 'sdk' ? FontWeight.bold : FontWeight.normal,
                          color: _currentMode == 'sdk' ? AppColors.liveGreen : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // Live badge
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
                if (_hasError)
                  _buildErrorWidget()
                else
                  WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: isFb ? const Color(0xFF1877F2) : AppColors.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Conectando con la transmisión...',
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                          Text('Transmisión en Vivo',
                              style: TextStyle(color: AppColors.liveRed, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isFb)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.facebook, size: 14, color: Color(0xFF1877F2)),
                            SizedBox(width: 4),
                            Text('Facebook Live',
                                style: TextStyle(color: Color(0xFF1877F2), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getModeLabel(_currentMode),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
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
                    if (isFb) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          final url = _resolvedUrl ?? widget.url;
                          if (_currentMode == 'direct') {
                            _loadFacebookPluginEmbed(url);
                          } else {
                            _loadDirectWebView(url);
                          }
                        },
                        icon: Icon(_currentMode == 'direct' ? Icons.smart_display : Icons.web, size: 18),
                        label: Text(_currentMode == 'direct' ? 'Embed' : 'Web', style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar la transmisión',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeStream,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
