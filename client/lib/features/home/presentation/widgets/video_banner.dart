// lib/features/home/presentation/widgets/video_banner.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBanner extends StatefulWidget {
  final String assetPath;
  final double aspectRatio;
  final bool fullWidth;

  const VideoBanner({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 8,
    this.fullWidth = false,
  });

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      await _controller.play();

      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (e) {
      debugPrint('VideoBanner error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          widget.fullWidth ? BorderRadius.zero : BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: widget.fullWidth ? (16 / 8) : widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video surface — renders black until first frame, then plays
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            // Subtle gradient overlay for polish
            if (_ready)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            // Keep a clean black background until the video is ready.
            if (!_ready) Container(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
