// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/post_services.dart';
import '../../services/auth_services.dart';
import '../../widgets/comments_dialog.dart';
import '../../providers/language_provider.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';
import 'job_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _postService = PostService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0EAFF),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _postService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: AppColors.wisteria,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading feed…',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  color: AppColors.wisteria,
                  backgroundColor: AppColors.white,
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => _PostCard(
                      post: posts[i],
                      currentUserId: currentUser?.uid ?? '',
                      postService: _postService,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
          colors: [
            AppColors.sunglow.withOpacity(0.32),
            AppColors.sunglow.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: topPad + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          // Hamburger — opens side drawer
          _HeaderIconBtn(
            icon: Icons.menu_rounded,
            onTap: () => PageWithDrawerCallback.of(context)?.onOpenDrawer(),
          ),
          const SizedBox(width: 10),
          // Search pill (shows translated placeholder)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded, color: AppColors.mutedText, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        Provider.of<LanguageProvider>(context).t('search'),
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Jobs (briefcase)
          _HeaderIconBtn(
            icon: Icons.work_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobPage()),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          GestureDetector(
            onTap: () {
              if (_userProfile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userProfile: _userProfile!),
                  ),
                );
              }
            },
            child: _AvatarCircle(
              name: _userProfile?.name ?? 'U',
              size: 36,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.wisteria.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  size: 56,
                  color: AppColors.wisteria,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Translated empty state text
          Text(
            Provider.of<LanguageProvider>(context).t('noPosts'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkPurple,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Provider.of<LanguageProvider>(context).t('firstPost'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Icon Button ───────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.darkPurple, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final PostService postService;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.postService,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _likeLoading = false;

  bool get _isLiked => widget.post.isLikedBy(widget.currentUserId);
  bool get _isOwn => widget.post.authorId == widget.currentUserId;

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);
    await widget.postService.toggleLike(widget.post.id);
    if (mounted) setState(() => _likeLoading = false);
  }

  void _showComments() {
    showDialog(
      context: context,
      builder: (_) => CommentsDialog(post: widget.post),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    ),
                    title: const Text(
                      'Delete post',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await widget.postService.deletePost(widget.post.id);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wisteria.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(
                    children: [
                      _AvatarCircle(name: post.author, size: 46, fontSize: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkPurple,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(post.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isOwn)
                        IconButton(
                          onPressed: _showMenu,
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.darkPurple,
                      height: 1.6,
                    ),
                  ),
                ),
                // Soft separator
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.mutedText.withOpacity(0.12),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      _ActionBtn(
                        icon: _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: post.likedBy.length.toString(),
                        color: _isLiked ? Colors.redAccent : AppColors.mutedText,
                        onTap: _toggleLike,
                        loading: _likeLoading,
                      ),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: post.comments.toString(),
                        color: AppColors.mutedText,
                        onTap: _showComments,
                      ),
                      _ActionBtn(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: AppColors.mutedText,
                        onTap: () {},
                      ),
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Avatar Widget ─────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const _AvatarCircle({
    required this.name,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wisteria, AppColors.splashPurple],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
