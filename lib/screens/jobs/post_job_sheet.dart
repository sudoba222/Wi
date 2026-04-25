// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'job_store.dart';

class PostJobSheet extends StatefulWidget {
  final JobPosting? editing;
  final VoidCallback onSaved;

  const PostJobSheet({super.key, this.editing, required this.onSaved});

  @override
  State<PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<PostJobSheet> {
  final _pageController = PageController();
  int _step = 0;

  // Step 1
  final _titleController = TextEditingController();
  String _category = '';
  String _type = '';

  // Step 2
  String _workStyle = '';
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  bool _easyApply = true;

  // Step 3
  final _descController = TextEditingController();
  final _reqController = TextEditingController();
  final List<String> _requirements = [];

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
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleController.text = e.title;
      _category = e.category;
      _type = e.type;
      _workStyle = e.workStyle;
      _locationController.text = e.location;
      _salaryMinController.text = e.salaryMin;
      _salaryMaxController.text = e.salaryMax;
      _easyApply = e.easyApplyEnabled;
      _descController.text = e.description;
      _requirements.addAll(e.requirements);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descController.dispose();
    _reqController.dispose();
    super.dispose();
  }

  bool get _step1Valid => _titleController.text.trim().isNotEmpty && _category.isNotEmpty && _type.isNotEmpty;
  bool get _step2Valid => _workStyle.isNotEmpty && _locationController.text.trim().isNotEmpty;
  bool get _step3Valid => _descController.text.trim().isNotEmpty;

