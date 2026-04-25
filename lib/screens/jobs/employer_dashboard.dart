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
  bool _editingName = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = JobsStore.companyName;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Widget _buildCompanyCard(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.darkCard, AppColors.darkCard.withOpacity(0.8)]
                    : [Colors.white, Colors.white.withOpacity(0.9)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.wisteria.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.splashPurple, AppColors.wisteria]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      JobsStore.companyName.isNotEmpty ? JobsStore.companyName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _editingName
                      ? TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Company name',
                            border: InputBorder.none,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  JobsStore.companyName = _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : 'Your Company';
                                  _editingName = false;
                                });
                              },
                              child: const Icon(Icons.check_rounded,
                                  color: Color(0xFF10B981), size: 20),
                            ),
                          ),
                          onSubmitted: (v) {
                            setState(() {
                              JobsStore.companyName = v.trim().isNotEmpty ? v.trim() : 'Your Company';
                              _editingName = false;
                            });
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(JobsStore.companyName,
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _editingName = true),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.mutedText),
                                ),
                              ],
                            ),
                            Text(JobsStore.companyIndustry,
                                style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
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
