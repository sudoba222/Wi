import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/global_data.dart';
import '../../models/post.dart';
import '../../widgets/glassmorphic_container.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassmorphicContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.wisteria,
                          ),
                          child: const Center(
                            child: Text(
                              'Y',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Content Input
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.darkPurple,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'What\'s on your mind?',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Post Options
                    Row(
                      children: [
                        _buildPostOption(
                          icon: Icons.image_outlined,
                          label: 'Photo',
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _buildPostOption(
                          icon: Icons.videocam_outlined,
                          label: 'Video',
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _buildPostOption(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Post Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isPosting ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sunglow,
                          foregroundColor: AppColors.darkPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.darkPurple,
                                ),
                              )
                            : const Text(
                                'Post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.darkPurple.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkPurple.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'You',
      content: _contentController.text.trim(),
      timestamp: DateTime.now(),
    );

    GlobalData.addPost(newPost);

    setState(() {
      _isPosting = false;
      _contentController.clear();
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: AppColors.sunglow,
        ),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}