  void _goNext() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _save();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _save() {
    final e = widget.editing;
    if (e != null) {
      e.title = _titleController.text.trim();
      e.category = _category;
      e.type = _type;
      e.workStyle = _workStyle;
      e.location = _locationController.text.trim();
      e.salaryMin = _salaryMinController.text.trim();
      e.salaryMax = _salaryMaxController.text.trim();
      e.easyApplyEnabled = _easyApply;
      e.description = _descController.text.trim();
      e.requirements
        ..clear()
        ..addAll(_requirements);
    } else {
      JobsStore.employerPostings.add(JobPosting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _category,
        type: _type,
        workStyle: _workStyle,
        location: _locationController.text.trim(),
        salaryMin: _salaryMinController.text.trim(),
        salaryMax: _salaryMaxController.text.trim(),
        description: _descController.text.trim(),
        requirements: List.from(_requirements),
        easyApplyEnabled: _easyApply,
        status: 'active',
        viewCount: 0,
        applicants: [],
        postedAt: DateTime.now(),
      ));
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle + Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_step > 0)
                        GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.arrow_back_ios_rounded,
                                color: textColor, size: 16),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.editing != null ? 'Edit Job' : 'Post a Job',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            Text(
                              'Step ${_step + 1} of 3 · ${['Basics', 'Details', 'Description'][_step]}',
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded, color: AppColors.mutedText, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppColors.sunglow
                              : AppColors.mutedText.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    titleController: _titleController,
                    category: _category,
                    type: _type,
                    isDark: isDark,
                    textColor: textColor,
                    categories: _categories,
                    onCategorySelect: (v) => setState(() => _category = v),
                    onTypeSelect: (v) => setState(() => _type = v),
                  ),
                  _Step2(
                    workStyle: _workStyle,
                    locationController: _locationController,
                    salaryMinController: _salaryMinController,
                    salaryMaxController: _salaryMaxController,
                    easyApply: _easyApply,
                    isDark: isDark,
                    textColor: textColor,
                    onWorkStyleSelect: (v) => setState(() => _workStyle = v),
                    onEasyApplyToggle: (v) => setState(() => _easyApply = v),
                  ),
                  _Step3(
                    descController: _descController,
                    reqController: _reqController,
                    requirements: _requirements,
                    isDark: isDark,
                    textColor: textColor,
                    onAddReq: () {
                      final v = _reqController.text.trim();
                      if (v.isNotEmpty) {
                        setState(() {
                          _requirements.add(v);
                          _reqController.clear();
                        });
                      }
                    },
                    onRemoveReq: (i) => setState(() => _requirements.removeAt(i)),
                  ),
                ],
              ),
            ),
            // Bottom CTA
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final canProceed = [_step1Valid, _step2Valid, _step3Valid][_step];
                    if (canProceed) {
                      HapticFeedback.lightImpact();
                      _goNext();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunglow,
                    foregroundColor: AppColors.darkPurple,
                    disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _step < 2 ? 'Continue →' : (widget.editing != null ? 'Save Changes' : 'Post Job 🚀'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Basics ──

class _Step1 extends StatelessWidget {
  final TextEditingController titleController;
  final String category;
  final String type;
  final bool isDark;
  final Color textColor;
  final List<(String, IconData)> categories;
  final void Function(String) onCategorySelect;
  final void Function(String) onTypeSelect;

  const _Step1({
    required this.titleController,
    required this.category,
    required this.type,
    required this.isDark,
    required this.textColor,
    required this.categories,
    required this.onCategorySelect,
    required this.onTypeSelect,
  });

  @override
  Widget build(BuildContext context) {
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormLabel('Job Title', textColor),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            style: TextStyle(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              hintText: 'e.g. Flutter Developer',
              hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6), fontSize: 14),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderSide: const BorderSide(color: AppColors.wisteria, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FormLabel('Category', textColor),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final (label, icon) = categories[i];
              final isSelected = category == label;
              return GestureDetector(
                onTap: () => onCategorySelect(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.darkPurple : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22,
                          color: isSelected ? AppColors.sunglow : AppColors.wisteria),
                      const SizedBox(height: 5),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.white : textColor,
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _FormLabel('Job Type', textColor),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['Full-time', 'Part-time', 'Contract', 'Internship'].map((t) {
              final isSelected = type == t;
              return GestureDetector(
                onTap: () => onTypeSelect(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.darkPurple : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                    ),
                  ),
                  child: Text(t,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.sunglow : textColor,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Details ──

class _Step2 extends StatelessWidget {
  final String workStyle;
  final TextEditingController locationController;
  final TextEditingController salaryMinController;
  final TextEditingController salaryMaxController;
  final bool easyApply;
  final bool isDark;
  final Color textColor;
  final void Function(String) onWorkStyleSelect;
  final void Function(bool) onEasyApplyToggle;

  const _Step2({
    required this.workStyle,
    required this.locationController,
    required this.salaryMinController,
    required this.salaryMaxController,
    required this.easyApply,
    required this.isDark,
    required this.textColor,
    required this.onWorkStyleSelect,
    required this.onEasyApplyToggle,
  });

  @override
  Widget build(BuildContext context) {
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormLabel('Work Arrangement', textColor),
          const SizedBox(height: 10),
          ...([
            ('Remote', Icons.laptop_rounded, 'Work from anywhere'),
            ('On-site', Icons.apartment_rounded, 'Work from the office'),
            ('Hybrid', Icons.sync_alt_rounded, 'Mix of both'),
          ].map((opt) {
            final (label, icon, sub) = opt;
            final val = label.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
            final isSelected = workStyle == val || workStyle == label.toLowerCase();
            return GestureDetector(
              onTap: () => onWorkStyleSelect(label.toLowerCase().replaceAll('-', '')),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkPurple : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.sunglow.withOpacity(0.5) : AppColors.mutedText.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sunglow.withOpacity(0.15)
                            : AppColors.wisteria.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 20,
                          color: isSelected ? AppColors.sunglow : AppColors.wisteria),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : textColor)),
                          Text(sub,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.6)
                                      : AppColors.mutedText)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.sunglow, size: 20),
                  ],
                ),
              ),
            );
          })),
          const SizedBox(height: 8),
          _FormLabel('Location', textColor),
          const SizedBox(height: 8),
          _InlineTextField(
              controller: locationController,
              hint: 'e.g. Dushanbe, TJ or Remote',
              textColor: textColor,
              fillColor: inputFill,
              borderColor: inputBorder),
          const SizedBox(height: 16),
          _FormLabel('Monthly Salary (\$)', textColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InlineTextField(
                    controller: salaryMinController,
                    hint: 'Min (e.g. 800)',
                    keyboardType: TextInputType.number,
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('–', style: TextStyle(fontSize: 20, color: textColor)),
              ),
              Expanded(
                child: _InlineTextField(
                    controller: salaryMaxController,
                    hint: 'Max (e.g. 1200)',
                    keyboardType: TextInputType.number,
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mutedText.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.sunglow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.sunglow, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Easy Apply',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                      const Text('Let candidates apply with one tap',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: easyApply,
                  onChanged: onEasyApplyToggle,
                  activeColor: AppColors.sunglow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Description ──

class _Step3 extends StatelessWidget {
  final TextEditingController descController;
  final TextEditingController reqController;
  final List<String> requirements;
  final bool isDark;
  final Color textColor;
  final VoidCallback onAddReq;
  final void Function(int) onRemoveReq;

  const _Step3({
    required this.descController,
    required this.reqController,
    required this.requirements,
    required this.isDark,
    required this.textColor,
    required this.onAddReq,
    required this.onRemoveReq,
  });

  @override
  Widget build(BuildContext context) {
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : AppColors.mutedText.withOpacity(0.2);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormLabel('Job Description', textColor),
          const SizedBox(height: 8),
          TextField(
            controller: descController,
            maxLines: 6,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: 'Describe the role, responsibilities, and team culture…',
              hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6), fontSize: 13),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.all(16),
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
                borderSide: const BorderSide(color: AppColors.wisteria, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FormLabel('Requirements', textColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InlineTextField(
                    controller: reqController,
                    hint: 'Add a requirement…',
                    textColor: textColor,
                    fillColor: inputFill,
                    borderColor: inputBorder),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAddReq,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.sunglow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.darkPurple, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (requirements.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text('No requirements added yet',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.mutedText.withOpacity(0.6), fontStyle: FontStyle.italic)),
            )
          else
            ...requirements.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outlined, color: AppColors.wisteria, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(e.value,
                              style: TextStyle(fontSize: 13, color: textColor))),
                      GestureDetector(
                        onTap: () => onRemoveReq(e.key),
                        child: Icon(Icons.close_rounded,
                            color: AppColors.mutedText.withOpacity(0.5), size: 16),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ── Shared form helpers ──

class _FormLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FormLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
      );
}

class _InlineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;

  const _InlineTextField({
    required this.controller,
    required this.hint,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6), fontSize: 13),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.wisteria, width: 1.5),
          ),
        ),
      );
}
