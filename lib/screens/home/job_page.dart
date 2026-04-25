// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/auth_services.dart';
import '../jobs/job_store.dart';
import '../jobs/seeker_dashboard.dart';
import '../jobs/employer_dashboard.dart';

/// Jobs tab — two-phase UI:
/// Phase 1: Onboarding wizard (6 steps for seekers, 5 for employers).
/// Phase 2: Routes to SeekerDashboard or EmployerDashboard.

class JobPage extends StatefulWidget {
  const JobPage({super.key});

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  // ── Onboarding state (static → persists across tab switches in a session) ─
  static bool _done = false;
  static String _role = '';
  static String _category = '';
  static String _workStyle = '';
  static String _experience = '';
  static bool _cvSimulated = false;

  // ── Per-UID cache: prevents re-asking the same user after logout/login ─────
  // Resets automatically when a different UID logs in.
  static String? _lastLoadedUid;

  // ── Loading state: shown while we check Firestore for saved prefs ──────────
  bool _loadingPrefs = true;

  final _pageController = PageController();
  int _step = 0;

  // ── Seeker extra steps ────────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _summaryController = TextEditingController();

  // ── Employer extra step ───────────────────────────────────────────────────
  final _companyNameController = TextEditingController();
  String _companyIndustry = '';
  String _companySize = '';

  UserProfile? _userProfile;

