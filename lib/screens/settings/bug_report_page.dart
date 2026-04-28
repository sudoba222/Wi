// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_services.dart';
import '../../services/cloudinary_service.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  String _type = 'bug';
  String _priority = 'medium';
  XFile? _ximage;
  Uint8List? _imageBytes;
  bool _submitting = false;
  bool _submitted = false;
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _ximage = picked; _imageBytes = bytes; });
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and description'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;

      String? imageUrl;
      if (_ximage != null && _imageBytes != null) {
        imageUrl = await _cloudinary.uploadPostImageBytes(_imageBytes!, _ximage!.name);
      }

      await FirebaseFirestore.instance.collection('feedback').add({
        'type': _type,
        'title': title,
        'description': desc,
        'priority': _type == 'bug' ? _priority : null,
        'imageUrl': imageUrl,
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'userName': user?.displayName ?? '',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _submitting = false;
        _submitted = true;
      });
      _checkAnim.forward();
      HapticFeedback.heavyImpact();
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final card = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _type == 'feedback' ? 'Send Feedback' : _type == 'feature' ? 'Request Feature' : 'Report a Bug',
          style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _submitted ? _buildSuccess(isDark, text) : _buildForm(isDark, bg, text, card),
    );
  }

  Widget _buildSuccess(bool isDark, Color text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 56, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Thank you!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text),
            ),
            const SizedBox(height: 12),
            Text(
              'Your report has been received.\nOur team will review it shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.mutedText, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunglow,
                  foregroundColor: AppColors.darkPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Go Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark, Color bg, Color text, Color card) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          _SectionLabel('What are you reporting?', text),
          const SizedBox(height: 12),
          Row(
            children: [
              _TypeCard(
                icon: Icons.bug_report_rounded,
                label: 'Bug',
                color: Colors.redAccent,
                selected: _type == 'bug',
                onTap: () => setState(() => _type = 'bug'),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _TypeCard(
                icon: Icons.lightbulb_rounded,
                label: 'Feedback',
                color: AppColors.sunglow,
                selected: _type == 'feedback',
                onTap: () => setState(() => _type = 'feedback'),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _TypeCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Feature',
                color: AppColors.wisteria,
                selected: _type == 'feature',
                onTap: () => setState(() => _type = 'feature'),
                isDark: isDark,
              ),
            ],
          ),

          // Priority (bug only)
          if (_type == 'bug') ...[
            const SizedBox(height: 24),
            _SectionLabel('Priority', text),
            const SizedBox(height: 10),
            Row(
              children: [
                _PriorityChip(label: 'Low', color: const Color(0xFF10B981), selected: _priority == 'low', onTap: () => setState(() => _priority = 'low')),
                const SizedBox(width: 8),
                _PriorityChip(label: 'Medium', color: AppColors.sunglow, selected: _priority == 'medium', onTap: () => setState(() => _priority = 'medium')),
                const SizedBox(width: 8),
                _PriorityChip(label: 'High', color: Colors.redAccent, selected: _priority == 'high', onTap: () => setState(() => _priority = 'high')),
              ],
            ),
          ],

          const SizedBox(height: 24),
          _SectionLabel('Title', text),
          const SizedBox(height: 8),
          _InputField(
            controller: _titleCtrl,
            hint: _type == 'bug'
                ? 'e.g. App crashes when opening messages'
                : _type == 'feedback'
                    ? 'e.g. Profile editing is confusing'
                    : 'e.g. Add dark mode to job listings',
            maxLines: 1,
            isDark: isDark,
            text: text,
          ),

          const SizedBox(height: 20),
          _SectionLabel('Description', text),
          const SizedBox(height: 4),
          Text(
            _type == 'bug'
                ? 'Steps to reproduce, what you expected, and what happened'
                : _type == 'feedback'
                    ? 'Share your thoughts in detail'
                    : 'Describe the feature and why it would be useful',
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          const SizedBox(height: 8),
          _InputField(
            controller: _descCtrl,
            hint: 'Write here...',
            maxLines: 6,
            isDark: isDark,
            text: text,
          ),

          const SizedBox(height: 24),
          _SectionLabel('Screenshot (optional)', text),
          const SizedBox(height: 4),
          const Text(
            'Attach a screenshot to help us understand the issue',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: _imageBytes != null ? 180 : 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _imageBytes != null
                      ? AppColors.wisteria.withOpacity(0.5)
                      : AppColors.mutedText.withOpacity(0.25),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: _imageBytes != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() { _ximage = null; _imageBytes = null; }),
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppColors.wisteria.withOpacity(0.7)),
                        const SizedBox(height: 6),
                        Text('Tap to add screenshot', style: TextStyle(fontSize: 13, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow,
                foregroundColor: AppColors.darkPurple,
                disabledBackgroundColor: AppColors.mutedText.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkPurple),
                    )
                  : Text(
                      _type == 'bug' ? 'Submit Report' : _type == 'feedback' ? 'Send Feedback' : 'Submit Request',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool isDark;
  final Color text;
  const _InputField({required this.controller, required this.hint, required this.maxLines, required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mutedText.withOpacity(0.18)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withOpacity(0.6)),
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
          ),
        ),
      );
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _TypeCard({required this.icon, required this.label, required this.color, required this.selected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onTap(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.12)
                  : isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.mutedText.withOpacity(0.18),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? color : AppColors.mutedText, size: 26),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? color : AppColors.mutedText)),
              ],
            ),
          ),
        ),
      );
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : AppColors.mutedText.withOpacity(0.3)),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? color : AppColors.mutedText)),
        ),
      );
}
