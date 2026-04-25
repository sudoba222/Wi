// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';

// ════════════════════════════════════════════════════════════
//  JOB CARD
// ════════════════════════════════════════════════════════════

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isApplied;
  final int matchScore;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.isApplied,
    required this.onSave,
    required this.onTap,
    this.matchScore = 0,
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
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      if (matchScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _matchColor(matchScore).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _matchColor(matchScore).withOpacity(0.3)),
                          ),
                          child: Text(
                            '$matchScore% match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _matchColor(matchScore),
                            ),
                          ),
                        )
                      else if (isApplied)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
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
                            color: (job['saved'] as bool) ? AppColors.sunglow : AppColors.mutedText,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    job['title'] as String,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.mutedText),
                      const SizedBox(width: 3),
                      Text(
                        job['location'] as String,
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                      ),
                      const SizedBox(width: 10),
                      _TypeChip(label: job['type'] as String),
                      if (job['isRemote'] as bool) ...[
                        const SizedBox(width: 6),
                        _RemoteChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
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

  Color _matchColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return AppColors.sunglow;
    return AppColors.mutedText;
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.splashPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _RemoteChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
      );
}

// ════════════════════════════════════════════════════════════
//  JOB DETAIL BOTTOM SHEET
// ════════════════════════════════════════════════════════════

class JobDetailSheet extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isApplied;
  final UserProfile? userProfile;
  final void Function(bool easyApply) onApply;

  const JobDetailSheet({
    super.key,
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
            ),
          ),
          child: Column(
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(icon: Icons.location_on_outlined, label: job['location'] as String),
                          InfoChip(icon: Icons.work_outline_rounded, label: job['type'] as String),
                          InfoChip(icon: Icons.attach_money_rounded, label: job['salary'] as String),
                          if (job['isRemote'] as bool)
                            InfoChip(icon: Icons.laptop_rounded, label: 'Remote OK', highlight: true),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('About the role', isDark),
                      const SizedBox(height: 10),
                      Text(
                        'We are looking for a talented ${job['title']} to join ${job['company']} in ${job['location']}. '
                        'You will be part of a dynamic team building innovative products for Tajikistan '
                        'and the broader Central Asia market.\n\n'
                        'This is a ${(job['type'] as String).toLowerCase()} position with a competitive salary of ${job['salary']}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedText,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Requirements', isDark),
                      const SizedBox(height: 10),
                      ...const [
                        '2+ years of relevant experience',
                        'Strong communication in Tajik, Russian or English',
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
                                child: Icon(Icons.check_circle_rounded,
                                    size: 15, color: AppColors.wisteria),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(r,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.mutedText,
                                        height: 1.5)),
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
              if (isApplied)
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => EasyApplySheet(
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
                                Text('⚡', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text('Easy Apply',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkPurple)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => ApplyWithCvSheet(
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
                              border: Border.all(color: AppColors.wisteria, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📄', style: TextStyle(fontSize: 16)),
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

class EasyApplySheet extends StatefulWidget {
  final String jobTitle;
  final String company;
  final UserProfile? userProfile;
  final VoidCallback onApply;

  const EasyApplySheet({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.onApply,
    this.userProfile,
  });

  @override
  State<EasyApplySheet> createState() => _EasyApplySheetState();
}

class _EasyApplySheetState extends State<EasyApplySheet> {
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
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : AppColors.background;
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2);
    final name = widget.userProfile?.name.isNotEmpty == true ? widget.userProfile!.name : 'Your Name';
    final role = widget.userProfile?.jobTitle.isNotEmpty == true
        ? widget.userProfile!.jobTitle
        : 'Your current role';
    final initial = name[0].toUpperCase();

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('Easy Apply',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${widget.jobTitle} at ${widget.company}',
                      style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.mutedText.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
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
                                      child: Text(initial,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(initial,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                              Text(role,
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: AppColors.wisteria, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.mutedText.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),
                  _FieldLabel('Phone Number', textColor),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _phoneController,
                    hint: 'Phone number',
                    keyboardType: TextInputType.phone,
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Cover Note', textColor),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _noteController,
                    hint: 'Add a short note… (optional)',
                    maxLines: 4,
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder,
                  ),
                  const SizedBox(height: 24),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Apply Now →',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
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
//  APPLY WITH CV SHEET
// ════════════════════════════════════════════════════════════

class ApplyWithCvSheet extends StatefulWidget {
  final String jobTitle;
  final String company;
  final VoidCallback onApply;

  const ApplyWithCvSheet({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.onApply,
  });

  @override
  State<ApplyWithCvSheet> createState() => _ApplyWithCvSheetState();
}

class _ApplyWithCvSheetState extends State<ApplyWithCvSheet> {
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
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : AppColors.background;
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2);

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('📄', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('Apply with CV',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${widget.jobTitle} at ${widget.company}',
                      style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                  const SizedBox(height: 20),
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
                            : (isDark ? Colors.white.withOpacity(0.04) : AppColors.background),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _cvSelected
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : AppColors.mutedText.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _cvSelected
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 32),
                              SizedBox(height: 8),
                              Text('Resume.pdf',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981))),
                              SizedBox(height: 2),
                              Text('Ready to submit',
                                  style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            ])
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.upload_file_rounded,
                                  color: AppColors.mutedText.withOpacity(0.6), size: 32),
                              const SizedBox(height: 8),
                              Text('Upload CV',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 2),
                              const Text('PDF, DOC or DOCX · max 5MB',
                                  style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Cover Letter', textColor),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _coverController,
                    hint: 'Introduce yourself to the hiring team… (optional)',
                    maxLines: 5,
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder,
                  ),
                  const SizedBox(height: 24),
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
                        disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Submit Application →',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
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
//  INFO CHIP
// ════════════════════════════════════════════════════════════

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const InfoChip({super.key, required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: highlight ? AppColors.sunglow.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight ? AppColors.sunglow.withOpacity(0.4) : AppColors.mutedText.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: highlight ? const Color(0xFF8B6914) : AppColors.mutedText),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: highlight ? const Color(0xFF8B6914) : AppColors.mutedText,
                )),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  ADVANCED FILTER SHEET
// ════════════════════════════════════════════════════════════

class AdvancedFilterSheet extends StatefulWidget {
  final String activeFilter;
  final void Function(String) onFilterChanged;

  const AdvancedFilterSheet({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
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
              width: 36, height: 4,
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
                  Text('Filter Jobs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      widget.onFilterChanged('All');
                      Navigator.pop(context);
                    },
                    child: const Text('Reset',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.wisteria)),
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
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sunglow.withOpacity(0.15)
                        : AppColors.mutedText.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18,
                      color: isSelected ? AppColors.sunglow : AppColors.mutedText),
                ),
                title: Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.sunglow : AppColors.darkPurple)
                          : textColor,
                    )),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.sunglow, size: 20)
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

