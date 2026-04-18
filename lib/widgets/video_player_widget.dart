import 'dart:async';
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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
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
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  void _openFullscreen() {
    final pos = _controller.value.position;
    final wasPlaying = _controller.value.isPlaying;
    _controller.pause();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenVideoPage(
          videoUrl: widget.videoUrl,
          startPosition: pos,
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
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePlay,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _playing ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: _PlayButton(size: 52),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _MiniProgressBar(controller: _controller),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.sunglow, strokeWidth: 2)),
          ),
        ),
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

// ── Mini progress bar (inline card) ──────────────────────────────────────────

class _MiniProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  const _MiniProgressBar({required this.controller});

  @override
  State<_MiniProgressBar> createState() => _MiniProgressBarState();
}

class _MiniProgressBarState extends State<_MiniProgressBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      widget.controller,
      allowScrubbing: true,
      padding: EdgeInsets.zero,
      colors: const VideoProgressColors(
        playedColor: AppColors.sunglow,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.black26,
      ),
    );
  }
}

// ── Play button widget ────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final double size;
  const _PlayButton({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.sunglow,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.play_arrow_rounded,
          color: AppColors.darkPurple, size: size * 0.6),
    );
  }
}

// ── Fullscreen video page ─────────────────────────────────────────────────────

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
  bool _showControls = true;
  Timer? _hideTimer;
  bool _dragging = false;

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
          _scheduleHide();
        }
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying && !_dragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      _controller.play();
      _scheduleHide();
    }
  }

  void _skip(int seconds) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final target = pos + Duration(seconds: seconds);
    _controller.seekTo(target.isNegative ? Duration.zero : (target > dur ? dur : target));
    _scheduleHide();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dur = _initialized ? _controller.value.duration : Duration.zero;
    final pos = _initialized ? _controller.value.position : Duration.zero;
    final isPlaying = _controller.value.isPlaying;
    final progress = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              Center(
                child: _initialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(
                        color: AppColors.sunglow, strokeWidth: 2),
              ),

              // Controls overlay
              if (_initialized)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black87,
                          ],
                          stops: [0.0, 0.25, 0.65, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Close button top-left
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fullscreen_exit_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),

                          // Center controls: -15s, play/pause, +15s
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SkipButton(
                                  icon: Icons.replay_10_rounded,
                                  label: '−15s',
                                  onTap: () => _skip(-15),
                                ),
                                const SizedBox(width: 32),
                                GestureDetector(
                                  onTap: _togglePlay,
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: const BoxDecoration(
                                      color: AppColors.sunglow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppColors.darkPurple,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                _SkipButton(
                                  icon: Icons.forward_10_rounded,
                                  label: '+15s',
                                  onTap: () => _skip(15),
                                ),
                              ],
                            ),
                          ),

                          // Bottom: time + scrubber
                          Positioned(
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Time labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(pos),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    Text(_fmt(dur),
                                        style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Custom scrubber
                                GestureDetector(
                                  onTapDown: (d) {
                                    final w = context.size?.width ?? 1;
                                    final frac = (d.localPosition.dx - 16)
                                        .clamp(0.0, w - 32) /
                                        (w - 32);
                                    _controller
                                        .seekTo(dur * frac);
                                    _scheduleHide();
                                  },
                                  onHorizontalDragStart: (_) {
                                    _dragging = true;
                                    _hideTimer?.cancel();
                                  },
                                  onHorizontalDragUpdate: (d) {
                                    final w = context.size?.width ?? 1;
                                    final frac = (d.localPosition.dx - 16)
                                        .clamp(0.0, w - 32) /
                                        (w - 32);
                                    _controller.seekTo(dur * frac);
                                  },
                                  onHorizontalDragEnd: (_) {
                                    _dragging = false;
                                    _scheduleHide();
                                  },
                                  child: _Scrubber(progress: progress.clamp(0.0, 1.0)),
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
        ),
      ),
    );
  }
}

// ── Scrubber ──────────────────────────────────────────────────────────────────

class _Scrubber extends StatelessWidget {
  final double progress;
  const _Scrubber({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sunglow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            alignment: Alignment.centerLeft,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.sunglow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skip button ───────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SkipButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
