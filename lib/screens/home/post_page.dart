// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../services/post_services.dart';
import '../../services/auth_services.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_profile.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  bool _isPosting = false;
  UserProfile? _userProfile;

  // Media
  List<File> _selectedImages = [];
  File? _selectedVideo;
  List<String> _uploadedMediaUrls = [];
  String _mediaType = '';

  // Location
  String _location = '';
  bool _loadingLocation = false;

  // Tagged users
  List<Map<String, dynamic>> _taggedUsers = [];

  static const int _maxChars = 2000;
  int get _charCount => _contentController.text.length;
  bool get _hasContent =>
      _contentController.text.trim().isNotEmpty ||
      _selectedImages.isNotEmpty ||
      _selectedVideo != null;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
    _loadProfile();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null) {
      final p = await auth.getFullUserProfile(auth.currentUser!.uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  // ── Pick images ─────────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((x) => File(x.path)).toList();
        _selectedVideo = null;
        _mediaType = 'image';
      });
    }
  }

  // ── Pick video ──────────────────────────────────────────────────────────────
  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImages = [];
        _mediaType = 'video';
      });
    }
  }

  // ── Get location ────────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    if (_location.isNotEmpty) {
      setState(() => _location = '');
      return;
    }
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationStr =
            '${place.locality ?? ''}, ${place.country ?? ''}'.trim();
        if (mounted) setState(() => _location = locationStr);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ── Tag users ───────────────────────────────────────────────────────────────
  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TagUserSheet(
        alreadyTagged: _taggedUsers,
        onTagged: (users) {
          setState(() => _taggedUsers = users);
        },
      ),
    );
  }

  // ── Publish ─────────────────────────────────────────────────────────────────
  Future<void> _publish() async {
    final text = _contentController.text.trim();
    if (!_hasContent || _isPosting) return;
    setState(() => _isPosting = true);

    try {
      // Upload images
      if (_selectedImages.isNotEmpty) {
        for (final image in _selectedImages) {
          final url = await _cloudinary.uploadPostImage(image);
          if (url != null) _uploadedMediaUrls.add(url);
        }
      }

      // Upload video
      if (_selectedVideo != null) {
        final url = await _cloudinary.uploadVideo(_selectedVideo!);
        if (url != null) _uploadedMediaUrls.add(url);
      }

      final taggedUserIds =
          _taggedUsers.map((u) => u['uid'] as String).toList();

      final success = await PostService().createPost(
        content: text,
        mediaUrls: _uploadedMediaUrls,
        mediaType: _mediaType,
        location: _location,
        taggedUsers: taggedUserIds,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopBar(context, topPad, isDark, textColor),
          _buildAuthorRow(isDark, textColor),

          // Location tag
          if (_location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.wisteria),
                  const SizedBox(width: 4),
                  Text(_location,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.wisteria)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _location = ''),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),

          // Tagged users
          if (_taggedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Wrap(
                spacing: 8,
                children: _taggedUsers.map((u) {
                  return Chip(
                    label: Text('@${u['name']}',
                        style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _taggedUsers.remove(u));
                    },
                    backgroundColor: AppColors.wisteria.withOpacity(0.15),
                    side: BorderSide(
                        color: AppColors.wisteria.withOpacity(0.3)),
                  );
                }).toList(),
              ),
            ),

          // Text area
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                maxLength: _maxChars,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    const SizedBox.shrink(),
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 17, height: 1.65, color: textColor),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    fontSize: 17,
                    color: AppColors.mutedText.withOpacity(0.8),
                    height: 1.65,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          // Selected images preview
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImages.length,
                itemBuilder: (_, i) => Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() =>
                            _selectedImages.removeAt(i)),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selected video preview
          if (_selectedVideo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.wisteria.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.wisteria.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_rounded,
                        color: AppColors.wisteria),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedVideo!.path.split('/').last,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.wisteria),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedVideo = null),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.mutedText, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          _buildBottomToolbar(isDark, bottomPad),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, double topPad, bool isDark, Color textColor) {
    return Container(
      padding: EdgeInsets.only(top: topPad + 8, left: 4, right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppColors.wisteria.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Create Post',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ),
          GestureDetector(
            onTap: _hasContent && !_isPosting ? _publish : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _hasContent
                    ? AppColors.sunglow
                    : AppColors.mutedText.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : AppColors.darkPurple),
                    )
                  : Text(
                      'Publish',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _hasContent
                            ? AppColors.darkPurple
                            : AppColors.mutedText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Real profile picture
          _userProfile?.profilePicture != null &&
                  _userProfile!.profilePicture.isNotEmpty
              ? CircleAvatar(
                  radius: 23,
                  backgroundImage:
                      NetworkImage(_userProfile!.profilePicture),
                )
              : Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.wisteria, AppColors.splashPurple],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _userProfile?.name.isNotEmpty == true
                          ? _userProfile!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userProfile?.name ?? 'You',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.wisteria.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.wisteria.withOpacity(0.3), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public_rounded,
                        size: 13, color: AppColors.splashPurple),
                    SizedBox(width: 4),
                    Text('Public',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.splashPurple)),
                    SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14, color: AppColors.splashPurple),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark, double bottomPad) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 10, bottom: 10 + bottomPad),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.wisteria.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Image picker
              _ToolbarIcon(
                icon: Icons.image_outlined,
                active: _selectedImages.isNotEmpty,
                onTap: _pickImages,
              ),
              const SizedBox(width: 4),
              // Video picker
              _ToolbarIcon(
                icon: Icons.videocam_outlined,
                active: _selectedVideo != null,
                onTap: _pickVideo,
              ),
              const SizedBox(width: 4),
              // Tag users
              _ToolbarIcon(
                icon: Icons.person_add_outlined,
                active: _taggedUsers.isNotEmpty,
                onTap: _showTagSheet,
              ),
              const SizedBox(width: 4),
              // Location
              _ToolbarIcon(
                icon: Icons.location_on_outlined,
                active: _location.isNotEmpty,
                onTap: _getLocation,
                loading: _loadingLocation,
              ),
              const Spacer(),
              // Character counter
              Text(
                '$_charCount/$_maxChars',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _charCount > _maxChars * 0.9
                      ? (_charCount >= _maxChars ? Colors.red : Colors.orange)
                      : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool loading;

  const _ToolbarIcon({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.wisteria.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.wisteria),
                ),
              )
            : Icon(icon,
                size: 24,
                color: active ? AppColors.wisteria : AppColors.wisteria),
      ),
    );
  }
}