  // ── Step counts ───────────────────────────────────────────────────────────
  int get _totalSteps {
    if (_role == 'seeker') return 6;
    if (_role == 'employer') return 5;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobPrefs();   // determines whether to show onboarding or dashboard
      _loadProfile();    // loads UserProfile in parallel
    });
  }

  // ── Load saved job preferences from Firestore ─────────────────────────────
  // This is the key to remembering a user's choices across logout/app-restart.
  Future<void> _loadJobPrefs() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      // Not logged in — reset everything and show onboarding
      _done = false;
      if (mounted) setState(() => _loadingPrefs = false);
      return;
    }

    // Same UID already loaded this session → use cached static state, no Firestore needed
    if (_lastLoadedUid == uid) {
      if (mounted) setState(() => _loadingPrefs = false);
      return;
    }

    // New UID (different user or first launch): reset in-memory state first
    _done = false;
    _role = '';
    _category = '';
    _workStyle = '';
    _experience = '';
    _cvSimulated = false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};

      if (data['jobOnboardingDone'] == true) {
        _done       = true;
        _role       = data['jobRole']       as String? ?? '';
        _category   = data['jobCategory']   as String? ?? '';
        _workStyle  = data['jobWorkStyle']  as String? ?? '';
        _experience = data['jobExperience'] as String? ?? '';

        if (_role == 'seeker') {
          final sp = JobsStore.seekerProfile;
          sp.phone        = data['jobPhone']       as String? ?? '';
          sp.location     = data['jobLocation']    as String? ?? '';
          sp.summary      = data['jobSummary']     as String? ?? '';
          sp.cvUploaded   = data['jobCvUploaded']  as bool?   ?? false;
          sp.cvFileName   = data['jobCvFileName']  as String? ?? '';
          sp.setupComplete = true;
        } else if (_role == 'employer') {
          final cp = JobsStore.companyProfile;
          cp.name         = data['companyName']     as String? ?? 'Your Company';
          cp.logoInitial  = cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C';
          cp.industry     = data['companyIndustry'] as String? ?? '';
          cp.size         = data['companySize']     as String? ?? '';
          cp.setupComplete = true;
        }
      }

      _lastLoadedUid = uid;
    } catch (_) {
      // Firestore unavailable — fall through to onboarding
    }

    if (mounted) setState(() => _loadingPrefs = false);
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  void _nextStep() {
    final maxStep = _totalSteps - 1;
    if (_step < maxStep) {
      _step++;
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {});
    } else {
      _finalizeSetup();
      setState(() => _done = true);
    }
  }

  void _finalizeSetup() {
    if (_role == 'seeker') {
      final sp = JobsStore.seekerProfile;
      sp.phone = _phoneController.text.trim();
      sp.location = _locationController.text.trim();
      sp.summary = _summaryController.text.trim();
      sp.cvUploaded = _cvSimulated;
      if (_cvSimulated) {
        sp.cvFileName = 'My_Resume.pdf';
        sp.cvUploadedAt = 'just now';
      }
      sp.setupComplete = true;
    } else {
      final cp = JobsStore.companyProfile;
      final rawName = _companyNameController.text.trim();
      cp.name = rawName.isNotEmpty ? rawName : 'Your Company';
      cp.logoInitial = cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C';
      cp.industry = _companyIndustry;
      cp.size = _companySize;
      cp.setupComplete = true;
    }
    _saveJobPrefsToFirestore(); // fire-and-forget persistence
  }

  // Save onboarding answers to Firestore so they survive app restarts.
  Future<void> _saveJobPrefsToFirestore() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final Map<String, dynamic> data = {
      'jobOnboardingDone': true,
      'jobRole':           _role,
      'jobCategory':       _category,
      'jobWorkStyle':      _workStyle,
      'jobExperience':     _experience,
    };

    if (_role == 'seeker') {
      final sp = JobsStore.seekerProfile;
      data.addAll({
        'jobPhone':      sp.phone,
        'jobLocation':   sp.location,
        'jobSummary':    sp.summary,
        'jobCvUploaded': sp.cvUploaded,
        'jobCvFileName': sp.cvFileName,
      });
    } else {
      final cp = JobsStore.companyProfile;
      data.addAll({
        'companyName':     cp.name,
        'companyIndustry': cp.industry,
        'companySize':     cp.size,
      });
    }

    _lastLoadedUid = uid; // mark cache as valid for this UID

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Briefly show a spinner while we check Firestore for saved preferences.
    // This prevents the onboarding from flashing before we know the user is done.
    if (_loadingPrefs) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0EAFF), AppColors.background],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.wisteria,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (!_done) return _buildOnboarding(context);
    if (_role == 'employer') return const EmployerDashboard();
    return SeekerDashboard(
      userProfile: _userProfile,
      category: _category,
      workStyle: _workStyle,
      experience: _experience,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ONBOARDING
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOnboarding(BuildContext context) {
    final steps = _totalSteps;
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
              // ── Progress bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: List.generate(steps, (i) => Expanded(
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
                  )),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Step 0 — Role
                    _StepRole(
                      selected: _role,
                      onSelect: (v) {
                        setState(() => _role = v);
                        Future.delayed(const Duration(milliseconds: 250), _nextStep);
                      },
                    ),
                    // Step 1 — Category
                    _StepCategory(
                      role: _role,
                      selected: _category,
                      onSelect: (v) => setState(() => _category = v),
                      onContinue: _nextStep,
                    ),
                    // Step 2 — Work style
                    _StepWorkStyle(
                      role: _role,
                      selected: _workStyle,
                      onSelect: (v) {
                        setState(() => _workStyle = v);
                        Future.delayed(const Duration(milliseconds: 250), _nextStep);
                      },
                    ),
                    // Step 3 — Experience
                    _StepExperience(
                      role: _role,
                      selected: _experience,
                      onSelect: (v) => setState(() => _experience = v),
                      onFinish: _nextStep,
                    ),
                    // Step 4 — Contact (seeker) / Company Setup (employer)
                    if (_role == 'employer')
                      _StepCompanySetup(
                        nameController: _companyNameController,
                        selectedIndustry: _companyIndustry,
                        onIndustryChanged: (v) => setState(() => _companyIndustry = v),
                        selectedSize: _companySize,
                        onSizeChanged: (v) => setState(() => _companySize = v),
                        onFinish: _nextStep,
                      )
                    else
                      _StepContact(
                        phoneController: _phoneController,
                        locationController: _locationController,
                        onContinue: _nextStep,
                      ),
                    // Step 5 — Summary + CV (seeker only)
                    _StepJobSummary(
                      summaryController: _summaryController,
                      cvUploaded: _cvSimulated,
                      onToggleCv: () => setState(() => _cvSimulated = !_cvSimulated),
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

// ══════════════════════════════════════════════════════════════════════════════
//  STEP WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// ── Step 0 – Role ─────────────────────────────────────────────────────────────

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
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                color: AppColors.darkPurple, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text("Let's personalize your experience.",
              style: TextStyle(fontSize: 16, color: AppColors.mutedText)),
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
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.isSelected, required this.onTap,
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
          boxShadow: [BoxShadow(
            color: AppColors.darkPurple.withOpacity(isSelected ? 0.18 : 0.06),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.darkPurple,
                )),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.white.withOpacity(0.7) : AppColors.mutedText,
                )),
              ],
            )),
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

// ── Step 1 – Category ─────────────────────────────────────────────────────────

class _StepCategory extends StatelessWidget {
  final String role;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  const _StepCategory({
    required this.role, required this.selected,
    required this.onSelect, required this.onContinue,
  });

