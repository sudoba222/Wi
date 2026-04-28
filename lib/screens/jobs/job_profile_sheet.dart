// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import 'job_store.dart';

/// Bottom sheet that lets job seekers view and edit their job profile.
/// Phone, location, summary, LinkedIn, and CV are stored in [JobsStore.seekerProfile].
/// Skills and experience shown from [UserProfile] (with a note to edit in main profile).
class JobProfileSheet extends StatefulWidget {
  final UserProfile? userProfile;

  const JobProfileSheet({super.key, this.userProfile});

  @override
  State<JobProfileSheet> createState() => _JobProfileSheetState();
}

class _JobProfileSheetState extends State<JobProfileSheet> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _linkedInCtrl;
  late final TextEditingController _portfolioCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final sp = JobsStore.seekerProfile;
    _phoneCtrl    = TextEditingController(text: sp.phone);
    _locationCtrl = TextEditingController(text: sp.location);
    _summaryCtrl  = TextEditingController(text: sp.summary);
    _linkedInCtrl = TextEditingController(text: sp.linkedIn);
    _portfolioCtrl = TextEditingController(text: sp.portfolioUrl);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _summaryCtrl.dispose();
    _linkedInCtrl.dispose();
    _portfolioCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    HapticFeedback.lightImpact();
    final sp = JobsStore.seekerProfile;
    sp.phone        = _phoneCtrl.text.trim();
    sp.location     = _locationCtrl.text.trim();
    sp.summary      = _summaryCtrl.text.trim();
    sp.linkedIn     = _linkedInCtrl.text.trim();
    sp.portfolioUrl = _portfolioCtrl.text.trim();
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _simulateCvUpload() {
    HapticFeedback.mediumImpact();
    setState(() {
      final sp = JobsStore.seekerProfile;
      sp.cvUploaded   = true;
      sp.cvFileName   = 'My_Resume.pdf';
      sp.cvUploadedAt = 'just now';
    });
  }

  void _removeCv() {
    setState(() {
      final sp = JobsStore.seekerProfile;
      sp.cvUploaded   = false;
      sp.cvFileName   = '';
      sp.cvUploadedAt = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = JobsStore.seekerProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard.withOpacity(0.98) : Colors.white.withOpacity(0.98);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final skills = widget.userProfile?.skills ?? [];

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
              // Handle
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job Profile',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                          Text('Pre-fills Easy Apply everywhere',
                              style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    // Completion badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _completionColor(sp.completionPct).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _completionColor(sp.completionPct).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${sp.completionPct}% complete',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _completionColor(sp.completionPct),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.mutedText.withOpacity(0.1)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Contact info ─────────────────────────────────────
                      _SectionHeader(icon: Icons.contact_phone_outlined, label: 'Contact', textColor: textColor),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        hint: '+992 900 000 000',
                        icon: Icons.phone_outlined,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        controller: _locationCtrl,
                        label: 'Location',
                        hint: 'Dushanbe, Tajikistan',
                        icon: Icons.location_on_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        controller: _linkedInCtrl,
                        label: 'LinkedIn',
                        hint: 'linkedin.com/in/yourname',
                        icon: Icons.link_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        controller: _portfolioCtrl,
                        label: 'Portfolio / Website',
                        hint: 'yoursite.com',
                        icon: Icons.open_in_browser_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 28),

                      // ── Professional summary ─────────────────────────────
                      _SectionHeader(icon: Icons.edit_note_rounded, label: 'Professional Summary', textColor: textColor),
                      const SizedBox(height: 6),
                      Text('Shown at the top of every Easy Apply application.',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
                        ),
                        child: TextField(
                          controller: _summaryCtrl,
                          maxLines: 4,
                          maxLength: 350,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Write 2–3 sentences about your experience and what you\'re looking for...',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.6)),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                            counterStyle: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── CV section ───────────────────────────────────────
                      _SectionHeader(icon: Icons.description_outlined, label: 'Your CV', textColor: textColor),
                      const SizedBox(height: 6),
                      Text('Upload once — auto-used for every "Apply with CV" application.',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                      const SizedBox(height: 14),
                      if (sp.cvUploaded)
                        _CvCard(
                          fileName: sp.cvFileName,
                          uploadedAt: sp.cvUploadedAt,
                          onReplace: _simulateCvUpload,
                          onRemove: _removeCv,
                          isDark: isDark,
                        )
                      else
                        _CvUploadArea(onUpload: _simulateCvUpload, isDark: isDark),
                      const SizedBox(height: 28),

                      // ── Skills from UserProfile ───────────────────────────
                      if (skills.isNotEmpty) ...[
                        _SectionHeader(icon: Icons.psychology_outlined, label: 'Skills', textColor: textColor),
                        const SizedBox(height: 6),
                        Text('From your main profile. Edit via Profile → Edit.',
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: skills.map((s) => _SkillChip(label: s, isDark: isDark)).toList(),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── Experience snippet ────────────────────────────────
                      if (widget.userProfile != null) ...[
                        _SectionHeader(icon: Icons.work_outline_rounded, label: 'Current Position', textColor: textColor),
                        const SizedBox(height: 12),
                        _PositionCard(userProfile: widget.userProfile!, isDark: isDark),
                        const SizedBox(height: 28),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // ── Save button ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: bg,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12, offset: const Offset(0, -4),
                  )],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saved
                      ? Container(
                          key: const ValueKey('saved'),
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Profile saved!',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('save'),
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sunglow,
                              foregroundColor: AppColors.darkPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Save Job Profile',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Color _completionColor(int pct) {
    if (pct >= 75) return const Color(0xFF10B981);
    if (pct >= 40) return AppColors.sunglow;
    return AppColors.mutedText;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  const _SectionHeader({required this.icon, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.wisteria),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2),
        )],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.darkPurple),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.5)),
          prefixIcon: Icon(icon, size: 18, color: AppColors.wisteria),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  final String fileName, uploadedAt;
  final VoidCallback onReplace, onRemove;
  final bool isDark;
  const _CvCard({
    required this.fileName, required this.uploadedAt,
    required this.onReplace, required this.onRemove, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                Text('Uploaded $uploadedAt · Auto-used on Apply with CV',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'replace') onReplace();
              if (v == 'remove') onRemove();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'replace', child: Text('Replace CV')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
            icon: Icon(Icons.more_vert_rounded, color: AppColors.mutedText, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CvUploadArea extends StatelessWidget {
  final VoidCallback onUpload;
  final bool isDark;
  const _CvUploadArea({required this.onUpload, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.wisteria.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.wisteria.withOpacity(0.25),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.wisteria.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded, color: AppColors.wisteria, size: 26),
            ),
            const SizedBox(height: 12),
            const Text('Tap to upload your CV',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.wisteria)),
            const SizedBox(height: 4),
            const Text('PDF or DOCX — max 5 MB',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SkillChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.wisteria.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.wisteria.withOpacity(0.25)),
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.splashPurple)),
  );
}

class _PositionCard extends StatelessWidget {
  final UserProfile userProfile;
  final bool isDark;
  const _PositionCard({required this.userProfile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mutedText.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_center_outlined, color: AppColors.wisteria, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.jobTitle.isNotEmpty ? userProfile.jobTitle : 'No title set',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkPurple,
                  ),
                ),
                if (userProfile.company.isNotEmpty)
                  Text(userProfile.company,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
