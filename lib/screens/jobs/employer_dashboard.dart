// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'job_store.dart';
import 'post_job_sheet.dart';
import 'applicants_page.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  @override
  void dispose() {
    super.dispose();
  }

  void _postJob() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostJobSheet(onSaved: () => setState(() {})),
    );
  }

  void _editJob(JobPosting posting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostJobSheet(
        editing: posting,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openApplicants(JobPosting posting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicantsPage(
          posting: posting,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  void _toggleStatus(JobPosting p) {
    setState(() {
      p.status = p.status == 'active' ? 'paused' : 'active';
    });
  }

  void _deletePosting(JobPosting p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text('Remove "${p.title}" from your active listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => JobsStore.employerPostings.remove(p));
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark, textColor)),
              SliverToBoxAdapter(child: _buildCompanyCard(isDark, textColor)),
              SliverToBoxAdapter(child: _buildStatsGrid(isDark, textColor)),
              SliverToBoxAdapter(child: _buildSectionTitle('Active Listings', isDark, textColor,
                  trailing: Text(
                    '${JobsStore.activeListings} active',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ))),
              if (JobsStore.employerPostings.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyListings(isDark, textColor))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _ListingCard(
                        posting: JobsStore.employerPostings[i],
                        isDark: isDark,
                        textColor: textColor,
                        onViewApplicants: () => _openApplicants(JobsStore.employerPostings[i]),
                        onEdit: () => _editJob(JobsStore.employerPostings[i]),
                        onToggleStatus: () => _toggleStatus(JobsStore.employerPostings[i]),
                        onDelete: () => _deletePosting(JobsStore.employerPostings[i]),
                      ),
                    ),
                    childCount: JobsStore.employerPostings.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _postJob,
        backgroundColor: AppColors.sunglow,
        foregroundColor: AppColors.darkPurple,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a Job', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            child: Text('Employer HQ',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: textColor,
                    letterSpacing: -0.3)),
          ),
          GestureDetector(
            onTap: _postJob,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.sunglow,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.sunglow.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.darkPurple, size: 18),
                      SizedBox(width: 4),
                      Text('Post Job',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkPurple)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCompanyProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompanyProfileSheet(onSaved: () => setState(() {})),
    );
  }

  Widget _buildCompanyCard(bool isDark, Color textColor) {
    final cp = JobsStore.companyProfile;
    final logoColor = Color(cp.logoColor);
    final initial = cp.logoInitial.isNotEmpty ? cp.logoInitial : (cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C');
    final completion = cp.completionPct;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: _openCompanyProfile,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                boxShadow: [BoxShadow(
                    color: AppColors.wisteria.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: logoColor, borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Text(initial,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(JobsStore.companyName,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                          Row(children: [
                            if (cp.industry.isNotEmpty)
                              Text(cp.industry,
                                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                            if (cp.industry.isNotEmpty && cp.size.isNotEmpty)
                              const Text(' · ', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                            if (cp.size.isNotEmpty)
                              Text('${cp.size} employees',
                                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                          ]),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.edit_outlined, size: 13, color: AppColors.mutedText),
                          const SizedBox(width: 4),
                          const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                  if (cp.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(cp.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedText, height: 1.5)),
                  ],
                  // Profile completeness bar
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Profile $completion% complete',
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 4,
                          backgroundColor: AppColors.mutedText.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(
                            completion >= 80 ? const Color(0xFF10B981) : AppColors.sunglow,
                          ),
                        ),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    if (completion < 100)
                      Text('${100 - completion}% left',
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, Color textColor) {
    final stats = [
      (JobsStore.activeListings, 'Active Listings', Icons.work_rounded, AppColors.splashPurple),
      (JobsStore.totalApplicants, 'Total Applicants', Icons.people_rounded, AppColors.wisteria),
      (JobsStore.totalViews, 'Profile Views', Icons.visibility_rounded, const Color(0xFF0984E3)),
      (JobsStore.totalHires, 'Offers Sent', Icons.celebration_rounded, AppColors.sunglow),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Row(
            children: stats.take(2).map((s) {
              final (count, label, icon, color) = s;
              return Expanded(
                child: _StatCard(
                  count: count, label: label, icon: icon, color: color, isDark: isDark,
                  margin: EdgeInsets.only(right: stats.indexOf(s) == 0 ? 6 : 0),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: stats.skip(2).map((s) {
              final (count, label, icon, color) = s;
              return Expanded(
                child: _StatCard(
                  count: count, label: label, icon: icon, color: color, isDark: isDark,
                  margin: EdgeInsets.only(right: stats.indexOf(s) == 2 ? 6 : 0),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, Color textColor, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.2)),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
  }

  Widget _buildEmptyListings(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.sunglow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.post_add_rounded, size: 38, color: AppColors.sunglow),
          ),
          const SizedBox(height: 16),
          Text('No listings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          const Text('Post your first job to start receiving applications',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _postJob,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.sunglow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.sunglow.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Text('Post Your First Job 🚀',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkPurple)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final EdgeInsets margin;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: AppColors.darkPurple.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: count.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, v, child) => Text(
                    '${v.toInt()}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.darkPurple),
                  ),
                ),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ],
            ),
          ],
        ),
      );
}

// ── Listing Card ──

class _ListingCard extends StatelessWidget {
  final JobPosting posting;
  final bool isDark;
  final Color textColor;
  final VoidCallback onViewApplicants;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.posting,
    required this.isDark,
    required this.textColor,
    required this.onViewApplicants,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = posting.status == 'active';
    final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final reviewingPct = posting.applicantCount > 0
        ? (posting.reviewingCount + posting.interviewCount + posting.offerCount) /
            posting.applicantCount
        : 0.0;
    final interviewPct =
        posting.applicantCount > 0 ? posting.interviewCount / posting.applicantCount : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.wisteria.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(posting.title,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _PostingChip(
                                label: posting.type, color: AppColors.splashPurple,
                                bg: AppColors.wisteria.withOpacity(0.1)),
                            _PostingChip(
                                label: posting.workStyle == 'remote'
                                    ? 'Remote'
                                    : posting.workStyle == 'onsite'
                                        ? 'On-site'
                                        : 'Hybrid',
                                color: const Color(0xFF8B6914),
                                bg: AppColors.sunglow.withOpacity(0.12)),
                            _PostingChip(
                                label: '\$${posting.salaryMin}–${posting.salaryMax}/mo',
                                color: AppColors.splashPurple,
                                bg: AppColors.splashPurple.withOpacity(0.06)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onToggleStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text(isActive ? 'Active' : 'Paused',
                                  style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: statusColor)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${posting.viewCount} views',
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Pipeline progress
              if (posting.applicantCount > 0) ...[
                Row(
                  children: [
                    Text('${posting.applicantCount} applicant${posting.applicantCount == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const Spacer(),
                    if (posting.newCount > 0)
                      _PipelineBadge(count: posting.newCount, label: 'New', color: AppColors.wisteria),
                    const SizedBox(width: 6),
                    if (posting.interviewCount > 0)
                      _PipelineBadge(
                          count: posting.interviewCount,
                          label: 'Interview',
                          color: const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    if (posting.offerCount > 0)
                      _PipelineBadge(
                          count: posting.offerCount, label: 'Offer', color: AppColors.sunglow),
                  ],
                ),
                const SizedBox(height: 8),
                // Multi-bar progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                          height: 6,
                          decoration: BoxDecoration(
                              color: AppColors.mutedText.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4))),
                      FractionallySizedBox(
                        widthFactor: reviewingPct.clamp(0, 1),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: interviewPct.clamp(0, 1),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ProgressLegend(color: AppColors.wisteria, label: 'Applied'),
                    const SizedBox(width: 10),
                    _ProgressLegend(color: const Color(0xFFF59E0B), label: 'Reviewing'),
                    const SizedBox(width: 10),
                    _ProgressLegend(color: const Color(0xFF10B981), label: 'Interview'),
                  ],
                ),
                const SizedBox(height: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mutedText.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 14, color: AppColors.mutedText),
                      SizedBox(width: 6),
                      Text('No applicants yet',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onViewApplicants();
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.darkPurple,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.darkPurple.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'View Applicants${posting.applicantCount > 0 ? ' (${posting.applicantCount})' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SmallActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.wisteria,
                      isDark: isDark,
                      onTap: onEdit),
                  const SizedBox(width: 8),
                  _SmallActionBtn(
                      icon: isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: onToggleStatus),
                  const SizedBox(width: 8),
                  _SmallActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      isDark: isDark,
                      onTap: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostingChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _PostingChip({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );
}

class _PipelineBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _PipelineBadge({required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$count $label',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

class _ProgressLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ProgressLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
        ],
      );
}

class _SmallActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _SmallActionBtn(
      {required this.icon, required this.color, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  COMPANY PROFILE SHEET
// ════════════════════════════════════════════════════════════

class _CompanyProfileSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _CompanyProfileSheet({required this.onSaved});

  @override
  State<_CompanyProfileSheet> createState() => _CompanyProfileSheetState();
}

class _CompanyProfileSheetState extends State<_CompanyProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _descCtrl;
  late String _industry;
  late String _size;
  late int _logoColor;
  bool _saved = false;

  static const _industries = [
    'Technology', 'Finance', 'Healthcare', 'Education',
    'Retail', 'Manufacturing', 'Media', 'Other',
  ];
  static const _sizes = ['1–10', '11–50', '51–200', '201–500', '500+'];
  static const _logoColors = [
    0xFF6C5CE7, 0xFF00B894, 0xFF0984E3, 0xFFFFD166,
    0xFFE84393, 0xFFE17055, 0xFF74B9FF, 0xFF210B2C,
  ];

  @override
  void initState() {
    super.initState();
    final cp = JobsStore.companyProfile;
    _nameCtrl    = TextEditingController(text: cp.name);
    _locationCtrl = TextEditingController(text: cp.location);
    _websiteCtrl = TextEditingController(text: cp.website);
    _descCtrl    = TextEditingController(text: cp.description);
    _industry    = cp.industry;
    _size        = cp.size;
    _logoColor   = cp.logoColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final cp = JobsStore.companyProfile;
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Your Company';
    cp.name        = name;
    cp.logoInitial = name[0].toUpperCase();
    cp.location    = _locationCtrl.text.trim();
    cp.website     = _websiteCtrl.text.trim();
    cp.description = _descCtrl.text.trim();
    cp.industry    = _industry;
    cp.size        = _size;
    cp.logoColor   = _logoColor;
    cp.setupComplete = true;
    setState(() => _saved = true);
    widget.onSaved();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard.withOpacity(0.98) : Colors.white.withOpacity(0.98);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3), borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Company Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                    const Text('Shown to candidates on all job listings', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                  ])),
                ]),
              ),
              Divider(height: 1, color: AppColors.mutedText.withOpacity(0.1)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo color picker
                      _Label('Company Logo Color', textColor),
                      const SizedBox(height: 10),
                      Row(children: [
                        // Preview
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Color(_logoColor), borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text(
                            _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'C',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Wrap(spacing: 8, runSpacing: 8,
                          children: _logoColors.map((c) {
                            final isSel = _logoColor == c;
                            return GestureDetector(
                              onTap: () => setState(() => _logoColor = c),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: Color(c), shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? Colors.white : Colors.transparent, width: 2.5,
                                  ),
                                  boxShadow: isSel ? [BoxShadow(color: Color(c).withOpacity(0.4), blurRadius: 6)] : [],
                                ),
                                child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                              ),
                            );
                          }).toList(),
                        )),
                      ]),
                      const SizedBox(height: 22),
                      _Label('Company Name', textColor),
                      const SizedBox(height: 8),
                      _Field(
                        controller: _nameCtrl,
                        hint: 'e.g. Alif Tech',
                        icon: Icons.business_outlined,
                        isDark: isDark,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _Label('Industry', textColor),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _industries.map((ind) {
                          final isSel = _industry == ind;
                          return GestureDetector(
                            onTap: () => setState(() => _industry = ind),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.darkPurple : (isDark ? Colors.white.withOpacity(0.07) : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                                ),
                              ),
                              child: Text(ind, style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isSel ? Colors.white : textColor)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _Label('Company Size', textColor),
                      const SizedBox(height: 10),
                      Row(children: _sizes.map((s) {
                        final isSel = _size == s;
                        return Expanded(child: GestureDetector(
                          onTap: () => setState(() => _size = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.darkPurple : (isDark ? Colors.white.withOpacity(0.07) : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                              ),
                            ),
                            child: Center(child: Text(s, style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : textColor))),
                          ),
                        ));
                      }).toList()),
                      const SizedBox(height: 16),
                      _Label('Location', textColor),
                      const SizedBox(height: 8),
                      _Field(controller: _locationCtrl, hint: 'e.g. Dushanbe, Tajikistan',
                          icon: Icons.location_on_outlined, isDark: isDark),
                      const SizedBox(height: 16),
                      _Label('Website', textColor),
                      const SizedBox(height: 8),
                      _Field(controller: _websiteCtrl, hint: 'https://yourcompany.com',
                          icon: Icons.language_rounded, isDark: isDark),
                      const SizedBox(height: 16),
                      _Label('About the company', textColor),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
                        ),
                        child: TextField(
                          controller: _descCtrl,
                          maxLines: 4, maxLength: 400,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'What does your company do? What\'s the culture like?',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.6)),
                            contentPadding: const EdgeInsets.all(14),
                            border: InputBorder.none,
                            counterStyle: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Save button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: bg,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saved
                      ? Container(
                          key: const ValueKey('saved'),
                          height: 52,
                          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Profile saved!', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ])),
                        )
                      : SizedBox(
                          key: const ValueKey('save'),
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sunglow,
                              foregroundColor: AppColors.darkPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Save Company Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.withOpacity(0.7)));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final ValueChanged<String>? onChanged;
  const _Field({required this.controller, required this.hint, required this.icon, required this.isDark, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.darkPurple),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.5)),
        prefixIcon: Icon(icon, size: 18, color: AppColors.wisteria),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

