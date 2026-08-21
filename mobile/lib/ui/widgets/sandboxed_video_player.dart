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
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false, // Keep locked inline inside Kivo layout
        mute: false,
        loop: false,
        strictRelatedVideos: true, // Prevent unrelated external channel videos
        playsInline: true, // Mandatory: prevents native browser takeover
        enableJavaScript: true,
      ),
    );
    _controller.loadVideoById(videoId: widget.videoId);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
}
