// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Jobs tab — two-phase UI:
/// 1. An onboarding wizard (4 steps) to capture role, category, work style,
///    and experience level.  State is `static` so it persists across tab switches.
/// 2. A filterable job board with glass cards once onboarding is complete.
class JobPage extends StatefulWidget {
  const JobPage({super.key});

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  // ── Onboarding state (static so it persists across tab switches) ──
  static bool _done = false;
  static String _role = '';       // 'seeker' | 'employer'
  static String _category = '';
  static String _workStyle = '';  // 'remote' | 'onsite' | 'hybrid'
  static String _experience = ''; // 'entry' | 'mid' | 'senior' | 'lead'

  final _pageController = PageController();
  int _step = 0;

  // ── Job board state ──
  String _activeFilter = 'All';
  final List<Map<String, dynamic>> _jobs = [
    {
      'title': 'Flutter Developer',
      'company': 'Alif.tj',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$800–1,200/mo',
      'posted': '2h ago',
      'logo': 'A',
      'color': 0xFF6C5CE7,
      'isRemote': true,
      'saved': false,
    },
    {
      'title': 'UI/UX Designer',
      'company': 'DushanbeIT',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$600–900/mo',
      'posted': '5h ago',
      'logo': 'D',
      'color': 0xFFBC96E6,
      'isRemote': false,
      'saved': false,
    },
    {
      'title': 'Marketing Manager',
      'company': 'TajTelecom',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$700–1,000/mo',
      'posted': '1d ago',
      'logo': 'T',
      'color': 0xFF00B894,
      'isRemote': false,
      'saved': true,
    },
    {
      'title': 'Financial Analyst',
      'company': 'Bank Eskhata',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$900–1,400/mo',
      'posted': '2d ago',
      'logo': 'B',
      'color': 0xFFFFD166,
      'isRemote': false,
      'saved': false,
    },
    {
      'title': 'Backend Engineer',
      'company': 'iPayments',
      'location': 'Remote',
      'type': 'Contract',
      'salary': '\$1,000–1,800/mo',
      'posted': '3d ago',
      'logo': 'i',
      'color': 0xFF210B2C,
      'isRemote': true,
      'saved': false,
    },
    {
      'title': 'Content Creator',
      'company': 'MediaTJ',
      'location': 'Dushanbe, TJ',
      'type': 'Part-time',
      'salary': '\$400–600/mo',
      'posted': '4d ago',
      'logo': 'M',
      'color': 0xFFE17055,
      'isRemote': true,
      'saved': false,
    },
    {
      'title': 'Sales Representative',
      'company': 'Somoni Motors',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$500–800/mo',
      'posted': '5d ago',
      'logo': 'S',
      'color': 0xFF74B9FF,
      'isRemote': false,
      'saved': false,
    },
    {
      'title': 'Product Manager',
      'company': 'TechHub TJ',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$1,200–2,000/mo',
      'posted': '1w ago',
      'logo': 'T',
      'color': 0xFFFF7675,
      'isRemote': false,
      'saved': false,
    },
  ];

