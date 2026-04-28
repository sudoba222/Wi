// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../models/user_profile.dart';
import '../../services/post_services.dart';
import '../../services/auth_services.dart';
import '../../services/notification_service.dart';
import '../../widgets/comments_dialog.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../providers/language_provider.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';
import 'job_page.dart';
import '../../widgets/video_player_widget.dart';
import 'package:share_plus/share_plus.dart';



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
              stream: currentUser != null
                  ? _postService.getAlgorithmicFeedStream(currentUser.uid)
                  : _postService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                final filteredFirestore = _filterFirestore(snapshot.data ?? []);
                if (filteredFirestore.isEmpty && _searchQuery.isNotEmpty) {
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
                    itemCount: filteredFirestore.length,
                    itemBuilder: (context, i) {
                      final post = filteredFirestore[i];
                      return _PostCard(
                        key: ValueKey(post.id),
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
          StreamBuilder<int>(
            stream: NotificationService.unreadCountStream(
                FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Stack(
                children: [
                  _HeaderIconBtn(
                    icon: Icons.menu_rounded,
                    isDark: isDark,
                    onTap: () => PageWithDrawerCallback.of(context)?.onOpenDrawer(),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.sunglow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E0B2C) : AppColors.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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



// ─── Firestore Post Card ───────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final PostService postService;
  final bool isDark;

  const _PostCard({
    super.key,
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
  bool? _optimisticLiked;

  int get _likeCount {
    final base = widget.post.likedBy.length;
    if (_optimisticLiked == null) return base;
    final wasLiked = widget.post.isLikedBy(widget.currentUserId);
    if (_optimisticLiked == true && !wasLiked) return base + 1;
    if (_optimisticLiked == false && wasLiked) return base - 1;
    return base;
  }

  bool get _isLiked {
    if (_optimisticLiked != null) return _optimisticLiked!;
    return widget.post.isLikedBy(widget.currentUserId);
  }

  bool get _isOwn => widget.post.authorId == widget.currentUserId;

  Future<void> _toggleLike() async {
    if (_likeLoading || widget.currentUserId.isEmpty) return;
    final wasLiked = _isLiked;
    setState(() {
      _optimisticLiked = !wasLiked;
      _likeLoading = true;
    });
    try {
      final ref = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
      if (wasLiked) {
        await ref.update({'likedBy': FieldValue.arrayRemove([widget.currentUserId])});
      } else {
        await ref.update({'likedBy': FieldValue.arrayUnion([widget.currentUserId])});
        try {
          final auth = Provider.of<AuthService>(context, listen: false);
          final me = await auth.getFullUserProfile(widget.currentUserId);
          await NotificationService.send(
            toUserId: widget.post.authorId,
            type: 'like',
            message: 'liked your post',
            senderName: me?.name ?? '',
            senderPhoto: me?.profilePicture,
          );
        } catch (e) {
          debugPrint('Notification error: $e');
        }
      }
    } catch (e) {
    }
    if (mounted) {
      setState(() {
        _likeLoading = false;
        _optimisticLiked = null;
      });
    }
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
                    child: _TaggedUsersRow(
                      taggedUserNames: post.taggedUserNames,
                      taggedUserIds: post.taggedUsers,
                      onUserTap: _openAuthorProfile,
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
                        label: _likeCount.toString(),
                        color:
                            _isLiked ? Colors.redAccent : AppColors.mutedText,
                        onTap: _toggleLike,
                        loading: _likeLoading,
                      ),
                      StreamBuilder<List<Comment>>(
                        stream: widget.postService.getCommentsStream(widget.post.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? post.comments;
                          return _ActionBtn(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: count.toString(),
                            color: AppColors.mutedText,
                            onTap: _showComments,
                          );
                        },
                      ),
                      _ActionBtn(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: AppColors.mutedText,
                          onTap: () async {
                          final text = '${post.author} on Wi:\n\n${post.content}\n\nDownload Wi app!';
                          await Share.share(text);
                        },
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

class _TaggedUsersRow extends StatelessWidget {
  final List<String> taggedUserNames;
  final List<String> taggedUserIds;
  final void Function(String uid) onUserTap;

  const _TaggedUsersRow({
    required this.taggedUserNames,
    required this.taggedUserIds,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_pin_rounded, size: 14, color: AppColors.wisteria),
            SizedBox(width: 4),
            Text('with', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ),
        ...List.generate(taggedUserNames.length, (i) {
          final name = i < taggedUserNames.length ? taggedUserNames[i] : '';
          final uid = i < taggedUserIds.length ? taggedUserIds[i] : '';
          return GestureDetector(
            onTap: uid.isNotEmpty ? () => onUserTap(uid) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.wisteria.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
              ),
              child: Text(
                '@$name',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.wisteria,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ],
    );
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
