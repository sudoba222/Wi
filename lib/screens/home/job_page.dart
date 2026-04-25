// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/auth_services.dart';
import '../jobs/seeker_dashboard.dart';
import '../jobs/employer_dashboard.dart';

/// Jobs tab — two-phase UI:
/// 1. An onboarding wizard (4 steps) to capture role, category, work style,
///    and experience level.  State is `static` so it persists across tab switches.
/// 2. Routes to SeekerDashboard or EmployerDashboard based on selected role.

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

  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) return _buildOnboarding(context);
    if (_role == 'employer') return const EmployerDashboard();
    return SeekerDashboard(
      userProfile: _userProfile,
      category: _category,
      workStyle: _workStyle,
      experience: _experience,
    );
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
