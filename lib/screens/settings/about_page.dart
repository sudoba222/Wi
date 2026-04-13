// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/language_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white54 : AppColors.mutedText;
    final card = isDark ? AppColors.darkCard : AppColors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.t('about'), style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Logo & branding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.darkPurple, AppColors.splashPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.sunglow,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.sunglow.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: const Center(
                      child: Text('Wi', style: TextStyle(color: AppColors.darkPurple, fontSize: 28, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Wi Tajikistan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(lang.t('aboutTagline'),
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sunglow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.sunglow.withOpacity(0.5)),
                    ),
                    child: const Text('Version 1.0.0', style: TextStyle(color: AppColors.sunglow, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mission card
            _InfoCard(
              card: card,
              title: lang.t('ourMission'),
              body: lang.t('missionText'),
              icon: Icons.flag_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // What is Wi
            _InfoCard(
              card: card,
              title: lang.t('whatIsWi'),
              body: lang.t('whatIsWiText'),
              icon: Icons.info_outline_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Features grid
            _SectionTitle(title: lang.t('keyFeatures'), color: text),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _FeatureTile(card: card, icon: Icons.work_rounded, label: lang.t('featureJobs'), isDark: isDark),
                _FeatureTile(card: card, icon: Icons.people_rounded, label: lang.t('featureNetwork'), isDark: isDark),
                _FeatureTile(card: card, icon: Icons.chat_bubble_rounded, label: lang.t('featureChat'), isDark: isDark),
                _FeatureTile(card: card, icon: Icons.article_rounded, label: lang.t('featureFeed'), isDark: isDark),
              ],
            ),

            const SizedBox(height: 24),

            // Made in Tajikistan
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(lang.t('madeIn'), style: TextStyle(color: sub, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text('© 2025 Wi Tajikistan', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color card;
  final String title, body;
  final IconData icon;
  final bool isDark;
  const _InfoCard({required this.card, required this.title, required this.body, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white60 : AppColors.mutedText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.wisteria.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.wisteria, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(color: sub, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final Color card;
  final IconData icon;
  final String label;
  final bool isDark;
  const _FeatureTile({required this.card, required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : AppColors.darkPurple;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.sunglow, size: 26),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
  );
}
