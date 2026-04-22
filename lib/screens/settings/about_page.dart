// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/language_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const double _sheetOverlap = 80;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white38 : AppColors.mutedText;
    final card = isDark ? AppColors.darkCard : AppColors.white;

    // Hero height = status bar + appbar + logo area + text + breathing room
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = topPadding + 56 + 180 + 130 + 40;

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── 1. Hero: pinned, never scrolls ────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: heroHeight,
              child: _HeroSection(topPadding: topPadding),
            ),
          ),

          // ── 2. Scrollable content on top ──────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Transparent spacer — lets hero show through
                SizedBox(height: heroHeight - _sheetOverlap),

                // White sheet slides up over the pinned hero
                Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MissionCard(lang: lang, card: card, text: text, sub: sub),
                      const SizedBox(height: 12),
                      _WhatIsWiCard(lang: lang, card: card, text: text, sub: sub),
                      const SizedBox(height: 28),
                      _FeatureLabel(title: lang.t('keyFeatures'), sub: sub),
                      const SizedBox(height: 14),
                      _FeaturesGrid(lang: lang, card: card, text: text, sub: sub),
                      const SizedBox(height: 44),
                      _Footer(lang: lang, sub: sub),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero: pinned gradient + logo + text ───────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final double topPadding;
  const _HeroSection({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E0020), Color(0xFF3B007A), Color(0xFF6A00C8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Ambient orbs
          Positioned(
            top: -80, right: -80,
            child: _Orb(size: 280, color: AppColors.wisteria.withOpacity(0.13)),
          ),
          Positioned(
            bottom: 40, left: -60,
            child: _Orb(size: 200, color: AppColors.sunglow.withOpacity(0.07)),
          ),
          // Logo + text centered below the app bar
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding + 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logo with explicit SizedBox so Stack height is controlled
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Orb(size: 180, color: AppColors.wisteria.withOpacity(0.25)),
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.wisteria.withOpacity(0.5),
                                blurRadius: 48,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 18),
                  // const Text(
                  //   'Wi',
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 34,
                  //     fontWeight: FontWeight.w800,
                  //     letterSpacing: -0.5,
                  //     height: 1,
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    'WORK INTERCONNECTED',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

// ── Mission card ──────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final LanguageProvider lang;
  final Color card, text, sub;
  const _MissionCard(
      {required this.lang,
      required this.card,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      card: card,
      child: Stack(
        children: [
          Positioned(
            top: -10, right: 2,
            child: Text(
              '\u201C',
              style: TextStyle(
                fontSize: 100,
                color: AppColors.wisteria.withOpacity(0.07),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(
                  icon: Icons.flag_rounded,
                  label: lang.t('ourMission'),
                  color: AppColors.wisteria),
              const SizedBox(height: 14),
              Text(
                lang.t('missionText'),
                style: TextStyle(
                  color: text.withOpacity(0.72),
                  fontSize: 14,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── What is Wi card ───────────────────────────────────────────────────────────

class _WhatIsWiCard extends StatelessWidget {
  final LanguageProvider lang;
  final Color card, text, sub;
  const _WhatIsWiCard(
      {required this.lang,
      required this.card,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(
              icon: Icons.info_rounded,
              label: lang.t('whatIsWi'),
              color: AppColors.sunglow),
          const SizedBox(height: 14),
          Text(
            lang.t('whatIsWiText'),
            style: TextStyle(
              color: text.withOpacity(0.72),
              fontSize: 14,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card label row ─────────────────────────────────────────────────────

class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CardLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ],
      );
}

// ── Features section ──────────────────────────────────────────────────────────

class _FeatureLabel extends StatelessWidget {
  final String title;
  final Color sub;
  const _FeatureLabel({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: TextStyle(
          color: sub,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      );
}

class _FeaturesGrid extends StatelessWidget {
  final LanguageProvider lang;
  final Color card, text, sub;
  const _FeaturesGrid(
      {required this.lang,
      required this.card,
      required this.text,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.work_rounded, lang.t('featureJobs'), 'Explore local opportunities', AppColors.sunglow),
      (Icons.people_alt_rounded, lang.t('featureNetwork'), 'Connect with professionals', AppColors.wisteria),
      (Icons.chat_bubble_rounded, lang.t('featureChat'), 'Real-time messaging', const Color(0xFF7ED9A8)),
      (Icons.dynamic_feed_rounded, lang.t('featureFeed'), 'Share & follow your industry', const Color(0xFF79BFFF)),
    ];

    return Column(
      children: [
        Row(children: [
          _FeatureCard(icon: features[0].$1, label: features[0].$2, desc: features[0].$3, accent: features[0].$4, card: card, text: text, sub: sub),
          const SizedBox(width: 12),
          _FeatureCard(icon: features[1].$1, label: features[1].$2, desc: features[1].$3, accent: features[1].$4, card: card, text: text, sub: sub),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _FeatureCard(icon: features[2].$1, label: features[2].$2, desc: features[2].$3, accent: features[2].$4, card: card, text: text, sub: sub),
          const SizedBox(width: 12),
          _FeatureCard(icon: features[3].$1, label: features[3].$2, desc: features[3].$3, accent: features[3].$4, card: card, text: text, sub: sub),
        ]),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final Color accent, card, text, sub;
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.accent,
    required this.card,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(color: sub, fontSize: 11, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final LanguageProvider lang;
  final Color sub;
  const _Footer({required this.lang, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: sub.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.favorite_rounded,
                  color: Colors.redAccent.withOpacity(0.7), size: 12),
            ),
            Container(width: 24, height: 1, color: sub.withOpacity(0.2)),
          ],
        ),
        const SizedBox(height: 14),
        Text(lang.t('madeIn'),
            style:
                TextStyle(color: sub, fontSize: 12, letterSpacing: 0.2)),
        const SizedBox(height: 6),
        Text('© 2025 Wi Tajikistan',
            style: TextStyle(
                color: sub.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final Color card;
  final Widget child;
  const _ContentCard({required this.card, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}
