// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/global_data.dart';
import '../../services/auth_services.dart';
import '../../models/post.dart';

/// Redesigned "Create Post" page.
/// - Clean full-height text area
/// - Publish button (amber when text present, greyed when empty)
/// - Author row with globe + Public audience pill
/// - Pinned bottom toolbar: media icons + character counter
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  bool _isPosting = false;

  static const int _maxChars = 2000;

  int get _charCount => _contentController.text.length;
  bool get _hasText => _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _contentController.text.trim();
    if (text.isEmpty || _isPosting) return;
    setState(() => _isPosting = true);

    // Get display name from auth if available
    String authorName = 'You';
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser?.displayName != null &&
          auth.currentUser!.displayName!.isNotEmpty) {
        authorName = auth.currentUser!.displayName!;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 400));
    GlobalData.addPost(Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: '',
      author: authorName,
      content: text,
      timestamp: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────────────────
          _buildTopBar(context, topPad, isDark, textColor),

          // ── Author row ───────────────────────────────────────────────────────
          _buildAuthorRow(isDark, textColor),

          // ── Scrollable text area (flex expands) ──────────────────────────────
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                maxLength: _maxChars,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    const SizedBox.shrink(), // hide default counter — we show our own
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.65,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    fontSize: 17,
                    color: AppColors.mutedText.withOpacity(0.8),
                    height: 1.65,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          // ── Bottom toolbar — pinned ──────────────────────────────────────────
          _buildBottomToolbar(isDark, bottomPad),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    double topPad,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: 4,
        right: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppColors.wisteria.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back arrow
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          // Title
          Expanded(
            child: Text(
              'Create Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          // Publish button — amber when text entered, grey when empty
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _hasText && !_isPosting ? _publish : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: _hasText
                      ? AppColors.sunglow
                      : AppColors.mutedText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isPosting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : AppColors.darkPurple,
                        ),
                      )
                    : Text(
                        'Publish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _hasText
                              ? AppColors.darkPurple
                              : AppColors.mutedText,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Gradient avatar
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.wisteria, AppColors.splashPurple],
              ),
            ),
            child: const Center(
              child: Text(
                'Y',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              // Public pill with globe icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.wisteria.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.wisteria.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 13,
                      color: AppColors.splashPurple,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.splashPurple,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.splashPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark, double bottomPad) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 10 + bottomPad,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.wisteria.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Media icons
              _ToolbarIcon(
                  icon: Icons.image_outlined, onTap: () {}),
              const SizedBox(width: 4),
              _ToolbarIcon(
                  icon: Icons.videocam_outlined, onTap: () {}),
              const SizedBox(width: 4),
              _ToolbarIcon(
                  icon: Icons.person_add_outlined, onTap: () {}),
              const SizedBox(width: 4),
              _ToolbarIcon(
                  icon: Icons.location_on_outlined, onTap: () {}),
              const Spacer(),
              // Character counter
              Text(
                '$_charCount/$_maxChars',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _charCount > _maxChars * 0.9
                      ? (_charCount >= _maxChars
                          ? Colors.red
                          : Colors.orange)
                      : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toolbar icon button — wisteria color.
class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 24,
          color: AppColors.wisteria,
        ),
      ),
    );
  }
}
