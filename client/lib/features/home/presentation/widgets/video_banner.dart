// lib/features/home/presentation/widgets/video_banner.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

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
  late final Player _player;
  late final VideoController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      debugPrint('VideoBanner: Initializing with path ${widget.assetPath}');
      Media media;

      // On desktop Windows/Linux, extract asset to a cached temp file so
      // libmpv can read it from the filesystem.
      if (!_isWebOrMobile) {
        debugPrint('VideoBanner: Extracting asset for desktop...');
        final path = await _extractAsset(widget.assetPath);
        media = Media(path);
      } else {
        // Android / iOS / Web: media_kit handles asset:// natively.
        debugPrint('VideoBanner: Loading asset for mobile/web...');
        media = Media('asset:///${widget.assetPath}');
      }

      debugPrint('VideoBanner: Opening media...');
      await _player.open(media, play: false);
      await _player.setVolume(0);
      await _player.setPlaylistMode(PlaylistMode.loop);
      debugPrint('VideoBanner: Starting playback...');
      await _player.play();

      if (mounted) {
        debugPrint('VideoBanner: Video ready.');
        setState(() => _ready = true);
      }
    } catch (e, stack) {
      debugPrint('VideoBanner error: $e');
      debugPrint('VideoBanner stack: $stack');
    }
  }

  bool get _isWebOrMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      // kIsWeb throws on Platform access — means we're on web
      return true;
    }
  }

  /// Extracts a Flutter asset to the app support directory and returns its path.
  /// Cached on disk so extraction only happens once.
  Future<String> _extractAsset(String assetPath) async {
    final dir = await getApplicationSupportDirectory();
    final fileName = assetPath.replaceAll('/', '_').replaceAll(' ', '_');
    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  @override
  void dispose() {
    _player.dispose();
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
            Video(
              controller: _controller,
              controls: NoVideoControls,
              fit: BoxFit.cover,
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
