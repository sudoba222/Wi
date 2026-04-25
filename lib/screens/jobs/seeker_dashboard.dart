// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import 'job_store.dart';
import 'job_widgets.dart';

class SeekerDashboard extends StatefulWidget {
  final UserProfile? userProfile;
  final String category;
  final String workStyle;
  final String experience;

  const SeekerDashboard({
    super.key,
    required this.userProfile,
    required this.category,
    required this.workStyle,
    required this.experience,
  });

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _strengthExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Profile strength ──

  int get _profileStrength {
    final p = widget.userProfile;
    if (p == null) return 10;
    int score = 0;
    if (p.name.isNotEmpty) score += 15;
    if (p.jobTitle.isNotEmpty) score += 15;
    if (p.company.isNotEmpty) score += 10;
    if (p.bio.isNotEmpty) score += 20;
    if (p.skills.isNotEmpty) score += 20;
    if (p.experience.isNotEmpty) score += 20;
    return score.clamp(10, 100);
  }

  List<(String, bool)> get _strengthChecklist {
    final p = widget.userProfile;
    return [
      ('Full name', p?.name.isNotEmpty ?? false),
      ('Job title', p?.jobTitle.isNotEmpty ?? false),
      ('Company', p?.company.isNotEmpty ?? false),
      ('Bio / summary', p?.bio.isNotEmpty ?? false),
      ('Skills added', p?.skills.isNotEmpty ?? false),
      ('Work experience', p?.experience.isNotEmpty ?? false),
    ];
  }

  // ── Job match ──

  int _matchScore(Map<String, dynamic> job) {
    int score = 10;
    final jobCategory = job['category'] as String? ?? '';
    final jobWorkStyle = job['workStyle'] as String? ?? '';
    if (widget.category.isNotEmpty && jobCategory == widget.category) score += 50;
    if (widget.workStyle.isNotEmpty) {
      if (widget.workStyle == 'remote' && jobWorkStyle == 'remote') {
        score += 30;
      } else if (widget.workStyle == 'onsite' && jobWorkStyle == 'onsite') {
        score += 30;
      } else if (widget.workStyle == 'hybrid') {
        score += 15;
      } else if (jobWorkStyle == 'remote' && widget.workStyle != 'onsite') {
        score += 10;
      }
    }
    return score.clamp(0, 100);
  }

