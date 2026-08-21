import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A secure, self-contained YouTube video player that plays videos inline
/// and prevents users from being redirected outside the Kivo Super App.
class SandboxedVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;

  const SandboxedVideoPlayer({
    Key? key,
    required this.videoId,
    this.autoPlay = false,
  }) : super(key: key);

  @override
  State<SandboxedVideoPlayer> createState() => _SandboxedVideoPlayerState();
}

class _SandboxedVideoPlayerState extends State<SandboxedVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _isPlaying = false;

  void _startPlayback() {
    try {
      final controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false, // Keep locked inline inside Kivo layout
          mute: false,
          loop: false,
          strictRelatedVideos: true, // Prevent external channel redirects
          playsInline: true, // Mandatory: prevents native browser takeover
          enableJavaScript: true,
        ),
      );
      setState(() {
        _isPlaying = true;
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Error starting YouTube playback: $e');
    }
  }

  @override
  void dispose() {
    try {
      _controller?.close();
    } catch (e) {
      debugPrint('Error disposing YouTube controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isPlaying && _controller != null
              ? YoutubePlayer(
                  controller: _controller!,
                  aspectRatio: 16 / 9,
                )
              : GestureDetector(
                  onTap: _startPlayback,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF101726),
                          child: const Center(
                            child: Icon(Icons.video_library, color: Colors.white24, size: 48),
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.black38,
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Color(0xFFFFD700), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Sandboxed In-App',
                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
