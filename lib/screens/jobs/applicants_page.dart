// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'job_store.dart';

class ApplicantsPage extends StatefulWidget {
  final JobPosting posting;
  final VoidCallback onChanged;

  const ApplicantsPage({super.key, required this.posting, required this.onChanged});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  String _filter = 'All';

  static const _statuses = ['new', 'reviewing', 'interview', 'offer', 'rejected'];

  static const _statusLabels = {
    'new': 'New',
    'reviewing': 'Reviewing',
    'interview': 'Interview',
    'offer': 'Offer',
    'rejected': 'Rejected',
  };

  static Color _color(String s) {
    switch (s) {
      case 'new': return AppColors.wisteria;
      case 'reviewing': return const Color(0xFFF59E0B);
      case 'interview': return const Color(0xFF10B981);
      case 'offer': return AppColors.sunglow;
      case 'rejected': return Colors.redAccent;
      default: return AppColors.mutedText;
    }
  }

  static IconData _icon(String s) {
    switch (s) {
      case 'new': return Icons.fiber_new_rounded;
      case 'reviewing': return Icons.visibility_rounded;
      case 'interview': return Icons.groups_rounded;
      case 'offer': return Icons.celebration_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.circle;
    }
  }

  List<Applicant> get _filtered {
    if (_filter == 'All') return widget.posting.applicants;
    return widget.posting.applicants.where((a) => a.status == _filter.toLowerCase()).toList();
  }

  void _moveStatus(Applicant a, String newStatus) {
    setState(() => a.status = newStatus);
    widget.onChanged();
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
                          Text(widget.posting.title,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                          Text(
                            '${widget.posting.applicantCount} applicant${widget.posting.applicantCount == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Pipeline stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _statuses.map((s) {
                    final count = widget.posting.applicants.where((a) => a.status == s).length;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _color(s).withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text('$count',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: count > 0 ? _color(s) : AppColors.mutedText)),
                            Text(_statusLabels[s]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', ...(_statusLabels.values)].map((f) {
                    final isActive = _filter == f;
                    final key = f == 'All' ? 'All' : _statusLabels.entries
                        .firstWhere((e) => e.value == f, orElse: () => MapEntry('All', f))
                        .key;
                    final chipColor = f == 'All' ? AppColors.wisteria : _color(key);
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive
                              ? chipColor.withOpacity(0.15)
                              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? chipColor.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                          ),
                        ),
                        child: Text(f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? chipColor : AppColors.mutedText,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Candidate list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 52, color: AppColors.mutedText.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No applicants here',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 4),
                            const Text('Check back later or share your job post',
                                style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _CandidateCard(
                          applicant: _filtered[i],
                          isDark: isDark,
                          textColor: textColor,
                          statusColor: _color(_filtered[i].status),
                          statusLabel: _statusLabels[_filtered[i].status] ?? _filtered[i].status,
                          statusIcon: _icon(_filtered[i].status),
                          onTap: () => _showDetail(context, _filtered[i]),
                          onMove: (s) => _moveStatus(_filtered[i], s),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Applicant a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CandidateDetailSheet(
        applicant: a,
        statusColor: _color(a.status),
        statusLabel: _statusLabels[a.status] ?? a.status,
        statusLabels: _statusLabels,
        statusColor2: _color,
        statusIcon2: _icon,
        onStatusChanged: (s) {
          setState(() => a.status = s);
          widget.onChanged();
        },
      ),
    );
  }
}

// ── Candidate Card ──

class _CandidateCard extends StatelessWidget {
  final Applicant applicant;
  final bool isDark;
  final Color textColor;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final VoidCallback onTap;
  final void Function(String) onMove;

  const _CandidateCard({
    required this.applicant,
    required this.isDark,
    required this.textColor,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.07) : AppColors.mutedText.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPurple.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Color(applicant.avatarColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(applicant.avatarInitial,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant.name,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                      Text(applicant.currentRole,
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.wisteria.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('${applicant.experience} exp',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.wisteria)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: applicant.appliedMethod == 'easy'
                        ? AppColors.sunglow.withOpacity(0.12)
                        : AppColors.mutedText.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    applicant.appliedMethod == 'easy' ? '⚡ Easy Apply' : '📄 With CV',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: applicant.appliedMethod == 'easy'
                          ? const Color(0xFF8B6914)
                          : AppColors.mutedText,
                    ),
                  ),
                ),
                const Spacer(),
                Text(applicant.appliedAt,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: applicant.skills.take(4).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.splashPurple.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.splashPurple)),
                  )).toList(),
            ),
            const SizedBox(height: 12),
            // Quick action buttons
            Row(
              children: [
                if (applicant.status == 'new') ...[
                  _ActionBtn(
                      label: 'Review',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.visibility_rounded,
                      onTap: () => onMove('reviewing')),
                  const SizedBox(width: 8),
                ],
                if (applicant.status == 'reviewing') ...[
                  _ActionBtn(
                      label: 'Interview',
                      color: const Color(0xFF10B981),
                      icon: Icons.groups_rounded,
                      onTap: () => onMove('interview')),
                  const SizedBox(width: 8),
                ],
                if (applicant.status == 'interview') ...[
                  _ActionBtn(
                      label: 'Send Offer',
                      color: AppColors.sunglow,
                      icon: Icons.celebration_rounded,
                      onTap: () => onMove('offer')),
                  const SizedBox(width: 8),
                ],
                if (applicant.status != 'rejected' && applicant.status != 'offer')
                  _ActionBtn(
                      label: 'Reject',
                      color: Colors.redAccent,
                      icon: Icons.close_rounded,
                      outlined: true,
                      onTap: () => onMove('rejected')),
                if (applicant.status == 'offer')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.sunglow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.celebration_rounded, size: 14, color: AppColors.sunglow),
                        SizedBox(width: 5),
                        Text('Offer Sent',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sunglow)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(outlined ? 0.6 : 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );
}

