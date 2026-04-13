// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/language_provider.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final card = isDark ? AppColors.darkCard : AppColors.white;

    final faqs = [
      {'q': lang.t('faq1q'), 'a': lang.t('faq1a')},
      {'q': lang.t('faq2q'), 'a': lang.t('faq2a')},
      {'q': lang.t('faq3q'), 'a': lang.t('faq3a')},
      {'q': lang.t('faq4q'), 'a': lang.t('faq4a')},
      {'q': lang.t('faq5q'), 'a': lang.t('faq5a')},
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.t('helpSupport'), style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.darkPurple, AppColors.splashPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: AppColors.sunglow.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.sunglow, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.t('helpTitle'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(lang.t('helpSubtitle'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FAQ section
            Text(lang.t('faqTitle'), style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            ...faqs.asMap().entries.map((e) => _FaqCard(
              card: card,
              question: e.value['q']!,
              answer: e.value['a']!,
              isExpanded: _expandedIndex == e.key,
              isDark: isDark,
              onTap: () => setState(() => _expandedIndex = _expandedIndex == e.key ? null : e.key),
            )),

            const SizedBox(height: 28),

            // Contact options
            Text(lang.t('contactUs'), style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            _ContactTile(
              card: card,
              icon: Icons.email_rounded,
              title: lang.t('contactEmail'),
              subtitle: 'support@wi-tajikistan.com',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _ContactTile(
              card: card,
              icon: Icons.telegram,
              title: lang.t('contactTelegram'),
              subtitle: '@wi_tajikistan',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _ContactTile(
              card: card,
              icon: Icons.bug_report_rounded,
              title: lang.t('reportBug'),
              subtitle: lang.t('reportBugSub'),
              isDark: isDark,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final Color card;
  final String question, answer;
  final bool isExpanded, isDark;
  final VoidCallback onTap;
  const _FaqCard({required this.card, required this.question, required this.answer, required this.isExpanded, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white60 : AppColors.mutedText;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? AppColors.wisteria.withOpacity(0.5) : Colors.transparent,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(question, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600))),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.wisteria,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
              const SizedBox(height: 10),
              Text(answer, style: TextStyle(color: sub, fontSize: 13, height: 1.6)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Color card;
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  const _ContactTile({required this.card, required this.icon, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white54 : AppColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.wisteria.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.wisteria, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: sub, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 20),
        ],
      ),
    );
  }
}
