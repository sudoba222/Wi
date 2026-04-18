// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../models/post.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/fullscreen_image_viewer.dart';

class PostsPage extends StatelessWidget {
  final UserProfile profile;
  const PostsPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final subColor =
        isDark ? Colors.white60 : AppColors.darkPurple.withOpacity(0.55);

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          '${profile.name}\'s Posts',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: profile.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.wisteria));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: subColor),
                  const SizedBox(height: 16),
                  Text('No posts yet',
                      style: TextStyle(fontSize: 16, color: subColor)),
                ],
              ),
            );
          }

          final posts = snapshot.data!.docs
              .map((d) => Post.fromFirestore(d))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              return _PostCard(
                post: posts[i],
                isOwner: posts[i].authorId == myUid,
                cardColor: cardColor,
                textColor: textColor,
                subColor: subColor,
              );
            },
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool isOwner;
  final Color cardColor, textColor, subColor;

  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ][time.month - 1];
    return '$m ${time.day}, ${time.year}';
  }

  Future<void> _editPost(BuildContext context) async {
    final controller = TextEditingController(text: post.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text('Edit Post',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.darkPurple,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkPurple),
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: TextStyle(
                color: isDark
                    ? Colors.white38
                    : AppColors.darkPurple.withOpacity(0.4)),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.07)
                : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wisteria,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .update({'content': controller.text.trim()});
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text('Delete Post',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.darkPurple,
                fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this post?',
            style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.darkPurple)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.wisteria,
                backgroundImage: post.authorProfilePicture.isNotEmpty
                    ? NetworkImage(post.authorProfilePicture)
                    : null,
                child: post.authorProfilePicture.isEmpty
                    ? Text(
                        post.author.isNotEmpty
                            ? post.author[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    Text(_timeAgo(post.timestamp),
                        style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                ),
              ),
              // Three-dots menu (own posts only)
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editPost(context);
                    if (value == 'delete') _deletePost(context);
                  },
                  icon: Icon(Icons.more_vert, color: subColor, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.wisteria),
                          const SizedBox(width: 10),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          if (post.content.isNotEmpty)
            Text(post.content,
                style: TextStyle(fontSize: 14, color: textColor, height: 1.55)),
          // Images
          if (post.mediaUrls.isNotEmpty && post.mediaType == 'image') ...[
            const SizedBox(height: 10),
            post.mediaUrls.length == 1
                ? GestureDetector(
                    onTap: () =>
                        FullscreenImageViewer.show(context, post.mediaUrls),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        post.mediaUrls.first,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                height: 200,
                                color: AppColors.wisteria.withOpacity(0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.wisteria, strokeWidth: 2),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.wisteria.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: AppColors.wisteria, size: 36)),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.mediaUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => FullscreenImageViewer.show(
                            context, post.mediaUrls, index: i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(post.mediaUrls[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
          // Video
          if (post.mediaUrls.isNotEmpty && post.mediaType == 'video') ...[
            const SizedBox(height: 10),
            VideoPlayerWidget(videoUrl: post.mediaUrls.first),
          ],
          const SizedBox(height: 12),
          // Engagement row
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 16, color: subColor),
              const SizedBox(width: 4),
              Text('${post.likes}',
                  style: TextStyle(fontSize: 13, color: subColor)),
              const SizedBox(width: 18),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: subColor),
              const SizedBox(width: 4),
              Text('${post.comments}',
                  style: TextStyle(fontSize: 13, color: subColor)),
            ],
          ),
        ],
      ),
    );
  }
}
