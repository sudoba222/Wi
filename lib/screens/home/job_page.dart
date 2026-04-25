// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/auth_services.dart';

/// Jobs tab — two-phase UI:
/// 1. An onboarding wizard (4 steps) to capture role, category, work style,
///    and experience level.  State is `static` so it persists across tab switches.
/// 2. A filterable job board with glass cards once onboarding is complete.

// ════════════════════════════════════════════════════════════
//  APPLICATION DATA MODEL
// ════════════════════════════════════════════════════════════

class _AppEntry {
  final String jobTitle;
  final String company;
  final String logo;
  final String salary;
  final String jobType;
  final int colorValue;
  final bool easyApply;
  final String appliedAt;
  String status; // 'applied' | 'reviewing' | 'interview' | 'offer' | 'rejected' | 'ghosted'

  _AppEntry({
    required this.jobTitle,
    required this.company,
    required this.logo,
    required this.salary,
    required this.jobType,
    required this.colorValue,
    required this.easyApply,
    required this.appliedAt,
    required this.status,
  });
}

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

  // ── Applications state (static so it persists across tab switches) ──
  static final List<_AppEntry> _applications = [];

  final _pageController = PageController();
  int _step = 0;

  // ── Job board state ──
  String _activeFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  UserProfile? _userProfile;
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

  // ── Application helpers ──
  bool _isApplied(Map job) =>
      _applications.any((a) => a.jobTitle == job['title'] && a.company == job['company']);

  void _applyToJob(Map job, bool easyApply) {
    if (_isApplied(job)) return;
    setState(() => _applications.add(_AppEntry(
          jobTitle: job['title'] as String,
          company: job['company'] as String,
          logo: job['logo'] as String,
          colorValue: job['color'] as int,
          salary: job['salary'] as String,
          jobType: job['type'] as String,
          easyApply: easyApply,
          appliedAt: 'just now',
          status: 'applied',
        )));
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

  void _toggleSave(int i) => setState(() => _jobs[i]['saved'] = !_jobs[i]['saved']);

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
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

    final filtered = _jobs.where((j) {
      final matchesFilter = _activeFilter == 'All'
          ? true
          : _activeFilter == 'Remote'
              ? j['isRemote'] == true
              : j['type'] == _activeFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          (j['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (j['company'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
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
                    isApplied: _isApplied(filtered[i]),
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
              // My Applications button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ApplicationsDashboard(
                        applications: _applications,
                        onStatusChanged: () => setState(() {}),
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.wisteria.withOpacity(0.15)
                                : AppColors.darkPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.wisteria.withOpacity(0.3)
                                  : AppColors.darkPurple.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.work_history_rounded,
                                color: isDark ? AppColors.wisteria : AppColors.darkPurple,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Applied',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.wisteria : AppColors.darkPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_applications.isNotEmpty)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.sunglow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_applications.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkPurple,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AdvancedFilterSheet(
                      activeFilter: _activeFilter,
                      onFilterChanged: (f) => setState(() => _activeFilter = f),
                    ),
                  );
                },
                child: ClipRRect(
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
          const SizedBox(height: 14),
          // Search bar
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.mutedText.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.darkPurple,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search jobs or companies…',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.mutedText,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
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
      builder: (_) => _JobDetailSheet(
        job: job,
        isApplied: _isApplied(job),
        userProfile: _userProfile,
        onApply: (easyApply) => _applyToJob(job, easyApply),
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

// ════════════════════════════════════════════════════════════
//  JOB CARD
// ════════════════════════════════════════════════════════════

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isApplied;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.isApplied,
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
                      if (isApplied)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 12, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'Applied',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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
                          color: isApplied
                              ? AppColors.mutedText.withOpacity(0.15)
                              : AppColors.sunglow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isApplied
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppColors.sunglow.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Text(
                          isApplied ? 'Applied' : 'Apply Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isApplied ? AppColors.mutedText : AppColors.darkPurple,
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
  final bool isApplied;
  final UserProfile? userProfile;
  final void Function(bool easyApply) onApply;

  const _JobDetailSheet({
    required this.job,
    required this.isApplied,
    required this.onApply,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = Color(job['color'] as int);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkCard.withOpacity(0.97)
        : Colors.white.withOpacity(0.97);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
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
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.darkPurple,
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
                      Text(
                        'About the role',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkPurple,
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
                      Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkPurple,
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
                    ],
                  ),
                ),
              ),
              // Bottom action area
              if (isApplied)
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You have already applied',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
                  child: Row(
                    children: [
                      // Easy Apply button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => _EasyApplySheet(
                                jobTitle: job['title'] as String,
                                company: job['company'] as String,
                                userProfile: userProfile,
                                onApply: () {
                                  onApply(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.sunglow,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sunglow.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '\u26a1',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Easy Apply',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply with CV button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => _ApplyWithCvSheet(
                                jobTitle: job['title'] as String,
                                company: job['company'] as String,
                                onApply: () {
                                  onApply(false);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.wisteria,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '\ud83d\udcc4',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Apply with CV',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.wisteria : AppColors.splashPurple,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  EASY APPLY SHEET
// ════════════════════════════════════════════════════════════

class _EasyApplySheet extends StatefulWidget {
  final String jobTitle;
  final String company;
  final UserProfile? userProfile;
  final VoidCallback onApply;

  const _EasyApplySheet({
    required this.jobTitle,
    required this.company,
    required this.onApply,
    this.userProfile,
  });

  @override
  State<_EasyApplySheet> createState() => _EasyApplySheetState();
}

class _EasyApplySheetState extends State<_EasyApplySheet> {
  final _phoneController = TextEditingController(text: '+992 ');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final inputFill = isDark
        ? Colors.white.withOpacity(0.05)
        : AppColors.background;
    final inputBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : AppColors.mutedText.withOpacity(0.2);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Text(
                            '\u26a1',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Easy Apply',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.jobTitle} at ${widget.company}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Profile preview
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.mutedText.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.wisteria,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: widget.userProfile?.profilePicture.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.userProfile!.profilePicture,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Center(
                                          child: Text(
                                            (widget.userProfile?.name.isNotEmpty == true
                                                    ? widget.userProfile!.name[0]
                                                    : 'U')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        (widget.userProfile?.name.isNotEmpty == true
                                                ? widget.userProfile!.name[0]
                                                : 'U')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userProfile?.name.isNotEmpty == true
                                      ? widget.userProfile!.name
                                      : 'Your Name',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  widget.userProfile?.jobTitle.isNotEmpty == true
                                      ? widget.userProfile!.jobTitle
                                      : 'Your current role',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.wisteria,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: AppColors.mutedText.withOpacity(0.15),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      // Phone field
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          hintStyle: TextStyle(
                            color: AppColors.mutedText.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.wisteria,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cover note
                      Text(
                        'Cover Note',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Add a short note\u2026 (optional)',
                          hintStyle: TextStyle(
                            color: AppColors.mutedText.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.wisteria,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            widget.onApply();
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
                            'Apply Now \u2192',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  APPLY WITH CV SHEET
// ════════════════════════════════════════════════════════════

class _ApplyWithCvSheet extends StatefulWidget {
  final String jobTitle;
  final String company;
  final VoidCallback onApply;

  const _ApplyWithCvSheet({
    required this.jobTitle,
    required this.company,
    required this.onApply,
  });

  @override
  State<_ApplyWithCvSheet> createState() => _ApplyWithCvSheetState();
}

class _ApplyWithCvSheetState extends State<_ApplyWithCvSheet> {
  bool _cvSelected = false;
  final _coverController = TextEditingController();

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final inputFill = isDark
        ? Colors.white.withOpacity(0.05)
        : AppColors.background;
    final inputBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : AppColors.mutedText.withOpacity(0.2);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Text(
                            '\ud83d\udcc4',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Apply with CV',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.jobTitle} at ${widget.company}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Upload area
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _cvSelected = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: _cvSelected
                                ? const Color(0xFF10B981).withOpacity(0.06)
                                : (isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : AppColors.background),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _cvSelected
                                  ? const Color(0xFF10B981).withOpacity(0.4)
                                  : AppColors.mutedText.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: _cvSelected
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Resume.pdf',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Ready to submit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file_rounded,
                                      color: AppColors.mutedText.withOpacity(0.6),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload CV',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'PDF, DOC or DOCX \u00b7 max 5MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cover letter
                      Text(
                        'Cover Letter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _coverController,
                        maxLines: 5,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Introduce yourself to the hiring team\u2026 (optional)',
                          hintStyle: TextStyle(
                            color: AppColors.mutedText.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.wisteria,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _cvSelected
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context);
                                  widget.onApply();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.splashPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.mutedText.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Submit Application \u2192',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  APPLICATIONS DASHBOARD
// ════════════════════════════════════════════════════════════

class _ApplicationsDashboard extends StatefulWidget {
  final List<_AppEntry> applications;
  final VoidCallback onStatusChanged;

  const _ApplicationsDashboard({
    required this.applications,
    required this.onStatusChanged,
  });

  @override
  State<_ApplicationsDashboard> createState() => _ApplicationsDashboardState();
}

class _ApplicationsDashboardState extends State<_ApplicationsDashboard> {
  String _filter = 'All';


  static const _statusLabels = {
    'applied': 'Applied',
    'reviewing': 'Reviewing',
    'interview': 'Interview',
    'offer': 'Offer',
    'rejected': 'Rejected',
    'ghosted': 'Ghosted',
  };

  static Color _statusColor(String status) {
    switch (status) {
      case 'applied':
        return AppColors.wisteria;
      case 'reviewing':
        return const Color(0xFFF59E0B);
      case 'interview':
        return const Color(0xFF10B981);
      case 'offer':
        return AppColors.sunglow;
      case 'rejected':
        return Colors.redAccent;
      case 'ghosted':
        return Colors.grey;
      default:
        return AppColors.mutedText;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'applied':
        return Icons.send_rounded;
      case 'reviewing':
        return Icons.visibility_rounded;
      case 'interview':
        return Icons.groups_rounded;
      case 'offer':
        return Icons.celebration_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'ghosted':
        return Icons.visibility_off_rounded;
      default:
        return Icons.circle;
    }
  }

  int _countByStatus(String status) =>
      widget.applications.where((a) => a.status == status).length;

  List<_AppEntry> get _filtered {
    if (_filter == 'All') return widget.applications;
    return widget.applications.where((a) => a.status == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [const Color(0xFF1E0B2C), AppColors.darkBg]
        : [const Color(0xFFF0EAFF), AppColors.background];
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.8);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : AppColors.mutedText.withOpacity(0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Applications',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${widget.applications.length} application${widget.applications.length == 1 ? '' : 's'} total',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatTile(
                          status: 'applied',
                          count: _countByStatus('applied'),
                          label: 'Applied',
                          color: _statusColor('applied'),
                          icon: _statusIcon('applied'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          status: 'reviewing',
                          count: _countByStatus('reviewing'),
                          label: 'Reviewing',
                          color: _statusColor('reviewing'),
                          icon: _statusIcon('reviewing'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          status: 'interview',
                          count: _countByStatus('interview'),
                          label: 'Interview',
                          color: _statusColor('interview'),
                          icon: _statusIcon('interview'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatTile(
                          status: 'offer',
                          count: _countByStatus('offer'),
                          label: 'Offers',
                          color: _statusColor('offer'),
                          icon: _statusIcon('offer'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          status: 'rejected',
                          count: _countByStatus('rejected'),
                          label: 'Rejected',
                          color: _statusColor('rejected'),
                          icon: _statusIcon('rejected'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          status: 'ghosted',
                          count: _countByStatus('ghosted'),
                          label: 'Ghosted',
                          color: _statusColor('ghosted'),
                          icon: _statusIcon('ghosted'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    'All',
                    'Applied',
                    'Reviewing',
                    'Interview',
                    'Offer',
                    'Rejected',
                    'Ghosted',
                  ].map((f) {
                    final isActive = _filter == f;
                    final statusKey = f.toLowerCase();
                    final chipColor = f == 'All'
                        ? AppColors.wisteria
                        : _statusColor(statusKey);
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? chipColor.withOpacity(0.15)
                              : (isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.white.withOpacity(0.7)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? chipColor.withOpacity(0.5)
                                : AppColors.mutedText.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? chipColor : AppColors.mutedText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Application list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off_outlined,
                              size: 56,
                              color: AppColors.mutedText.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No applications yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Apply to jobs and track them here',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final entry = _filtered[i];
                          return _ApplicationCard(
                            entry: entry,
                            cardColor: cardColor,
                            isDark: isDark,
                            statusColor: _statusColor(entry.status),
                            statusLabel: _statusLabels[entry.status] ?? entry.status,
                            statusIcon: _statusIcon(entry.status),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _StatusUpdateSheet(
                                  entry: entry,
                                  statusLabels: _statusLabels,
                                  statusColor: _statusColor,
                                  statusIcon: _statusIcon,
                                  onStatusChanged: (newStatus) {
                                    setState(() => entry.status = newStatus);
                                    widget.onStatusChanged();
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat tile widget ──

class _StatTile extends StatelessWidget {
  final String status;
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatTile({
    required this.status,
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.darkPurple,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Application card widget ──

class _ApplicationCard extends StatelessWidget {
  final _AppEntry entry;
  final Color cardColor;
  final bool isDark;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.entry,
    required this.cardColor,
    required this.isDark,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = Color(entry.colorValue);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : AppColors.mutedText.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: logoColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  entry.logo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.jobTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 10, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.company,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Salary + type chips
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.splashPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          entry.salary,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.splashPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.wisteria.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          entry.jobType,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.wisteria,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Apply method + date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: entry.easyApply
                              ? AppColors.sunglow.withOpacity(0.15)
                              : AppColors.mutedText.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          entry.easyApply ? '\u26a1 Easy Apply' : '\ud83d\udcc4 With CV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: entry.easyApply
                                ? const Color(0xFF8B6914)
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.appliedAt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STATUS UPDATE SHEET
// ════════════════════════════════════════════════════════════

class _StatusUpdateSheet extends StatefulWidget {
  final _AppEntry entry;
  final Map<String, String> statusLabels;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final void Function(String) onStatusChanged;

  const _StatusUpdateSheet({
    required this.entry,
    required this.statusLabels,
    required this.statusColor,
    required this.statusIcon,
    required this.onStatusChanged,
  });

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.entry.status;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.entry.jobTitle} at ${widget.entry.company}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.mutedText.withOpacity(0.12), height: 1),
            ...widget.statusLabels.entries.map((e) {
              final isSelected = _selected == e.key;
              final color = widget.statusColor(e.key);
              final icon = widget.statusIcon(e.key);
              return ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = e.key);
                  widget.onStatusChanged(e.key);
                  Navigator.pop(context);
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                title: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : textColor,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: color, size: 20)
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INFO CHIP
// ════════════════════════════════════════════════════════════

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

// ════════════════════════════════════════════════════════════
//  ADVANCED FILTER SHEET
// ════════════════════════════════════════════════════════════

class _AdvancedFilterSheet extends StatefulWidget {
  final String activeFilter;
  final void Function(String) onFilterChanged;

  const _AdvancedFilterSheet({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late String _selected;

  static const _options = [
    ('All', Icons.apps_rounded),
    ('Remote', Icons.laptop_rounded),
    ('Full-time', Icons.work_rounded),
    ('Part-time', Icons.work_outline_rounded),
    ('Contract', Icons.assignment_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.activeFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.mutedText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Filter Jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      widget.onFilterChanged('All');
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.wisteria,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.mutedText.withOpacity(0.12), height: 1),
            ..._options.map((opt) {
              final (label, icon) = opt;
              final isSelected = _selected == label;
              return ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = label);
                  widget.onFilterChanged(label);
                  Navigator.pop(context);
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sunglow.withOpacity(0.15)
                        : AppColors.mutedText.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppColors.sunglow : AppColors.mutedText,
                  ),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? (isDark ? AppColors.sunglow : AppColors.darkPurple) : textColor,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: AppColors.sunglow, size: 20)
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
