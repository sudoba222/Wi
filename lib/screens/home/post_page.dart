// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/global_data.dart';
import '../../models/post.dart';

/// Full-screen compose + preview page.
/// Top: glass compose card.
/// Below: Instagram-style sample post cards showing the format.
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Creates a new post in GlobalData and pops back to the feed.
  Future<void> _createPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    GlobalData.addPost(Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: '',
      author: 'You',
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

    return Container(
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
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad > 0 ? 4 : 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : AppColors.darkPurple, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Create Post',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkPurple,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PostButton(isPosting: _isPosting, onTap: _createPost),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Scrollable body: compose card + sample posts ─────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  // Glass compose card
                  _GlassCard(
                    isDark: isDark,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthorRow(isDark: isDark),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contentController,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 16, height: 1.5,
                              color: isDark ? Colors.white : AppColors.darkPurple,
                            ),
                            decoration: const InputDecoration(
                              hintText: "What's on your mind?",
                              hintStyle: TextStyle(fontSize: 16, color: AppColors.mutedText),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MediaToolbar(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section label
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'POST PREVIEW',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                        color: isDark ? Colors.white38 : AppColors.mutedText,
                      ),
                    ),
                  ),

                  // ── Sample posts ─────────────────────────────────────────
                  ..._samplePosts.map((p) => _SamplePostCard(post: p, isDark: isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sample post data ──────────────────────────────────────────────────────────

class _PostData {
  final String author;
  final String role;
  final String initial;
  final String? imageUrl;
  final String caption;
  final int likes;
  final int comments;
  final String time;

  const _PostData({
    required this.author, required this.role, required this.initial,
    this.imageUrl, required this.caption, required this.likes,
    required this.comments, required this.time,
  });
}

const _samplePosts = [
  _PostData(
    author: 'Alisher Nazarov',
    role: 'Senior Software Engineer · Dushanbe',
    initial: 'A',
    imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&q=80',
    caption: 'Shipped our new dashboard today! 🚀 Six months of work, countless late nights, and now watching real users love it. Proud of the whole team. #Flutter #MobileFirst #TajikTech',
    likes: 142,
    comments: 18,
    time: '2h ago',
  ),
  _PostData(
    author: 'Nargis Rahimova',
    role: 'UX Designer · Khujand',
    initial: 'N',
    imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&q=80',
    caption: 'Design isn\'t just how it looks — it\'s how it works. Presented our new design system to the team today. Every component built with Tajik users in mind. #UX #DesignThinking',
    likes: 89,
    comments: 11,
    time: '5h ago',
  ),
  _PostData(
    author: 'Rustam Karimov',
    role: 'Product Manager · Dushanbe',
    initial: 'R',
    imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&q=80',
    caption: 'Our team just crossed 10,000 active users! 🎉 Building a product people actually use is the best feeling. Grateful for every person who gave feedback. The journey is just starting.',
    likes: 211,
    comments: 34,
    time: '1d ago',
  ),
  _PostData(
    author: 'Zarina Muhammadova',
    role: 'Data Analyst · Bokhtar',
    initial: 'Z',
    imageUrl: null,
    caption: 'Just completed the Google Data Analytics Certificate! 📊 Three months of nights and weekends. If you\'re thinking about upskilling — just start. Consistency beats everything. #DataScience #Tajikistan',
    likes: 67,
    comments: 9,
    time: '2d ago',
  ),
];

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Instagram-style post card in our glass/purple theme.
class _SamplePostCard extends StatefulWidget {
  final _PostData post;
  final bool isDark;
  const _SamplePostCard({required this.post, required this.isDark});

  @override
  State<_SamplePostCard> createState() => _SamplePostCardState();
}

class _SamplePostCardState extends State<_SamplePostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final isDark = widget.isDark;
    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppColors.wisteria.withOpacity(0.2);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      // Gradient avatar
                      Container(
                        width: 42, height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple]),
                        ),
                        child: Center(
                          child: Text(p.initial,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.author,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                            Text(p.role,
                              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text(p.time, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                      const SizedBox(width: 8),
                      Icon(Icons.more_horiz_rounded, color: AppColors.mutedText, size: 20),
                    ],
                  ),
                ),

                // ── Photo (if any) ─────────────────────────────────────────
                if (p.imageUrl != null)
                  ClipRRect(
                    child: Image.network(
                      p.imageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 220,
                              color: AppColors.wisteria.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.wisteria, strokeWidth: 2),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: AppColors.wisteria.withOpacity(0.08),
                        child: const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.wisteria, size: 40),
                        ),
                      ),
                    ),
                  ),

                // ── Caption ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text(
                    p.caption,
                    style: TextStyle(fontSize: 14, color: textColor, height: 1.45),
                  ),
                ),

                // ── Action row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                  child: Row(
                    children: [
                      // Like
                      _ActionBtn(
                        icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: '${p.likes + (_liked ? 1 : 0)}',
                        color: _liked ? Colors.redAccent : AppColors.mutedText,
                        onTap: () => setState(() => _liked = !_liked),
                      ),
                      const SizedBox(width: 4),
                      // Comment
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${p.comments}',
                        color: AppColors.mutedText,
                        onTap: () {},
                      ),
                      const SizedBox(width: 4),
                      // Repost / Share
                      _ActionBtn(
                        icon: Icons.repeat_rounded,
                        label: 'Share',
                        color: AppColors.mutedText,
                        onTap: () {},
                      ),
                      const Spacer(),
                      // Bookmark
                      Icon(Icons.bookmark_border_rounded, size: 20, color: AppColors.mutedText),
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
}

/// Icon + label action button for the post card toolbar.
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Amber pill "Post" button.
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
          color: isPosting ? AppColors.sunglow.withOpacity(0.5) : AppColors.sunglow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isPosting
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPurple))
            : const Text('Post',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkPurple)),
      ),
    );
  }
}

/// Gradient avatar circle + display name row at the top of the compose card.
class _AuthorRow extends StatelessWidget {
  final bool isDark;
  const _AuthorRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple]),
          ),
          child: const Center(child: Text('Y', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkPurple)),
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.wisteria.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Anyone', style: TextStyle(fontSize: 11, color: AppColors.splashPurple, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom attachment-type pills: Photo / Video / Location (UI only).
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

class _AttachPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AttachPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.wisteria.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.splashPurple),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkPurple)),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism card wrapper.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : AppColors.wisteria.withOpacity(0.25),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