// ── Candidate Detail Sheet ──

class _CandidateDetailSheet extends StatefulWidget {
  final Applicant applicant;
  final Color statusColor;
  final String statusLabel;
  final Map<String, String> statusLabels;
  final Color Function(String) statusColor2;
  final IconData Function(String) statusIcon2;
  final void Function(String) onStatusChanged;

  const _CandidateDetailSheet({
    required this.applicant,
    required this.statusColor,
    required this.statusLabel,
    required this.statusLabels,
    required this.statusColor2,
    required this.statusIcon2,
    required this.onStatusChanged,
  });

  @override
  State<_CandidateDetailSheet> createState() => _CandidateDetailSheetState();
}

class _CandidateDetailSheetState extends State<_CandidateDetailSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.applicant.status;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final a = widget.applicant;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Color(a.avatarColor),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(a.avatarInitial,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name,
                                    style: TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                                Text(a.currentRole,
                                    style: const TextStyle(fontSize: 14, color: AppColors.mutedText)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                              icon: Icons.access_time_rounded,
                              label: '${a.experience} experience'),
                          _DetailChip(
                              icon: a.appliedMethod == 'easy'
                                  ? Icons.bolt_rounded
                                  : Icons.attach_file_rounded,
                              label: a.appliedMethod == 'easy' ? 'Easy Apply' : 'Applied with CV'),
                          _DetailChip(icon: Icons.schedule_rounded, label: 'Applied ${a.appliedAt}'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Skills',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: a.skills.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.splashPurple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.splashPurple.withOpacity(0.2)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.splashPurple)),
                            )).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text('Update Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 12),
                      ...widget.statusLabels.entries.map((e) {
                        final isSelected = _selected == e.key;
                        final color = widget.statusColor2(e.key);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = e.key);
                            widget.onStatusChanged(e.key);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color.withOpacity(0.4) : AppColors.mutedText.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(widget.statusIcon2(e.key), color: color, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(e.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? color : textColor,
                                      )),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded, color: color, size: 18),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.wisteria),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.wisteria)),
          ],
        ),
      );
}
