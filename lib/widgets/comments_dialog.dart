// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/post_services.dart';
import '../services/auth_services.dart';
import '../utils/app_colors.dart';

class CommentsDialog extends StatefulWidget {
  final Post post;

  const CommentsDialog({super.key, required this.post});

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  final TextEditingController _commentController = TextEditingController();
  final PostService _postService = PostService();
  bool _isPostingComment = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.darkPurple.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.wisteria.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wisteria.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.sunglow,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sunglow,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.sunglow, size: 24),
                  ),
                ],
              ),
            ),

            // Post Content
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.wisteria,
                        ),
                        child: widget.post.authorProfilePicture.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.post.authorProfilePicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildInitialAvatar(widget.post.author),
                                ),
                              )
                            : _buildInitialAvatar(widget.post.author),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.post.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkPurple,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Comments List
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: _postService.getCommentsStream(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.sunglow,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading comments',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(
                          color: AppColors.darkPurple.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(comments[index]);
                    },
                  );
                },
              ),
            ),

            // Comment Input
            if (currentUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.wisteria.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 280,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkPurple,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: AppColors.darkPurple.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _isPostingComment ? null : _postComment,
                      icon: _isPostingComment
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.sunglow,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: AppColors.sunglow,
                              size: 24,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isOwnComment = currentUser?.uid == comment.authorId;
    final isLiked = currentUser != null && comment.isLikedBy(currentUser.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.wisteria,
                ),
                child: comment.authorProfilePicture.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          comment.authorProfilePicture,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialAvatar(comment.author),
                        ),
                      )
                    : _buildInitialAvatar(comment.author),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.author,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple,
                  ),
                ),
              ),
              if (isOwnComment)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCommentAction(value, comment),
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: AppColors.darkPurple.withOpacity(0.6),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment Content
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkPurple,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Comment Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleCommentLike(comment),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked
                          ? Colors.red
                          : AppColors.darkPurple.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likes.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkPurple.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatTime(comment.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkPurple.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPostingComment = true);

    final success = await _postService.addComment(widget.post.id, content);

    setState(() => _isPostingComment = false);

    if (success) {
      _commentController.clear();
      // Show success message if needed
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    final success = await _postService.toggleCommentLike(
      widget.post.id,
      comment.id,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCommentAction(String action, Comment comment) {
    switch (action) {
      case 'delete':
        _showDeleteCommentConfirmation(comment);
        break;
    }
  }

  void _showDeleteCommentConfirmation(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _postService.deleteComment(
                widget.post.id,
                comment.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Comment deleted successfully'
                          : 'Failed to delete comment',
                    ),
                    backgroundColor: success ? AppColors.sunglow : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
