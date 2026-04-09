// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/global_data.dart';
import '../../models/post.dart';

/// Full-screen compose page for creating a new post.
/// Uses GlobalData as the backing store (PostService is not yet wired up).
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  bool _isPosting = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Creates a new post and stores it in GlobalData, then pops the page.
  Future<void> _createPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    // Simulate a brief network delay to show the loading indicator.
    await Future.delayed(const Duration(milliseconds: 600));

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: '',
      author: 'You',
      content: text,
      timestamp: DateTime.now(),
    );

    GlobalData.addPost(newPost);

    if (!mounted) return;
    setState(() => _isPosting = false);

    // Navigate back to the feed after posting.
    Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Total top padding including status bar.
    final topPad = MediaQuery.of(context).padding.top + 12;

    return Container(
      // Gradient background matching the app design system.
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
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad - MediaQuery.of(context).padding.top, 8, 0),
              child: Row(
                children: [
                  // Back arrow — navigates away without posting.
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.darkPurple,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Post',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  ),
                  // Amber "Post" action button.
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PostButton(
                      isPosting: _isPosting,
                      onTap: _createPost,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Glass compose card ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row — avatar initial + display name.
                        _AuthorRow(),

                        const SizedBox(height: 16),

                        // Expandable text field.
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            autofocus: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.darkPurple,
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: "What's on your mind?",
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: AppColors.mutedText,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bottom toolbar: media attachment pills (UI only).
                        _MediaToolbar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Amber pill button in the top bar that triggers the post action.
class _PostButton extends StatelessWidget {
  final bool isPosting;
  final VoidCallback onTap;

  const _PostButton({required this.isPosting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPosting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isPosting
              ? AppColors.sunglow.withOpacity(0.5)
              : AppColors.sunglow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isPosting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.darkPurple,
                ),
              )
            : const Text(
                'Post',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPurple,
                ),
              ),
      ),
    );
  }
}

/// Gradient avatar circle + display name row.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gradient avatar with "Y" initial for the current user.
        Container(
          width: 44,
          height: 44,
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
        // Author name and audience label.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.wisteria.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Anyone',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.splashPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom row of media-type attachment pills (Photo / Video / Location).
/// These are UI-only — tapping them shows no action yet.
class _MediaToolbar extends StatelessWidget {
  const _MediaToolbar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AttachPill(icon: Icons.image_outlined, label: 'Photo'),
        const SizedBox(width: 10),
        _AttachPill(icon: Icons.videocam_outlined, label: 'Video'),
        const SizedBox(width: 10),
        _AttachPill(icon: Icons.location_on_outlined, label: 'Location'),
      ],
    );
  }
}

/// A single pill-shaped attachment option button.
class _AttachPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AttachPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Placeholder — no actual functionality.
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.wisteria.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.splashPurple),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass-morphism card used to wrap the compose area.
/// Applies a blur + translucent white overlay with a white border.
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
