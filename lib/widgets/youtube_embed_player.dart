import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Official YouTube IFrame embed with native YouTube controls & branding.
/// No custom Flutter play/seek overlays on the player surface.
class YoutubeEmbedPlayer extends StatefulWidget {
  final String videoId;
  final double aspectRatio;

  const YoutubeEmbedPlayer({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    // HTML iframe keeps YouTube chrome (controls, logo, title).
    // baseUrl helps YouTube associate the embed with a proper origin.
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<style>
  html, body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
  iframe { position:absolute; inset:0; width:100%; height:100%; border:0; }
</style>
</head>
<body>
  <iframe
    src="https://www.youtube.com/embed/${widget.videoId}?playsinline=1&rel=0&controls=1&fs=1&modestbranding=0&iv_load_policy=3"
    title="YouTube video"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
    allowfullscreen
    referrerpolicy="strict-origin-when-cross-origin">
  </iframe>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _loading = true; _failed = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() { _loading = false; _failed = true; });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Keep embed navigations inside the WebView
            if (url.contains('youtube.com/embed') ||
                url.contains('youtube-nocookie.com/embed') ||
                url.startsWith('about:') ||
                url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            // Open YouTube watch / channel links externally
            if (url.contains('youtube.com') || url.contains('youtu.be')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        html,
        baseUrl: 'https://www.youtube.com',
      );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_failed) WebViewWidget(controller: _controller),
            if (_failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Player load nahi hua. YouTube app mein kholein.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      watchOnYouTubeButton(widget.videoId),
                    ],
                  ),
                ),
              ),
            if (_loading && !_failed)
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> openVideoOnYouTube(String videoId) async {
  final appUri = Uri.parse('vnd.youtube:$videoId');
  final webUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
  try {
    final launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

Widget watchOnYouTubeButton(String videoId) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => openVideoOnYouTube(videoId),
      icon: const Icon(Icons.open_in_new_rounded, color: AppColors.gold),
      label: Text(
        'Watch on YouTube',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.gold),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}