  static const _cats = [
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
          Text(role == 'employer' ? 'What type of role\nare you posting?' : "What's your\nfield?",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Select the category that fits best.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15,
              ),
              itemCount: _cats.length,
              itemBuilder: (_, i) {
                final (label, icon) = _cats[i];
                final isSel = selected == label;
                return GestureDetector(
                  onTap: () => onSelect(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.darkPurple : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 24, color: isSel ? AppColors.sunglow : AppColors.wisteria),
                        const SizedBox(height: 6),
                        Text(label, textAlign: TextAlign.center, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isSel ? AppColors.white : AppColors.darkPurple,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _ContinueBtn(label: 'Continue', enabled: selected.isNotEmpty, onTap: onContinue),
        ],
      ),
    );
  }
}

// ── Step 2 – Work style ───────────────────────────────────────────────────────

class _StepWorkStyle extends StatelessWidget {
  final String role;
  final String selected;
  final ValueChanged<String> onSelect;
  const _StepWorkStyle({required this.role, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(role == 'employer' ? "What's the\nwork arrangement?" : "How do you want\nto work?",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Choose your preferred style.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 40),
          _WorkStyleOption(icon: Icons.apartment_rounded, title: 'On-site',
              subtitle: 'Work from the office', value: 'onsite', selected: selected, onSelect: onSelect),
          const SizedBox(height: 14),
          _WorkStyleOption(icon: Icons.laptop_rounded, title: 'Remote',
              subtitle: 'Work from anywhere', value: 'remote', selected: selected, onSelect: onSelect),
          const SizedBox(height: 14),
          _WorkStyleOption(icon: Icons.sync_alt_rounded, title: 'Hybrid',
              subtitle: 'Mix of both', value: 'hybrid', selected: selected, onSelect: onSelect),
        ],
      ),
    );
  }
}

class _WorkStyleOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, value, selected;
  final ValueChanged<String> onSelect;

  const _WorkStyleOption({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSel ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
            color: AppColors.darkPurple.withOpacity(isSel ? 0.18 : 0.05),
            blurRadius: 12, offset: const Offset(0, 3),
          )],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSel ? AppColors.sunglow.withOpacity(0.15) : AppColors.wisteria.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSel ? AppColors.sunglow : AppColors.wisteria, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: isSel ? AppColors.white : AppColors.darkPurple)),
                Text(subtitle, style: TextStyle(fontSize: 13,
                    color: isSel ? AppColors.white.withOpacity(0.65) : AppColors.mutedText)),
              ],
            )),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSel ? AppColors.sunglow : Colors.transparent,
                border: Border.all(
                  color: isSel ? AppColors.sunglow : AppColors.mutedText.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSel ? const Icon(Icons.check, size: 14, color: AppColors.darkPurple) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3 – Experience ───────────────────────────────────────────────────────

class _StepExperience extends StatelessWidget {
  final String role, selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onFinish;

  const _StepExperience({
    required this.role, required this.selected,
    required this.onSelect, required this.onFinish,
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
          Text(role == 'employer' ? 'Required\nexperience level?' : 'Your\nexperience level?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('This helps us show the most relevant results.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 30),
          ...List.generate(_levels.length, (i) {
            final (label, years, icon) = _levels[i];
            final isSel = selected == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                    ),
                  ),
                  child: Row(children: [
                    Icon(icon, color: isSel ? AppColors.sunglow : AppColors.wisteria, size: 22),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: isSel ? AppColors.white : AppColors.darkPurple)),
                        Text(years, style: TextStyle(fontSize: 12,
                            color: isSel ? AppColors.white.withOpacity(0.6) : AppColors.mutedText)),
                      ],
                    )),
                    if (isSel) const Icon(Icons.check_circle_rounded, color: AppColors.sunglow, size: 20),
                  ]),
                ),
              ),
            );
          }),
          const Spacer(),
          _ContinueBtn(label: 'Continue', enabled: selected.isNotEmpty, onTap: onFinish),
        ],
      ),
    );
  }
}

// ── Step 4a – Contact Info (seeker) ──────────────────────────────────────────

