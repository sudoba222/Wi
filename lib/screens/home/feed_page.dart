// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../widgets/video_player_widget.dart';
import '../../widgets/fullscreen_image_viewer.dart';

// ─── Mock post data ────────────────────────────────────────────────────────────

class _MockPost {
  final String author;
  final String role;
  final String initial;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final String timeAgo;

  const _MockPost({
    required this.author,
    required this.role,
    required this.initial,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

const _mockPosts = [
  _MockPost(
    author: 'Alisher N.',
    role: 'Flutter Developer · Alif.tj',
    initial: 'A',
    content:
        'Just shipped a brand-new feature to production — real-time analytics built entirely in Flutter. Six months of late nights, dozens of code reviews, and one very patient team. Watching real users interact with it in the first hour was worth every minute. This is why we build. 🚀 #Flutter #TajikTech #MobileFirst',
    imageUrl:
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600&q=80',
    likes: 42,
    comments: 8,
    timeAgo: '1h ago',
  ),
  _MockPost(
    author: 'Nargis R.',
    role: 'UX Designer · Freelance',
    initial: 'N',
    content:
        'Design systems are not just component libraries — they are a shared language. Spent the last week documenting every spacing decision, typography scale, and interaction pattern in our product. The result: a team that ships faster and a product that looks like one person designed it. #UX #DesignSystem #ProductDesign',
    imageUrl: null,
    likes: 28,
    comments: 5,
    timeAgo: '3h ago',
  ),
  _MockPost(
    author: 'Rustam K.',
    role: 'Product Manager · TechHub TJ',
    initial: 'R',
    content:
        'We are hiring! Looking for a senior Flutter developer to join our growing team in Dushanbe. Competitive salary, remote-friendly, and the chance to build products used by thousands across Tajikistan. DM me or apply via the link below. Referrals welcome! 🙌 #Hiring #Flutter #Dushanbe',
    imageUrl:
        'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&q=80',
    likes: 67,
    comments: 14,
    timeAgo: '6h ago',
  ),
];

// ─── Feed Page ────────────────────────────────────────────────────────────────

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _postService = PostService();
  UserProfile? _userProfile;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  List<_MockPost> _filterMock(List<_MockPost> posts) {
    if (_searchQuery.isEmpty) return posts;
    return posts.where((p) =>
      p.author.toLowerCase().contains(_searchQuery) ||
      p.role.toLowerCase().contains(_searchQuery) ||
      p.content.toLowerCase().contains(_searchQuery)).toList();
  }

  List<Post> _filterFirestore(List<Post> posts) {
    if (_searchQuery.isEmpty) return posts;
    return posts.where((p) =>
      p.author.toLowerCase().contains(_searchQuery) ||
      p.content.toLowerCase().contains(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;

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
      child: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _postService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                final filteredMock = _filterMock(_mockPosts.toList());
                final filteredFirestore = _filterFirestore(snapshot.data ?? []);
                final totalCount = filteredMock.length + filteredFirestore.length;

                if (totalCount == 0 && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppColors.mutedText.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('No results for "$_searchQuery"',
                            style: const TextStyle(color: AppColors.mutedText, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.wisteria,
                  backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: totalCount,
                    itemBuilder: (context, i) {
                      if (i < filteredMock.length) {
                        return _MockPostCard(data: filteredMock[i], isDark: isDark);
                      }
                      final post = filteredFirestore[i - filteredMock.length];
                      return _PostCard(
                        post: post,
                        currentUserId: currentUser?.uid ?? '',
                        postService: _postService,
                        isDark: isDark,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
          colors: [
            AppColors.sunglow.withOpacity(isDark ? 0.18 : 0.32),
            AppColors.sunglow.withOpacity(isDark ? 0.04 : 0.08),
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
          _HeaderIconBtn(
            icon: Icons.menu_rounded,
            isDark: isDark,
            onTap: () => PageWithDrawerCallback.of(context)?.onOpenDrawer(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.white.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkPurple,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: Provider.of<LanguageProvider>(context).t('search'),
                      hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.mutedText, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _HeaderIconBtn(
            icon: Icons.work_outline_rounded,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobPage()),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              if (_userProfile != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userProfile: _userProfile!),
                  ),
                );
                _loadProfile();
              }
            },
            child: _AvatarCircle(
              name: _userProfile?.name ?? 'U',
              size: 36,
              fontSize: 13,
              photoUrl: _userProfile?.profilePicture,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
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
}

// ─── Header Icon Button ────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

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
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.7),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppColors.darkPurple,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mock Post Card ────────────────────────────────────────────────────────────

class _MockPostCard extends StatefulWidget {
  final _MockPost data;
  final bool isDark;

  const _MockPostCard({required this.data, required this.isDark});

  @override
  State<_MockPostCard> createState() => _MockPostCardState();
}

class _MockPostCardState extends State<_MockPostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.75);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : AppColors.wisteria.withOpacity(0.2);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                  color: AppColors.wisteria.withOpacity(isDark ? 0.04 : 0.08),
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
                      _AvatarCircle(
                          name: d.author, size: 46, fontSize: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.author,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d.role,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              d.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.more_horiz_rounded,
                          color: AppColors.mutedText, size: 20),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                // Content — expandable caption (Instagram/Telegram style)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _ExpandableText(text: d.content, isDark: isDark),
                ),
                // Optional image
                if (d.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: () => FullscreenImageViewer.show(
                          context, [d.imageUrl!]),
                      child: Image.network(
                        d.imageUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    height: 220,
                                    color:
                                        AppColors.wisteria.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.wisteria,
                                          strokeWidth: 2),
                                    ),
                                  ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: AppColors.wisteria.withOpacity(0.08),
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: AppColors.wisteria, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                // Separator
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.mutedText.withOpacity(0.12),
                ),
                // Actions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      _ActionBtn(
                        icon: _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '${d.likes + (_liked ? 1 : 0)}',
                        color: _liked ? Colors.redAccent : AppColors.mutedText,
                        onTap: () => setState(() => _liked = !_liked),
                      ),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${d.comments}',
                        color: AppColors.mutedText,
                        onTap: () {},
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
}

// ─── Firestore Post Card ───────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final PostService postService;
  final bool isDark;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.postService,
    required this.isDark,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _likeLoading = false;

  bool get _isLiked => widget.post.isLikedBy(widget.currentUserId);
  bool get _isOwn => widget.post.authorId == widget.currentUserId;

  Future<void> _toggleLike() async {
    if (_likeLoading || widget.currentUserId.isEmpty) return;
    setState(() => _likeLoading = true);
    try {
      final ref = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
      if (_isLiked) {
        await ref.update({'likedBy': FieldValue.arrayRemove([widget.currentUserId])});
      } else {
        await ref.update({'likedBy': FieldValue.arrayUnion([widget.currentUserId])});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update like: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (mounted) setState(() => _likeLoading = false);
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsDialog(post: widget.post),
    );
  }
  Future<void> _openAuthorProfile(String authorId) async {
  final auth = Provider.of<AuthService>(context, listen: false);
  if (authorId == widget.currentUserId) return;
  try {
    final userProfile = await auth.getFullUserProfile(authorId);
    if (userProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(userProfile: userProfile),
        ),
      );
    }
  } catch (e) {
    print('Error opening profile: $e');
  }
  }
  void _showMenu() {
    final isDark = widget.isDark;
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
              color: isDark
                  ? AppColors.darkCard.withOpacity(0.95)
                  : Colors.white.withOpacity(0.92),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  width: 1),
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
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 20),
                    ),
                    title: const Text(
                      'Delete post',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
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
    final isDark = widget.isDark;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.75);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.6);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                  color: AppColors.wisteria.withOpacity(isDark ? 0.04 : 0.08),
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
                      GestureDetector(
                        onTap: () => _openAuthorProfile(post.authorId),
                        child: _AvatarCircle(
                            name: post.author,
                            size: 46,
                            fontSize: 18,
                            photoUrl: post.authorProfilePicture),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openAuthorProfile(post.authorId),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
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
                // Content — expandable caption (Instagram/Telegram style)
                if (post.content.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, post.mediaUrls.isEmpty ? 16 : 8),
                    child: _ExpandableText(text: post.content, isDark: isDark),
                  ),

                // Location
                if (post.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: AppColors.wisteria),
                        const SizedBox(width: 4),
                        Text(post.location,
                            style: const TextStyle(fontSize: 12, color: AppColors.wisteria)),
                      ],
                    ),
                  ),

                // Images
                if (post.mediaUrls.isNotEmpty && post.mediaType == 'image')
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: post.mediaUrls.length == 1
                        ? GestureDetector(
                            onTap: () => FullscreenImageViewer.show(
                                context, post.mediaUrls),
                            child: Image.network(
                              post.mediaUrls.first,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) => progress == null
                                  ? child
                                  : Container(
                                      height: 220,
                                      color: AppColors.wisteria.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: AppColors.wisteria, strokeWidth: 2),
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: AppColors.wisteria.withOpacity(0.08),
                                child: const Center(
                                  child: Icon(Icons.image_outlined,
                                      color: AppColors.wisteria, size: 40),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: post.mediaUrls.length,
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => FullscreenImageViewer.show(
                                    context, post.mediaUrls, index: i),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(post.mediaUrls[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),

                // Video
                // Video
                if (post.mediaUrls.isNotEmpty && post.mediaType == 'video')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: VideoPlayerWidget(videoUrl: post.mediaUrls.first),
                  ),

                // Tagged users
                if (post.taggedUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 13, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          'with ${post.taggedUsers.length} ${post.taggedUsers.length == 1 ? 'person' : 'people'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),

                // Separator
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.mutedText.withOpacity(0.12),
                ),
                // Actions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      _ActionBtn(
                        icon: _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: post.likedBy.length.toString(),
                        color:
                            _isLiked ? Colors.redAccent : AppColors.mutedText,
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
  final String? photoUrl;

  const _AvatarCircle({
    required this.name,
    required this.size,
    required this.fontSize,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
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
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initial,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700)),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Expandable caption text ──────────────────────────────────────────────────

/// Shows up to 3 lines of text with a "more" tap to expand,
/// and a "Show less" tap to collapse. No toggle shown if text fits in 3 lines.
class _ExpandableText extends StatefulWidget {
  final String text;
  final bool isDark;
  const _ExpandableText({required this.text, required this.isDark});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.darkPurple;
    const style = TextStyle(fontSize: 15, height: 1.6);
    final colored = style.copyWith(color: textColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure if text overflows 3 lines
        final span = TextSpan(text: widget.text, style: colored);
        final tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;

        if (!overflows) {
          // Short text — just render it plainly
          return Text(widget.text, style: colored);
        }

        if (_expanded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.text, style: colored),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Show less',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wisteria,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Collapsed — 3 lines + "... more" inline
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: colored),
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'more',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wisteria,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
