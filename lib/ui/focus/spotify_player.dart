import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyPlayer extends StatefulWidget {
  final String webUrl;

  const SpotifyPlayer({super.key, required this.webUrl});

  @override
  State<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends State<SpotifyPlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant SpotifyPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.webUrl != oldWidget.webUrl) {
      _loadUrl();
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent);
    _loadUrl();
  }

  void _loadUrl() {
    String embedUrl = widget.webUrl;
    
    // Convert https://open.spotify.com/playlist/... to https://open.spotify.com/embed/playlist/...
    if (embedUrl.contains('open.spotify.com/playlist/')) {
      embedUrl = embedUrl.replaceFirst('open.spotify.com/playlist/', 'open.spotify.com/embed/playlist/');
    } else if (embedUrl.contains('open.spotify.com/track/')) {
      embedUrl = embedUrl.replaceFirst('open.spotify.com/track/', 'open.spotify.com/embed/track/');
    } else if (embedUrl.contains('open.spotify.com/album/')) {
      embedUrl = embedUrl.replaceFirst('open.spotify.com/album/', 'open.spotify.com/embed/album/');
    }

    final uri = Uri.parse(embedUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['utm_source'] = 'generator';
    
    _controller.loadRequest(uri.replace(queryParameters: params));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152, // Standard height for Spotify embed iframe
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
