import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../auth/auth_wrapper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // 1. Logo fades + scales in
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // 2. Dot falls from off-screen top to resting position
  late final AnimationController _dotCtrl;

  // 3. Squash & stretch on impact
  late final AnimationController _squishCtrl;
  late final Animation<double> _squishX;
  late final Animation<double> _squishY;

  // Image dimensions (px)
  static const double _imgW = 971;
  static const double _imgH = 843;

  // Yellow dot center in the image (relative 0–1)
  static const double _dotRelX = 0.566;
  static const double _dotRelY = 0.368;
  static const double _dotBaseRadius = 22.0;

  @override
  void initState() {
    super.initState();

    // Logo: fade + subtle scale-up
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );

    // Dot fall
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // Squash & stretch (triggers right after dot lands)
    _squishCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _squishX = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.45)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.45, end: 0.92)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 0.92, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
    ]).animate(_squishCtrl);
    _squishY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.58)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.58, end: 1.08)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
    ]).animate(_squishCtrl);

    // Sequence: logo in → dot falls → squash on impact → navigate
    _logoCtrl.forward().then((_) {
      _dotCtrl.forward().then((_) => _squishCtrl.forward());
    });

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _dotCtrl.dispose();
    _squishCtrl.dispose();
    super.dispose();
  }

  /// Returns the dot's resting center in screen coordinates.
  Offset _dotRest(Size screen) {
    final cW = screen.width * 0.8;
    final cH = screen.height * 0.6;
    final s = min(cW / _imgW, cH / _imgH);
    final rW = _imgW * s;
    final rH = _imgH * s;
    final left = (screen.width - cW) / 2 + (cW - rW) / 2;
    final top = (screen.height - cH) / 2 + (cH - rH) / 2;
    return Offset(left + _dotRelX * rW, top + _dotRelY * rH);
  }

  double _dotRadius(Size screen) {
    final cW = screen.width * 0.8;
    final cH = screen.height * 0.6;
    return _dotBaseRadius * min(cW / _imgW, cH / _imgH);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final rest = _dotRest(screen);
    final r = _dotRadius(screen);

    // Dot starts from well above the screen
    final startY = -r * 2 - 60.0;

    return Scaffold(
      backgroundColor: const Color(0xFF3D0066),
      body: Stack(
        children: [
          // ── Wi logo (fades + scales in) ──────────────────────────────────
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: SizedBox(
                  width: screen.width * 0.8,
                  height: screen.height * 0.6,
                  child: Image.asset('assets/splash.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          // ── Falling yellow dot with squash & stretch ─────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_dotCtrl, _squishCtrl]),
            builder: (_, __) {
              // Gravity-style fall: accelerates, then one small rebound
              final t = _dotCtrl.value;
              final fallY = TweenSequence<double>([
                // Phase 1 — accelerating fall (gravity)
                TweenSequenceItem(
                  tween: Tween(begin: startY, end: rest.dy)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 78,
                ),
                // Phase 2 — tiny rebound up
                TweenSequenceItem(
                  tween: Tween(begin: rest.dy, end: rest.dy - r * 0.6)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 11,
                ),
                // Phase 3 — settles back down
                TweenSequenceItem(
                  tween: Tween(begin: rest.dy - r * 0.6, end: rest.dy)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 11,
                ),
              ]).evaluate(AlwaysStoppedAnimation(t));

              final sx = _squishCtrl.isAnimating || _squishCtrl.isCompleted
                  ? _squishX.value
                  : 1.0;
              final sy = _squishCtrl.isAnimating || _squishCtrl.isCompleted
                  ? _squishY.value
                  : 1.0;

              return Positioned(
                left: rest.dx - r,
                top: fallY - r,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(sx, sy, 1.0),
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD166),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x55FFD166),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
