import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });

    _controller.addListener(() {
      if (mounted) setState(() => _playing = _controller.value.isPlaying);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _openFullscreen() {
    final wasPlaying = _controller.value.isPlaying;
    _controller.pause();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenVideoPage(
          videoUrl: widget.videoUrl,
          startPosition: _controller.value.position,
          autoPlay: wasPlaying,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 220,
            color: Colors.black,
            child: _initialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      // Tap anywhere to toggle play/pause
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePlay,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // Play button overlay (visual only)
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _playing ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.sunglow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: AppColors.darkPurple, size: 32),
                          ),
                        ),
                      ),
                      // Progress bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.sunglow,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.sunglow, strokeWidth: 2),
                  ),
          ),
        ),
        // Fullscreen button always on top, outside the tap-to-play zone
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _openFullscreen,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fullscreen_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fullscreen video page ──────────────────────────────────────────────────────

class _FullscreenVideoPage extends StatefulWidget {
  final String videoUrl;
  final Duration startPosition;
  final bool autoPlay;

  const _FullscreenVideoPage({
    required this.videoUrl,
    required this.startPosition,
    required this.autoPlay,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          _controller.seekTo(widget.startPosition);
          if (widget.autoPlay) _controller.play();
          setState(() => _initialized = true);
        }
      });

    _controller.addListener(() {
      if (mounted) setState(() => _playing = _controller.value.isPlaying);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_initialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.sunglow, strokeWidth: 2),
                ),
              if (_initialized)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    color: Colors.black26,
                    child: Stack(
                      children: [
                        // Play/Pause center button
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.sunglow,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.darkPurple,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        // Close button top-left
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen_exit_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                        // Progress bar bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            colors: const VideoProgressColors(
                              playedColor: AppColors.sunglow,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.black26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
