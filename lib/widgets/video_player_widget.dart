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
  bool _showControls = false;
  bool _muted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _controller.value.isPlaying) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      _controller.play();
      _scheduleHide();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0.0 : 1.0);
  }

  void _seekRelative(int seconds) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final t = pos + Duration(seconds: seconds);
    _controller.seekTo(t < Duration.zero ? Duration.zero : t > dur ? dur : t);
    _scheduleHide();
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
          muted: _muted,
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _controller.value.isPlaying;
    final dur = _initialized ? _controller.value.duration : Duration.zero;
    final pos = _initialized ? _controller.value.position : Duration.zero;
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final aspectRatio = _initialized
        ? _controller.value.aspectRatio.clamp(0.5, 16 / 9)
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: Colors.black,
          child: _initialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Video ────────────────────────────────────────────
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),

                    // ── Gesture layer: tap + double-tap seek ─────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _onTap,
                            onDoubleTap: () => _seekRelative(-10),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _onTap,
                            onDoubleTap: () => _seekRelative(10),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),

                    // ── Controls overlay (shows on tap) ──────────────────
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Stack(
                          children: [
                            // Top gradient
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 64,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Bottom gradient
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 72,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black87,
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Top row: remaining time + mute + fullscreen
                            Positioned(
                              top: 8,
                              left: 10,
                              right: 10,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _Badge(text: _fmt(dur - pos)),
                                  Row(
                                    children: [
                                      _ControlBtn(
                                        icon: _muted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        onTap: _toggleMute,
                                      ),
                                      const SizedBox(width: 6),
                                      _ControlBtn(
                                        icon: Icons.fullscreen_rounded,
                                        onTap: _openFullscreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Center: play / pause
                            Center(
                              child: GestureDetector(
                                onTap: _togglePlay,
                                child: _CirclePlayBtn(
                                    isPlaying: isPlaying, size: 54),
                              ),
                            ),

                            // Bottom: time labels + scrubber
                            Positioned(
                              bottom: 8,
                              left: 10,
                              right: 10,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fmt(pos),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _fmt(dur),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _InlineScrubber(
                                    controller: _controller,
                                    progress: progress,
                                    duration: dur,
                                    onSeekStart: () => _hideTimer?.cancel(),
                                    onSeekEnd: _scheduleHide,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Always-visible play button when paused + hidden controls
                    if (!_showControls && !isPlaying)
                      Center(
                        child: GestureDetector(
                          onTap: _onTap,
                          child:
                              _CirclePlayBtn(isPlaying: false, size: 54),
                        ),
                      ),

                    // ── Always-visible thin progress bar at bottom ───────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                            Colors.white70),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
        ),
      ),
    );
  }
}

// ── Inline scrubber with drag support ────────────────────────────────────────

class _InlineScrubber extends StatefulWidget {
  final VideoPlayerController controller;
  final double progress;
  final Duration duration;
  final VoidCallback onSeekStart;
  final VoidCallback onSeekEnd;

  const _InlineScrubber({
    required this.controller,
    required this.progress,
    required this.duration,
    required this.onSeekStart,
    required this.onSeekEnd,
  });

  @override
  State<_InlineScrubber> createState() => _InlineScrubberState();
}

class _InlineScrubberState extends State<_InlineScrubber> {
  bool _dragging = false;
  double _dragProgress = 0.0;

  double get _displayProgress =>
      _dragging ? _dragProgress : widget.progress;

  void _seek(double localDx, double totalWidth) {
    final frac = (localDx / totalWidth).clamp(0.0, 1.0);
    widget.controller.seekTo(widget.duration * frac);
    setState(() => _dragProgress = frac);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final w = context.size?.width ?? 1;
        _seek(d.localPosition.dx, w);
        widget.onSeekEnd();
      },
      onHorizontalDragStart: (d) {
        _dragging = true;
        setState(() => _dragProgress = widget.progress);
        widget.onSeekStart();
      },
      onHorizontalDragUpdate: (d) {
        final w = context.size?.width ?? 1;
        _seek(d.localPosition.dx, w);
      },
      onHorizontalDragEnd: (_) {
        _dragging = false;
        widget.onSeekEnd();
      },
      child: SizedBox(
        height: 20,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track
            Container(
              height: _dragging ? 4 : 3,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Played
            FractionallySizedBox(
              widthFactor: _displayProgress,
              child: Container(
                height: _dragging ? 4 : 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            if (_dragging)
              FractionallySizedBox(
                widthFactor: _displayProgress,
                alignment: Alignment.centerLeft,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small widgets ────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _CirclePlayBtn extends StatelessWidget {
  final bool isPlaying;
  final double size;
  const _CirclePlayBtn({required this.isPlaying, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}

// ── Fullscreen video page ─────────────────────────────────────────────────────

class _FullscreenVideoPage extends StatefulWidget {
  final String videoUrl;
  final Duration startPosition;
  final bool autoPlay;
  final bool muted;

  const _FullscreenVideoPage({
    required this.videoUrl,
    required this.startPosition,
    required this.autoPlay,
    required this.muted,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  bool _muted = false;
  bool _dragging = false;
  Timer? _hideTimer;

  // For swipe-down-to-close
  double _dragOffsetY = 0;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.seekTo(widget.startPosition);
        _controller.setVolume(_muted ? 0.0 : 1.0);
        if (widget.autoPlay) _controller.play();
        setState(() => _initialized = true);
        _scheduleHide();
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setOrientation();
  }

  void _setOrientation() {
    final isLandscape = _initialized &&
        _controller.value.aspectRatio > 1.0;
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    // Portrait videos stay in portrait
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
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      _controller.play();
      _scheduleHide();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0.0 : 1.0);
  }

  void _skip(int seconds) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final t = pos + Duration(seconds: seconds);
    _controller.seekTo(t < Duration.zero ? Duration.zero : t > dur ? dur : t);
    _scheduleHide();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dur = _initialized ? _controller.value.duration : Duration.zero;
    final pos = _initialized ? _controller.value.position : Duration.zero;
    final isPlaying = _controller.value.isPlaying;
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          // Swipe down to close
          onVerticalDragUpdate: (d) {
            setState(() => _dragOffsetY += d.delta.dy);
          },
          onVerticalDragEnd: (d) {
            if (_dragOffsetY > 80 ||
                (d.primaryVelocity ?? 0) > 600) {
              Navigator.pop(context);
            } else {
              setState(() => _dragOffsetY = 0);
            }
          },
          child: Transform.translate(
            offset: Offset(0, _dragOffsetY.clamp(0.0, double.infinity)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Video ──────────────────────────────────────────────
                Center(
                  child: _initialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                ),

                // ── Controls overlay ───────────────────────────────────
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
                            stops: [0.0, 0.3, 0.65, 1.0],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top: close + mute
                            Positioned(
                              top:
                                  MediaQuery.of(context).padding.top + 8,
                              left: 14,
                              right: 14,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pop(context),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _toggleMute,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _muted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center: skip back, play/pause, skip forward
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SkipBtn(
                                    icon: Icons.replay_10_rounded,
                                    label: '−10s',
                                    onTap: () => _skip(-10),
                                  ),
                                  const SizedBox(width: 36),
                                  GestureDetector(
                                    onTap: _togglePlay,
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.45),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 1.5),
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                  _SkipBtn(
                                    icon: Icons.forward_10_rounded,
                                    label: '+10s',
                                    onTap: () => _skip(10),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom: time + scrubber
                            Positioned(
                              bottom: MediaQuery.of(context)
                                      .padding
                                      .bottom +
                                  16,
                              left: 16,
                              right: 16,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fmt(pos),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _fmt(dur),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _FullScrubber(
                                    controller: _controller,
                                    progress: progress,
                                    duration: dur,
                                    onSeekStart: () {
                                      _dragging = true;
                                      _hideTimer?.cancel();
                                    },
                                    onSeekEnd: () {
                                      _dragging = false;
                                      _scheduleHide();
                                    },
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
      ),
    );
  }
}

// ── Fullscreen scrubber ───────────────────────────────────────────────────────

class _FullScrubber extends StatefulWidget {
  final VideoPlayerController controller;
  final double progress;
  final Duration duration;
  final VoidCallback onSeekStart;
  final VoidCallback onSeekEnd;

  const _FullScrubber({
    required this.controller,
    required this.progress,
    required this.duration,
    required this.onSeekStart,
    required this.onSeekEnd,
  });

  @override
  State<_FullScrubber> createState() => _FullScrubberState();
}

class _FullScrubberState extends State<_FullScrubber> {
  bool _dragging = false;
  double _dragProgress = 0.0;

  double get _p => _dragging ? _dragProgress : widget.progress;

  void _seek(double dx, double width) {
    final frac = (dx / width).clamp(0.0, 1.0);
    widget.controller.seekTo(widget.duration * frac);
    setState(() => _dragProgress = frac);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final w = context.size?.width ?? 1;
        _seek(d.localPosition.dx, w);
        widget.onSeekEnd();
      },
      onHorizontalDragStart: (d) {
        _dragging = true;
        setState(() => _dragProgress = widget.progress);
        widget.onSeekStart();
      },
      onHorizontalDragUpdate: (d) {
        final w = context.size?.width ?? 1;
        _seek(d.localPosition.dx, w);
      },
      onHorizontalDragEnd: (_) {
        _dragging = false;
        widget.onSeekEnd();
      },
      child: SizedBox(
        height: 24,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: _dragging ? 5 : 3,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: _p,
              child: Container(
                height: _dragging ? 5 : 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: _p,
              alignment: Alignment.centerLeft,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: _dragging ? 16 : 12,
                  height: _dragging ? 16 : 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skip button (fullscreen) ──────────────────────────────────────────────────

class _SkipBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SkipBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