// ════════════════════════════════════════════════════════════
//  SHARED HELPER WIDGETS
// ════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionTitle(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.darkPurple,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
      );
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: maxLines > 1 ? 14 : 15, color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6), fontSize: 14),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.wisteria, width: 1.5),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  STATUS HELPERS (shared across seeker + employer)
// ════════════════════════════════════════════════════════════

const seekerStatusLabels = {
  'applied': 'Applied',
  'reviewing': 'Reviewing',
  'interview': 'Interview',
  'offer': 'Offer',
  'rejected': 'Rejected',
  'ghosted': 'Ghosted',
};

Color seekerStatusColor(String status) {
  switch (status) {
    case 'applied': return AppColors.wisteria;
    case 'reviewing': return const Color(0xFFF59E0B);
    case 'interview': return const Color(0xFF10B981);
    case 'offer': return AppColors.sunglow;
    case 'rejected': return Colors.redAccent;
    case 'ghosted': return Colors.grey;
    default: return AppColors.mutedText;
  }
}

IconData seekerStatusIcon(String status) {
  switch (status) {
    case 'applied': return Icons.send_rounded;
    case 'reviewing': return Icons.visibility_rounded;
    case 'interview': return Icons.groups_rounded;
    case 'offer': return Icons.celebration_rounded;
    case 'rejected': return Icons.cancel_rounded;
    case 'ghosted': return Icons.visibility_off_rounded;
    default: return Icons.circle;
  }
}