  void _nextStep() {
    if (_step < 3) {
      _step++;
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {});
    } else {
      setState(() => _done = true);
    }
  }

  void _toggleSave(int i) => setState(() => _jobs[i]['saved'] = !_jobs[i]['saved']);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) return _buildOnboarding(context);
    return _buildJobBoard(context);
  }

  // ════════════════════════════════════════════════════════════
  //  ONBOARDING
  // ════════════════════════════════════════════════════════════

  Widget _buildOnboarding(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EAFF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppColors.sunglow
                              : AppColors.mutedText.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepRole(
                      selected: _role,
                      onSelect: (v) {
                        setState(() => _role = v);
                        Future.delayed(
                          const Duration(milliseconds: 250),
                          _nextStep,
                        );
                      },
                    ),
                    _StepCategory(
                      role: _role,
                      selected: _category,
                      onSelect: (v) => setState(() => _category = v),
                      onContinue: _nextStep,
                    ),
                    _StepWorkStyle(
                      role: _role,
                      selected: _workStyle,
                      onSelect: (v) {
                        setState(() => _workStyle = v);
                        Future.delayed(
                          const Duration(milliseconds: 250),
                          _nextStep,
                        );
                      },
                    ),
                    _StepExperience(
                      role: _role,
                      selected: _experience,
                      onSelect: (v) => setState(() => _experience = v),
                      onFinish: _nextStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  JOB BOARD
  // ════════════════════════════════════════════════════════════

  Widget _buildJobBoard(BuildContext context) {
    final filters = ['All', 'Remote', 'Full-time', 'Part-time', 'Contract'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _activeFilter == 'All'
        ? _jobs
        : _jobs.where((j) {
            if (_activeFilter == 'Remote') return j['isRemote'] == true;
            return j['type'] == _activeFilter;
          }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E0B2C), AppColors.darkBg]
                : [const Color(0xFFF0EAFF), AppColors.background],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBoardHeader(context, isDark)),
            SliverToBoxAdapter(child: _buildFilters(filters, isDark)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _JobCard(
                    job: filtered[i],
                    onSave: () => _toggleSave(_jobs.indexOf(filtered[i])),
                    onTap: () => _showJobDetail(context, filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardHeader(BuildContext context, bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    return Padding(
      padding: EdgeInsets.only(
        top: topPad + 12,
        left: 20,
        right: 16,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jobs for You',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.7)),
                    ),
                    child: Icon(Icons.tune_rounded, color: textColor, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              _role == 'employer'
                  ? 'Find the right talent for your team'
                  : 'Opportunities in Tajikistan & remote',
              style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<String> filters, bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isActive = f == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? AppColors.wisteria : AppColors.darkPurple)
                    : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.65)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? (isDark ? AppColors.wisteria : AppColors.darkPurple)
                      : AppColors.mutedText.withOpacity(0.25),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? (isDark ? AppColors.darkPurple : AppColors.sunglow)
                      : AppColors.mutedText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJobDetail(BuildContext context, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailSheet(job: job),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ONBOARDING STEPS
// ════════════════════════════════════════════════════════════

class _StepRole extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _StepRole({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Welcome to\nWi Jobs',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.darkPurple,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Let's personalize your experience.",
            style: TextStyle(fontSize: 16, color: AppColors.mutedText),
          ),
          const SizedBox(height: 48),
          _RoleCard(
            icon: Icons.search_rounded,
            title: "I'm looking for a job",
            subtitle: 'Browse opportunities that match your skills',
            color: AppColors.sunglow,
            isSelected: selected == 'seeker',
            onTap: () => onSelect('seeker'),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.groups_rounded,
            title: "I'm hiring talent",
            subtitle: 'Post roles and find the right candidates',
            color: AppColors.wisteria,
            isSelected: selected == 'employer',
            onTap: () => onSelect('employer'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.sunglow.withOpacity(0.6) : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withOpacity(isSelected ? 0.18 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.white : AppColors.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.white.withOpacity(0.7)
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: isSelected ? AppColors.sunglow : AppColors.mutedText,
              size: isSelected ? 22 : 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCategory extends StatelessWidget {
  final String role;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  const _StepCategory({
    required this.role,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
  });

  static const _categories = [
    ('Software Dev', Icons.code_rounded),
    ('Design', Icons.design_services_rounded),
    ('Marketing', Icons.campaign_rounded),
    ('Finance', Icons.account_balance_rounded),
    ('Sales', Icons.handshake_rounded),
    ('Operations', Icons.settings_rounded),
    ('HR', Icons.people_rounded),
    ('Engineering', Icons.engineering_rounded),
    ('Education', Icons.school_rounded),
    ('Healthcare', Icons.medical_services_rounded),
    ('Legal', Icons.gavel_rounded),
    ('Other', Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            role == 'employer'
                ? 'What type of role\nare you posting?'
                : "What's your\nfield?",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.darkPurple,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the category that fits best.',
            style: TextStyle(fontSize: 15, color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final (label, icon) = _categories[i];
                final isSelected = selected == label;
                return GestureDetector(
                  onTap: () => onSelect(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.darkPurple : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sunglow.withOpacity(0.5)
                            : AppColors.mutedText.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: isSelected ? AppColors.sunglow : AppColors.wisteria,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.white : AppColors.darkPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selected.isNotEmpty ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow,
                foregroundColor: AppColors.darkPurple,
                disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepWorkStyle extends StatelessWidget {
  final String role;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StepWorkStyle({
    required this.role,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            role == 'employer'
                ? "What's the\nwork arrangement?"
                : "How do you want\nto work?",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.darkPurple,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred style.',
            style: TextStyle(fontSize: 15, color: AppColors.mutedText),
          ),
          const SizedBox(height: 40),
          _WorkStyleOption(
            icon: Icons.apartment_rounded,
            title: 'On-site',
            subtitle: 'Work from the office',
            value: 'onsite',
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 14),
          _WorkStyleOption(
            icon: Icons.laptop_rounded,
            title: 'Remote',
            subtitle: 'Work from anywhere',
            value: 'remote',
            selected: selected,
            onSelect: onSelect,
          ),
          const SizedBox(height: 14),
          _WorkStyleOption(
            icon: Icons.sync_alt_rounded,
            title: 'Hybrid',
            subtitle: 'Mix of both',
            value: 'hybrid',
            selected: selected,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _WorkStyleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;

  const _WorkStyleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.sunglow.withOpacity(0.5)
                : AppColors.mutedText.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withOpacity(isSelected ? 0.18 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sunglow.withOpacity(0.15)
                    : AppColors.wisteria.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.sunglow : AppColors.wisteria,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.white : AppColors.darkPurple,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.white.withOpacity(0.65)
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.sunglow : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.sunglow
                      : AppColors.mutedText.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.darkPurple)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepExperience extends StatelessWidget {
  final String role;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onFinish;

  const _StepExperience({
    required this.role,
    required this.selected,
    required this.onSelect,
    required this.onFinish,
  });

  static const _levels = [
    ('Entry Level', '0–2 years', Icons.emoji_nature_rounded),
    ('Mid Level', '2–5 years', Icons.trending_up_rounded),
    ('Senior Level', '5–8 years', Icons.military_tech_rounded),
    ('Lead / Manager', '8+ years', Icons.workspace_premium_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            role == 'employer'
                ? 'Required\nexperience level?'
                : 'Your\nexperience level?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.darkPurple,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us show the most relevant results.',
            style: TextStyle(fontSize: 15, color: AppColors.mutedText),
          ),
          const SizedBox(height: 30),
          ...List.generate(_levels.length, (i) {
            final (label, years, icon) = _levels[i];
            final isSelected = selected == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.sunglow.withOpacity(0.5)
                          : AppColors.mutedText.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? AppColors.sunglow : AppColors.wisteria,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.white : AppColors.darkPurple,
                              ),
                            ),
                            Text(
                              years,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? AppColors.white.withOpacity(0.6)
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.sunglow,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selected.isNotEmpty ? onFinish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow,
                foregroundColor: AppColors.darkPurple,
                disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Let's Go!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  JOB CARD
// ════════════════════════════════════════════════════════════

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.onSave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = Color(job['color'] as int);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.75);
    final borderColor = isDark
        ? AppColors.wisteria.withOpacity(0.25)
        : Colors.white.withOpacity(0.6);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wisteria.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: logoColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            job['logo'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['company'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText,
                              ),
                            ),
                            Text(
                              job['posted'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onSave,
                        child: Icon(
                          (job['saved'] as bool)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: (job['saved'] as bool)
                              ? AppColors.sunglow
                              : AppColors.mutedText,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    job['title'] as String,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location + type chips
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        job['location'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.wisteria.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job['type'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.splashPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (job['isRemote'] as bool) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.sunglow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Remote',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B6914),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Salary + Apply
                  Row(
                    children: [
                      Text(
                        job['salary'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.splashPurple,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.sunglow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunglow.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  JOB DETAIL BOTTOM SHEET
// ════════════════════════════════════════════════════════════

class _JobDetailSheet extends StatelessWidget {
  final Map<String, dynamic> job;

  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    final logoColor = Color(job['color'] as int);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: logoColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                job['logo'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkPurple,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  job['company'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Details chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: job['location'] as String,
                          ),
                          _InfoChip(
                            icon: Icons.work_outline_rounded,
                            label: job['type'] as String,
                          ),
                          _InfoChip(
                            icon: Icons.attach_money_rounded,
                            label: job['salary'] as String,
                          ),
                          if (job['isRemote'] as bool)
                            _InfoChip(
                              icon: Icons.laptop_rounded,
                              label: 'Remote OK',
                              highlight: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'About the role',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We are looking for a talented ${job['title']} to join ${job['company']} in ${job['location']}. '
                        'You will be part of a dynamic team building innovative products for Tajikistan and the broader Central Asia market.\n\n'
                        'This is a ${job['type'].toString().toLowerCase()} position with a competitive salary of ${job['salary']}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedText,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...const [
                        '2+ years of relevant experience',
                        'Strong communication skills in Tajik, Russian or English',
                        'Ability to work in a fast-paced environment',
                        'Passion for building great products',
                      ].map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: AppColors.wisteria,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.mutedText,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Application submitted!'),
                                backgroundColor: AppColors.darkPurple,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunglow,
                            foregroundColor: AppColors.darkPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.sunglow.withOpacity(0.15)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.sunglow.withOpacity(0.4)
              : AppColors.mutedText.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? const Color(0xFF8B6914) : AppColors.mutedText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlight ? const Color(0xFF8B6914) : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