class _StepContact extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final VoidCallback onContinue;

  const _StepContact({
    required this.phoneController,
    required this.locationController,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Your contact\ndetails',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Used to pre-fill Easy Apply so you never type this again.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 32),
          _OnboardField(
            controller: phoneController,
            label: 'Phone number',
            hint: '+992 900 000 000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _OnboardField(
            controller: locationController,
            label: 'Location',
            hint: 'Dushanbe, Tajikistan',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sunglow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sunglow.withOpacity(0.25)),
            ),
            child: Row(
              children: const [
                Icon(Icons.bolt_rounded, color: AppColors.sunglow, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These details will be saved to your job profile and auto-filled when you apply.',
                    style: TextStyle(fontSize: 12, color: AppColors.darkPurple, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _ContinueBtn(label: 'Continue', enabled: true, onTap: onContinue),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onContinue,
              child: const Text('Skip for now',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4b – Company Setup (employer) ───────────────────────────────────────

class _StepCompanySetup extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedIndustry;
  final ValueChanged<String> onIndustryChanged;
  final String selectedSize;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onFinish;

  const _StepCompanySetup({
    required this.nameController,
    required this.selectedIndustry,
    required this.onIndustryChanged,
    required this.selectedSize,
    required this.onSizeChanged,
    required this.onFinish,
  });

  static const _industries = [
    'Technology', 'Finance', 'Healthcare', 'Education',
    'Retail', 'Manufacturing', 'Media', 'Other',
  ];

  static const _sizes = ['1–10', '11–50', '51–200', '201–500', '500+'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Set up your\ncompany',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Help candidates learn about you.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 28),
          _OnboardField(
            controller: nameController,
            label: 'Company name',
            hint: 'e.g. Alif Tech',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 20),
          Text('Industry', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.darkPurple.withOpacity(0.7))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _industries.map((ind) {
              final isSel = selectedIndustry == ind;
              return GestureDetector(
                onTap: () => onIndustryChanged(ind),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                    ),
                  ),
                  child: Text(ind, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSel ? AppColors.white : AppColors.darkPurple)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Company size', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.darkPurple.withOpacity(0.7))),
          const SizedBox(height: 10),
          Row(
            children: _sizes.map((s) {
              final isSel = selectedSize == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSizeChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.darkPurple : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                      ),
                    ),
                    child: Center(child: Text(s, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: isSel ? AppColors.white : AppColors.darkPurple))),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _ContinueBtn(label: "Let's Start Hiring", enabled: true, onTap: onFinish),
        ],
      ),
    );
  }
}

// ── Step 5 – Summary + CV (seeker) ───────────────────────────────────────────

class _StepJobSummary extends StatelessWidget {
  final TextEditingController summaryController;
  final bool cvUploaded;
  final VoidCallback onToggleCv;
  final VoidCallback onFinish;

  const _StepJobSummary({
    required this.summaryController,
    required this.cvUploaded,
    required this.onToggleCv,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Your professional\nsummary',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.darkPurple, height: 1.2)),
          const SizedBox(height: 8),
          const Text('This appears at the top of every Easy Apply.',
              style: TextStyle(fontSize: 15, color: AppColors.mutedText)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
            ),
            child: TextField(
              controller: summaryController,
              maxLines: 4,
              maxLength: 300,
              style: const TextStyle(fontSize: 14, color: AppColors.darkPurple),
              decoration: InputDecoration(
                hintText: 'e.g. Flutter developer with 3 years of experience building cross-platform apps...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.7)),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                counterStyle: const TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Upload your CV',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkPurple)),
          const SizedBox(height: 4),
          const Text('Saved once — auto-used every time you apply with CV.',
              style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleCv();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cvUploaded
                    ? const Color(0xFF10B981).withOpacity(0.08)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cvUploaded
                      ? const Color(0xFF10B981).withOpacity(0.4)
                      : AppColors.mutedText.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cvUploaded
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : AppColors.wisteria.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cvUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: cvUploaded ? const Color(0xFF10B981) : AppColors.wisteria,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cvUploaded ? 'My_Resume.pdf' : 'Browse or drop your CV',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: cvUploaded ? const Color(0xFF10B981) : AppColors.darkPurple,
                        ),
                      ),
                      Text(
                        cvUploaded ? 'Saved — will be used in all future applications' : 'PDF, DOCX — max 5 MB',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  )),
                  if (cvUploaded)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                  else
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.wisteria.withOpacity(0.7), size: 20),
                ],
              ),
            ),
          ),
          const Spacer(),
          _ContinueBtn(label: "All done — let's go!", enabled: true, onTap: onFinish),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onFinish,
              child: const Text('Skip, I\'ll do this later',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _OnboardField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _OnboardField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.darkPurple.withOpacity(0.7))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.mutedText.withOpacity(0.2)),
            boxShadow: [BoxShadow(
              color: AppColors.darkPurple.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2),
            )],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: AppColors.darkPurple),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: AppColors.mutedText.withOpacity(0.6)),
              prefixIcon: Icon(icon, size: 20, color: AppColors.wisteria),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ContinueBtn({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunglow,
          foregroundColor: AppColors.darkPurple,
          disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