// ─── Tag User Sheet ────────────────────────────────────────────────────────────

class _TagUserSheet extends StatefulWidget {
  final List<Map<String, dynamic>> alreadyTagged;
  final void Function(List<Map<String, dynamic>>) onTagged;

  const _TagUserSheet({
    required this.alreadyTagged,
    required this.onTagged,
  });

  @override
  State<_TagUserSheet> createState() => _TagUserSheetState();
}

class _TagUserSheetState extends State<_TagUserSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _tagged = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tagged = List.from(widget.alreadyTagged);
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    try {
      final qCapitalized = q.isEmpty ? q : q[0].toUpperCase() + q.substring(1);

      final byCapitalized = await FirebaseFirestore.instance
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: qCapitalized)
          .where('fullName', isLessThanOrEqualTo: '$qCapitalized\uf8ff')
          .limit(10)
          .get();

      final byLower = await FirebaseFirestore.instance
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: q)
          .where('fullName', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(10)
          .get();

      final seen = <String>{};
      final results = <Map<String, dynamic>>[];
      for (final doc in [...byCapitalized.docs, ...byLower.docs]) {
        if (seen.add(doc.id)) {
          results.add({...doc.data(), 'uid': doc.id});
        }
      }

      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleTag(Map<String, dynamic> user) {
    setState(() {
      final exists = _tagged.any((u) => u['uid'] == user['uid']);
      if (exists) {
        _tagged.removeWhere((u) => u['uid'] == user['uid']);
      } else {
        _tagged.add({
          'uid': user['uid'],
          'name': user['fullName'] ?? user['email'] ?? 'Unknown',
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDrawer : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Text('Tag People',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.darkPurple)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onTagged(_tagged);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sunglow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: AppColors.darkPurple,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.wisteria.withOpacity(0.3)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkPurple),
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: TextStyle(color: AppColors.mutedText),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.wisteria, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.wisteria, strokeWidth: 2))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _ctrl.text.isEmpty
                              ? 'Search for people to tag'
                              : 'No users found',
                          style: const TextStyle(
                              color: AppColors.mutedText, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final u = _results[i];
                          final name = u['fullName'] ?? 'Unknown';
                          final isTagged =
                              _tagged.any((t) => t['uid'] == u['uid']);
                          return ListTile(
                            leading: Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  AppColors.wisteria,
                                  AppColors.splashPurple
                                ]),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                            title: Text(name,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkPurple,
                                    fontWeight: FontWeight.w600)),
                            trailing: isTagged
                                ? const Icon(Icons.check_circle_rounded,
                                    color: AppColors.wisteria)
                                : const Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    color: AppColors.mutedText),
                            onTap: () => _toggleTag(u),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}