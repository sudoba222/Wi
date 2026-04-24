// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/post_services.dart';
import '../services/auth_services.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

/// Beautiful bottom-sheet style comments panel with glassmorphism cards,
/// avatar circles, like buttons, and a sticky reply input bar.
class CommentsDialog extends StatefulWidget {
  final Post post;
  const CommentsDialog({super.key, required this.post});

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _postService = PostService();
  bool _posting = false;

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Submits the comment text to Firestore via PostService.
  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final ok = await _postService.addComment(widget.post.id, text);
    if (ok) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final me = auth.currentUser != null
            ? await auth.getFullUserProfile(auth.currentUser!.uid)
            : null;
        await NotificationService.send(
          toUserId: widget.post.authorId,
          type: 'comment',
          message: 'commented on your post',
          senderName: me?.name ?? '',
          senderPhoto: me?.profilePicture,
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }
    }
    if (mounted) setState(() => _posting = false);
    if (ok) {
      _controller.clear();
      // Scroll to the latest comment after posting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment'), backgroundColor: Colors.red),
      );
    }
  }

  /// Toggles a like on a comment.
  Future<void> _toggleLike(Comment c) async {
    await _postService.toggleCommentLike(widget.post.id, c.id);
  }

  /// Confirms and deletes the user's own comment.
  void _confirmDelete(Comment c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete comment?', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.mutedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await _postService.deleteComment(widget.post.id, c.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Comment deleted' : 'Failed to delete'),
                  backgroundColor: ok ? AppColors.sunglow : Colors.red,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Takes up to 85% of screen height
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E0B2C) : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.wisteria, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.darkPurple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ),

          // ── Original post preview ─────────────────────────────────────────
          _PostPreview(post: widget.post, isDark: isDark),

          const SizedBox(height: 4),

          // ── Comments list ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _postService.getCommentsStream(widget.post.id),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.wisteria, strokeWidth: 2));
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return _EmptyComments(isDark: isDark);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentCard(
                    comment: comments[i],
                    currentUid: uid,
                    isDark: isDark,
                    onLike: () => _toggleLike(comments[i]),
                    onDelete: () => _confirmDelete(comments[i]),
                  ),
                );
              },
            ),
          ),

          // ── Sticky reply input ────────────────────────────────────────────
          if (auth.currentUser != null) _ReplyBar(controller: _controller, posting: _posting, isDark: isDark, onSend: _submit),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Original post mini-preview inside the sheet ────────────────────────────

class _PostPreview extends StatelessWidget {
  final Post post;
  final bool isDark;
  const _PostPreview({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.07) : AppColors.wisteria.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // Author avatar
                _AvatarCircle(name: post.author, photo: post.authorProfilePicture, size: 30, fontSize: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.darkPurple)),
                      Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.4)),
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

// ── A single comment card ──────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final Comment comment;
  final String currentUid;
  final bool isDark;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment, required this.currentUid, required this.isDark,
    required this.onLike, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.authorId == currentUid;
    final isLiked = comment.isLikedBy(currentUid);
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final cardBg = isDark ? Colors.white.withOpacity(0.07) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.darkPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row + actions
            Row(
              children: [
                _AvatarCircle(name: comment.author, photo: comment.authorProfilePicture, size: 32, fontSize: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.author, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                      Text(_timeAgo(comment.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                // Delete option for own comments
                if (isOwn)
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Comment body
            Text(comment.content, style: TextStyle(fontSize: 14, color: textColor, height: 1.5)),
            const SizedBox(height: 8),
            // Like button
            GestureDetector(
              onTap: onLike,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isLiked),
                      size: 17,
                      color: isLiked ? Colors.redAccent : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comment.likes > 0 ? comment.likes.toString() : 'Like',
                    style: TextStyle(fontSize: 12, color: isLiked ? Colors.redAccent : AppColors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyComments extends StatelessWidget {
  final bool isDark;
  const _EmptyComments({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.wisteria.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 32, color: AppColors.wisteria),
          ),
          const SizedBox(height: 14),
          Text('No comments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.darkPurple)),
          const SizedBox(height: 4),
          const Text('Be the first to comment!', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

// ── Sticky reply input bar ─────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool posting;
  final bool isDark;
  final VoidCallback onSend;

  const _ReplyBar({required this.controller, required this.posting, required this.isDark, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85),
            border: Border(top: BorderSide(color: AppColors.wisteria.withOpacity(0.15))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : AppColors.background,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.darkPurple),
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Send button — amber when active
                GestureDetector(
                  onTap: posting ? null : onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.sunglow,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.sunglow.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: posting
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPurple))
                        : const Icon(Icons.send_rounded, color: AppColors.darkPurple, size: 20),
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

// ── Shared avatar circle ───────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String photo;
  final double size;
  final double fontSize;

  const _AvatarCircle({required this.name, required this.photo, required this.size, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple]),
      ),
      child: photo.isNotEmpty
          ? ClipOval(child: Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initial()))
          : _initial(),
    );
  }

  Widget _initial() => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700),
    ),
  );
}