  List<Map<String, dynamic>> get _recommendedJobs {
    final jobs = List<Map<String, dynamic>>.from(JobsStore.jobBoard);
    jobs.sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));
    return jobs.where((j) => _matchScore(j) >= 40).take(5).toList();
  }

  List<Map<String, dynamic>> get _filteredBrowse {
    return JobsStore.jobBoard.where((j) {
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
  }

  List<Map<String, dynamic>> get _savedJobs =>
      JobsStore.jobBoard.where((j) => j['saved'] == true).toList();

  bool _isApplied(Map j) => JobsStore.seekerApplications
      .any((a) => a.jobTitle == j['title'] && a.company == j['company']);

  void _applyToJob(Map<String, dynamic> job, bool easyApply) {
    if (_isApplied(job)) return;
    setState(() => JobsStore.seekerApplications.add(AppEntry(
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

  void _toggleSave(Map<String, dynamic> job) {
    setState(() => job['saved'] = !(job['saved'] as bool));
  }

  void _openJobDetail(BuildContext context, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailSheet(
        job: job,
        isApplied: _isApplied(job),
        userProfile: widget.userProfile,
        onApply: (easyApply) => _applyToJob(job, easyApply),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final strength = _profileStrength;

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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.15)),
                        ),
                        child: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jobs for You',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                          Text('Opportunities in Tajikistan & remote',
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    // Applied badge
                    GestureDetector(
                      onTap: () => _tabController.animateTo(3),
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
                                    Icon(Icons.work_history_rounded,
                                        color: isDark ? AppColors.wisteria : AppColors.darkPurple,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text('Applied',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.wisteria : AppColors.darkPurple)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (JobsStore.seekerApplications.isNotEmpty)
                            Positioned(
                              top: -6, right: -6,
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                    color: AppColors.sunglow, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${JobsStore.seekerApplications.length}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.darkPurple)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : AppColors.mutedText.withOpacity(0.15)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isDark ? AppColors.darkPurple : Colors.white,
                  unselectedLabelColor: AppColors.mutedText,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  indicator: BoxDecoration(
                    color: isDark ? AppColors.wisteria : AppColors.darkPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'For You'),
                    Tab(text: 'Browse'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ForYouTab(
                      isDark: isDark,
                      textColor: textColor,
                      strength: strength,
                      strengthExpanded: _strengthExpanded,
                      checklist: _strengthChecklist,
                      onToggleStrength: () => setState(() => _strengthExpanded = !_strengthExpanded),
                      applications: JobsStore.seekerApplications,
                      recommendedJobs: _recommendedJobs,
                      matchScore: _matchScore,
                      isApplied: _isApplied,
                      onSave: _toggleSave,
                      onTap: (j) => _openJobDetail(context, j),
                    ),
                    _BrowseTab(
                      isDark: isDark,
                      textColor: textColor,
                      activeFilter: _activeFilter,
                      searchQuery: _searchQuery,
                      searchController: _searchController,
                      filteredJobs: _filteredBrowse,
                      isApplied: _isApplied,
                      onSave: _toggleSave,
                      onTap: (j) => _openJobDetail(context, j),
                      onFilterChanged: (f) => setState(() => _activeFilter = f),
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      onOpenFilter: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AdvancedFilterSheet(
                          activeFilter: _activeFilter,
                          onFilterChanged: (f) => setState(() => _activeFilter = f),
                        ),
                      ),
                    ),
                    _SavedTab(
                      isDark: isDark,
                      textColor: textColor,
                      savedJobs: _savedJobs,
                      isApplied: _isApplied,
                      onSave: _toggleSave,
                      onTap: (j) => _openJobDetail(context, j),
                    ),
                    _ActivityTab(
                      isDark: isDark,
                      textColor: textColor,
                      applications: JobsStore.seekerApplications,
                      onStatusChanged: () => setState(() {}),
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
//  TAB: FOR YOU
// ════════════════════════════════════════════════════════════

class _ForYouTab extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final int strength;
  final bool strengthExpanded;
  final List<(String, bool)> checklist;
  final VoidCallback onToggleStrength;
  final List<AppEntry> applications;
  final List<Map<String, dynamic>> recommendedJobs;
  final int Function(Map<String, dynamic>) matchScore;
  final bool Function(Map) isApplied;
  final void Function(Map<String, dynamic>) onSave;
  final void Function(Map<String, dynamic>) onTap;

  const _ForYouTab({
    required this.isDark,
    required this.textColor,
    required this.strength,
    required this.strengthExpanded,
    required this.checklist,
    required this.onToggleStrength,
    required this.applications,
    required this.recommendedJobs,
    required this.matchScore,
    required this.isApplied,
    required this.onSave,
    required this.onTap,
  });

  Color get _strengthColor {
    if (strength >= 80) return const Color(0xFF10B981);
    if (strength >= 50) return AppColors.sunglow;
    return Colors.redAccent;
  }

  String get _strengthLabel {
    if (strength >= 80) return 'Strong';
    if (strength >= 50) return 'Good';
    return 'Starter';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Profile strength card
        GestureDetector(
          onTap: onToggleStrength,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkCard, AppColors.darkCard.withOpacity(0.8)]
                        : [Colors.white, Colors.white.withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _strengthColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _strengthColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _strengthColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$strength%',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800, color: _strengthColor)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Profile Strength',
                                      style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _strengthColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_strengthLabel,
                                        style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.w700, color: _strengthColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Complete your profile to stand out',
                                  style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        Icon(
                          strengthExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.mutedText, size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: strength / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.mutedText.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                      ),
                    ),
                    if (strengthExpanded) ...[
                      const SizedBox(height: 14),
                      Divider(color: AppColors.mutedText.withOpacity(0.1), height: 1),
                      const SizedBox(height: 12),
                      ...checklist.map((item) {
                        final (label, done) = item;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: done ? const Color(0xFF10B981).withOpacity(0.12) : AppColors.mutedText.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  done ? Icons.check_rounded : Icons.close_rounded,
                                  size: 13,
                                  color: done ? const Color(0xFF10B981) : AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: done ? textColor : AppColors.mutedText,
                                    fontWeight: done ? FontWeight.w500 : FontWeight.normal,
                                    decoration: done ? TextDecoration.none : TextDecoration.none,
                                  )),
                              if (!done) ...[
                                const Spacer(),
                                Text('Add →',
                                    style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.wisteria)),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Quick stats
        Row(
          children: [
            _QuickStat(
              count: applications.length,
              label: 'Applied',
              icon: Icons.send_rounded,
              color: AppColors.wisteria,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _QuickStat(
              count: applications.where((a) => a.status == 'interview').length,
              label: 'Interviews',
              icon: Icons.groups_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _QuickStat(
              count: applications.where((a) => a.status == 'offer').length,
              label: 'Offers',
              icon: Icons.celebration_rounded,
              color: AppColors.sunglow,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _QuickStat(
              count: JobsStore.jobBoard.where((j) => j['saved'] == true).length,
              label: 'Saved',
              icon: Icons.bookmark_rounded,
              color: AppColors.splashPurple,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Recommended for You',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
            const Spacer(),
            Text('${recommendedJobs.length} jobs',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ),
        const SizedBox(height: 10),
        if (recommendedJobs.isEmpty)
          _EmptyState(
            icon: Icons.search_rounded,
            title: 'No matches yet',
            subtitle: 'Complete your profile to get personalized recommendations',
            isDark: isDark,
          )
        else
          ...recommendedJobs.map((j) => JobCard(
                job: j,
                isApplied: isApplied(j),
                matchScore: matchScore(j),
                onSave: () => onSave(j),
                onTap: () => onTap(j),
              )),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TAB: BROWSE
// ════════════════════════════════════════════════════════════

class _BrowseTab extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final String activeFilter;
  final String searchQuery;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> filteredJobs;
  final bool Function(Map) isApplied;
  final void Function(Map<String, dynamic>) onSave;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String) onFilterChanged;
  final void Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilter;

  const _BrowseTab({
    required this.isDark,
    required this.textColor,
    required this.activeFilter,
    required this.searchQuery,
    required this.searchController,
    required this.filteredJobs,
    required this.isApplied,
    required this.onSave,
    required this.onTap,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilter,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Remote', 'Full-time', 'Part-time', 'Contract'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: TextStyle(
                            fontSize: 14, color: isDark ? Colors.white : AppColors.darkPurple),
                        decoration: InputDecoration(
                          hintText: 'Search jobs or companies…',
                          hintStyle: TextStyle(
                              fontSize: 14, color: AppColors.mutedText.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: AppColors.mutedText),
                          suffixIcon: searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: onClearSearch,
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.mutedText))
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onOpenFilter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.7)),
                      ),
                      child: Icon(Icons.tune_rounded, color: textColor, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            itemBuilder: (_, i) {
              final f = filters[i];
              final isActive = f == activeFilter;
              return GestureDetector(
                onTap: () => onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? AppColors.wisteria : AppColors.darkPurple)
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive
                            ? (isDark ? AppColors.wisteria : AppColors.darkPurple)
                            : AppColors.mutedText.withOpacity(0.25)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? (isDark ? AppColors.darkPurple : AppColors.sunglow)
                            : AppColors.mutedText,
                      )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredJobs.isEmpty
              ? _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No jobs found',
                  subtitle: 'Try adjusting your search or filters',
                  isDark: isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filteredJobs.length,
                  itemBuilder: (_, i) => JobCard(
                    job: filteredJobs[i],
                    isApplied: isApplied(filteredJobs[i]),
                    onSave: () => onSave(filteredJobs[i]),
                    onTap: () => onTap(filteredJobs[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TAB: SAVED
// ════════════════════════════════════════════════════════════

class _SavedTab extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final List<Map<String, dynamic>> savedJobs;
  final bool Function(Map) isApplied;
  final void Function(Map<String, dynamic>) onSave;
  final void Function(Map<String, dynamic>) onTap;

  const _SavedTab({
    required this.isDark,
    required this.textColor,
    required this.savedJobs,
    required this.isApplied,
    required this.onSave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (savedJobs.isEmpty) {
      return _EmptyState(
        icon: Icons.bookmark_outline_rounded,
        title: 'No saved jobs',
        subtitle: 'Bookmark jobs you\'re interested in to see them here',
        isDark: isDark,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: savedJobs.length,
      itemBuilder: (_, i) => JobCard(
        job: savedJobs[i],
        isApplied: isApplied(savedJobs[i]),
        onSave: () => onSave(savedJobs[i]),
        onTap: () => onTap(savedJobs[i]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TAB: ACTIVITY (applications tracker)
// ════════════════════════════════════════════════════════════

class _ActivityTab extends StatefulWidget {
  final bool isDark;
  final Color textColor;
  final List<AppEntry> applications;
  final VoidCallback onStatusChanged;

  const _ActivityTab({
    required this.isDark,
    required this.textColor,
    required this.applications,
    required this.onStatusChanged,
  });

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  String _filter = 'All';

  List<AppEntry> get _filtered {
    if (_filter == 'All') return widget.applications;
    return widget.applications
        .where((a) => a.status == _filter.toLowerCase())
        .toList();
  }

  int _countByStatus(String s) =>
      widget.applications.where((a) => a.status == s).length;

  @override
  Widget build(BuildContext context) {
    if (widget.applications.isEmpty) {
      return _EmptyState(
        icon: Icons.work_off_outlined,
        title: 'No applications yet',
        subtitle: 'Apply to jobs and track your progress here',
        isDark: widget.isDark,
      );
    }

    final statuses = ['applied', 'reviewing', 'interview', 'offer', 'rejected', 'ghosted'];
    final filters = ['All', 'Applied', 'Reviewing', 'Interview', 'Offer', 'Rejected', 'Ghosted'];

    return Column(
      children: [
        // Stats grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: statuses.take(3).map((s) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: seekerStatusColor(s).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: seekerStatusColor(s).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(seekerStatusIcon(s), color: seekerStatusColor(s), size: 15),
                        ),
                        const SizedBox(height: 5),
                        Text('${_countByStatus(s)}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: widget.isDark ? Colors.white : AppColors.darkPurple)),
                        Text(seekerStatusLabels[s]!,
                            style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: statuses.skip(3).map((s) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: seekerStatusColor(s).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: seekerStatusColor(s).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(seekerStatusIcon(s), color: seekerStatusColor(s), size: 15),
                        ),
                        const SizedBox(height: 5),
                        Text('${_countByStatus(s)}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: widget.isDark ? Colors.white : AppColors.darkPurple)),
                        Text(seekerStatusLabels[s]!,
                            style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filters.map((f) {
              final isActive = _filter == f;
              final key = f == 'All' ? 'all' : f.toLowerCase();
              final chipColor = f == 'All' ? AppColors.wisteria : seekerStatusColor(key);
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? chipColor.withOpacity(0.15)
                        : (widget.isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive ? chipColor.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isActive ? chipColor : AppColors.mutedText)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filtered.isEmpty
              ? _EmptyState(
                  icon: Icons.filter_list_off_rounded,
                  title: 'No applications in this stage',
                  subtitle: 'Swipe a different status to see them',
                  isDark: widget.isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final entry = _filtered[i];
                    return _AppEntryCard(
                      entry: entry,
                      isDark: widget.isDark,
                      textColor: widget.textColor,
                      onUpdateStatus: (s) {
                        setState(() => entry.status = s);
                        widget.onStatusChanged();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AppEntryCard extends StatelessWidget {
  final AppEntry entry;
  final bool isDark;
  final Color textColor;
  final void Function(String) onUpdateStatus;

  const _AppEntryCard({
    required this.entry,
    required this.isDark,
    required this.textColor,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = seekerStatusColor(entry.status);
    final statusLabel = seekerStatusLabels[entry.status] ?? entry.status;
    final statusIcon = seekerStatusIcon(entry.status);
    final logoColor = Color(entry.colorValue);

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _StatusUpdateSheet(
          entry: entry,
          onStatusChanged: onUpdateStatus,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.07) : AppColors.mutedText.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
                color: AppColors.darkPurple.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: logoColor, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(entry.logo,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(entry.jobTitle,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 10, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(entry.company,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniChip(label: entry.salary, color: AppColors.splashPurple),
                      const SizedBox(width: 6),
                      _MiniChip(label: entry.jobType, color: AppColors.wisteria),
                      const SizedBox(width: 6),
                      _MiniChip(
                        label: entry.easyApply ? '⚡ Easy Apply' : '📄 With CV',
                        color: entry.easyApply ? const Color(0xFF8B6914) : AppColors.mutedText,
                        bg: entry.easyApply
                            ? AppColors.sunglow.withOpacity(0.12)
                            : AppColors.mutedText.withOpacity(0.08),
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

class _StatusUpdateSheet extends StatefulWidget {
  final AppEntry entry;
  final void Function(String) onStatusChanged;

  const _StatusUpdateSheet({required this.entry, required this.onStatusChanged});

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
            Container(
              width: 36, height: 4,
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
                  Text('Update Status',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 2),
                  Text('${widget.entry.jobTitle} at ${widget.entry.company}',
                      style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                ],
              ),
            ),
            Divider(color: AppColors.mutedText.withOpacity(0.12), height: 1),
            ...seekerStatusLabels.entries.map((e) {
              final isSelected = _selected == e.key;
              final color = seekerStatusColor(e.key);
              final icon = seekerStatusIcon(e.key);
              return ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = e.key);
                  widget.onStatusChanged(e.key);
                  Navigator.pop(context);
                },
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                title: Text(e.value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : textColor,
                    )),
                trailing: isSelected ? Icon(Icons.check_rounded, color: color, size: 20) : null,
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

// ════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ════════════════════════════════════════════════════════════

class _QuickStat extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _QuickStat({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(height: 5),
              Text('$count',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.darkPurple)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
            ],
          ),
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;

  const _MiniChip({required this.label, required this.color, this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg ?? color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: AppColors.mutedText.withOpacity(0.35)),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkPurple)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
            ],
          ),
        ),
      );
}
