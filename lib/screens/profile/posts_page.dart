// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../models/post.dart';

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
            .orderBy('timestamp', descending: true)
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
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final post = posts[i];
              return _PostCard(
                post: post,
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
  final Color cardColor, textColor, subColor;

  const _PostCard({
    required this.post,
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
    final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][time.month - 1];
    return '$m ${time.day}, ${time.year}';
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
                            color: Colors.white, fontWeight: FontWeight.bold),
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
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Text(post.content,
              style: TextStyle(fontSize: 14, color: textColor, height: 1.55)),
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
