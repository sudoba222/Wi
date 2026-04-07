// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../models/user_profile.dart';
import '../../models/experience.dart';
import '../../models/education.dart';
import '../../services/auth_services.dart' hide UserProfile;
import '../../services/cloudinary_service.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  const ProfilePage({super.key, required this.userProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isConnected = false;
  late UserProfile _currentProfile;
  File? _profileImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const double _expandedHeight = 300.0;

  double _collapseProgress(BuildContext context) {
    final statusBar = MediaQuery.of(context).padding.top;
    final maxScroll = _expandedHeight - kToolbarHeight - statusBar;
    return (_scrollOffset / maxScroll).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _collapseProgress(context);
    // Name fades in during the last 40% of the collapse stroke
    final titleOpacity = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.darkPurple,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkPurple, AppColors.wisteria],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              backgroundColor: AppColors.darkPurple,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              // No actions — three-dot removed
              title: Opacity(
                opacity: titleOpacity,
                child: Text(
                  _currentProfile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _buildMorphingHeader(_currentProfile, progress),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProfileHeader(_currentProfile),
                  _buildStatsSection(_currentProfile),
                  _buildAboutSection(_currentProfile),
                  _buildExperienceSection(_currentProfile),
                  _buildEducationSection(_currentProfile),
                  _buildSkillsSection(_currentProfile),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scroll-driven header: large photo with name overlay → small circular avatar.
  /// progress = 0 → fully expanded ; progress = 1 → fully collapsed (pinned toolbar)
  Widget _buildMorphingHeader(UserProfile profile, double progress) {
    // Photo size: large square → small circle
    const double expandedSize = 160;
    const double collapsedSize = 48;
    final photoSize = expandedSize + (collapsedSize - expandedSize) * progress;

    // Border radius: slight rounding → perfect circle
    final borderRadius = 16.0 + (photoSize / 2 - 16.0) * progress;

    // Vertical alignment within the pinned background (height = _expandedHeight).
    // At progress=0 the photo is centered (y≈0).
    // At progress=1 the visible area is ~toolbar+statusBar px tall, so we push
    // the photo toward the very top to stay visible after clipping.
    final verticalAlignment = 0.0 + (-0.88 - 0.0) * progress; // 0 → -0.88

    // Overlays & camera fade out in the first half of the collapse
    final overlayOpacity = (1.0 - progress * 2.2).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always-visible background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkPurple, AppColors.wisteria],
            ),
          ),
        ),

        // Top scrim so back button stays readable at all scroll positions
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, -0.25),
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
            ),
          ),
        ),

        // ── The morphing photo ──────────────────────────────────────────────
        Align(
          alignment: Alignment(0, verticalAlignment),
          child: Container(
            width: photoSize,
            height: photoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.25 + 0.75 * progress),
                width: 2.0 + progress,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35 * (1 - progress * 0.6)),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: _buildPhotoContent(profile),
            ),
          ),
        ),

        // Bottom gradient + name text — fades out while collapsing
        Opacity(
          opacity: overlayOpacity,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1))],
                    ),
                  ),
                  if (profile.jobTitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      profile.jobTitle.isNotEmpty && profile.company.isNotEmpty
                          ? '${profile.jobTitle} at ${profile.company}'
                          : profile.jobTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 14,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Camera edit button — fades out as header collapses
        if (profile.isOwnProfile)
          Opacity(
            opacity: overlayOpacity,
            child: Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: _editProfilePicture,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sunglow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, size: 20, color: AppColors.darkPurple),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The actual image / initial-letter content for the morphing photo.
  Widget _buildPhotoContent(UserProfile profile) {
    if (_isUploadingImage) {
      return Container(
        color: AppColors.darkPurple,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }
    if (_profileImage != null) {
      return Image.file(_profileImage!, fit: BoxFit.cover);
    }
    if (profile.profilePicture.isNotEmpty) {
      return Image.network(
        profile.profilePicture,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialLetter(profile),
      );
    }
    return _buildInitialLetter(profile);
  }

  Widget _buildInitialLetter(UserProfile profile) {
    return Container(
      color: AppColors.wisteria,
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Location row
              GestureDetector(
                onTap: profile.isOwnProfile ? _editBasicInfo : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.darkPurple.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      profile.location.isNotEmpty ? profile.location : 'Add location',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkPurple.withOpacity(0.6),
                        fontStyle: profile.location.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (profile.isOwnProfile) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 12, color: AppColors.darkPurple.withOpacity(0.4)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  if (profile.isOwnProfile) ...[
                    Expanded(
                      child: _buildActionButton(
                        label: 'Edit Profile',
                        icon: Icons.edit,
                        isPrimary: true,
                        onTap: _editBasicInfo,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _buildActionButton(
                        label: _isConnected ? 'Connected' : 'Connect',
                        icon: _isConnected ? Icons.check : Icons.person_add,
                        isPrimary: !_isConnected,
                        onTap: () => setState(() => _isConnected = !_isConnected),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Message',
                        icon: Icons.message,
                        isPrimary: false,
                        onTap: () {},
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.sunglow : Colors.white.withOpacity(0.15),
        foregroundColor: AppColors.darkPurple,
        elevation: 0,
        side: isPrimary
            ? null
            : BorderSide(color: AppColors.darkPurple.withOpacity(0.4), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.sunglow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
            children: [
              Expanded(child: _buildStatItem('Connections', profile.connections.toString())),
              Container(width: 1, height: 40, color: AppColors.darkPurple.withOpacity(0.15)),
              Expanded(child: _buildStatItem('Posts', profile.posts.toString())),
              Container(width: 1, height: 40, color: AppColors.darkPurple.withOpacity(0.15)),
              Expanded(child: _buildStatItem('Followers', profile.followers.toString())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.darkPurple.withOpacity(0.55), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAboutSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('About'),
                  if (profile.isOwnProfile)
                    IconButton(onPressed: _editAbout, icon: const Icon(Icons.edit, color: AppColors.darkPurple)),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: profile.isOwnProfile ? _editAbout : null,
                child: Text(
                  profile.bio.isEmpty ? 'Add a bio to tell people about yourself' : profile.bio,
                  style: TextStyle(
                    fontSize: 15,
                    color: profile.bio.isEmpty ? Colors.grey : AppColors.darkPurple.withOpacity(0.8),
                    height: 1.5,
                    fontStyle: profile.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _editProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(icon: Icons.camera_alt, label: 'Camera', onTap: () => _pickImage(ImageSource.camera)),
                _buildImageOption(icon: Icons.photo_library, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery)),
                if (_profileImage != null || _currentProfile.profilePicture.isNotEmpty)
                  _buildImageOption(icon: Icons.delete, label: 'Remove', onTap: _removeProfilePicture, isDestructive: true),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppColors.wisteria.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isDestructive ? Colors.red : AppColors.darkPurple),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isDestructive ? Colors.red : AppColors.darkPurple, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);
        Navigator.pop(context);

        final cloudinaryService = CloudinaryService();
        final imageUrl = await cloudinaryService.uploadProfilePicture(File(pickedFile.path));

        if (imageUrl != null) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final uid = authService.currentUser?.uid;

          if (uid != null) {
            await authService.firestore
                .collection('users')
                .doc(uid)
                .update({'profilePicture': imageUrl});
          }

          setState(() {
            _profileImage = File(pickedFile.path);
            _currentProfile = UserProfile(
              id: _currentProfile.id,
              name: _currentProfile.name,
              jobTitle: _currentProfile.jobTitle,
              company: _currentProfile.company,
              location: _currentProfile.location,
              bio: _currentProfile.bio,
              profilePicture: imageUrl,
              connections: _currentProfile.connections,
              posts: _currentProfile.posts,
              followers: _currentProfile.followers,
              experience: _currentProfile.experience,
              education: _currentProfile.education,
              skills: _currentProfile.skills,
              isOwnProfile: _currentProfile.isOwnProfile,
            );
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() => _isUploadingImage = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      Navigator.pop(context);
    }
  }

  void _removeProfilePicture() {
    setState(() {
      _profileImage = null;
      _currentProfile = UserProfile(
        id: _currentProfile.id,
        name: _currentProfile.name,
        jobTitle: _currentProfile.jobTitle,
        company: _currentProfile.company,
        location: _currentProfile.location,
        bio: _currentProfile.bio,
        profilePicture: '',
        connections: _currentProfile.connections,
        posts: _currentProfile.posts,
        followers: _currentProfile.followers,
        experience: _currentProfile.experience,
        education: _currentProfile.education,
        skills: _currentProfile.skills,
        isOwnProfile: _currentProfile.isOwnProfile,
      );
    });
    Navigator.pop(context);
  }

  void _editBasicInfo() {
    final nameController = TextEditingController(text: _currentProfile.name);
    final jobTitleController = TextEditingController(text: _currentProfile.jobTitle);
    final companyController = TextEditingController(text: _currentProfile.company);
    final locationController = TextEditingController(text: _currentProfile.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Basic Info', style: TextStyle(color: AppColors.darkPurple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: jobTitleController, decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore.collection('users').doc(uid).update({
                  'fullName': nameController.text,
                  'jobTitle': jobTitleController.text,
                  'company': companyController.text,
                  'location': locationController.text,
                });
              }
              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: nameController.text,
                  jobTitle: jobTitleController.text,
                  company: companyController.text,
                  location: locationController.text,
                  bio: _currentProfile.bio,
                  profilePicture: _currentProfile.profilePicture,
                  connections: _currentProfile.connections,
                  posts: _currentProfile.posts,
                  followers: _currentProfile.followers,
                  experience: _currentProfile.experience,
                  education: _currentProfile.education,
                  skills: _currentProfile.skills,
                  isOwnProfile: _currentProfile.isOwnProfile,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunglow),
            child: const Text('Save', style: TextStyle(color: AppColors.darkPurple)),
          ),
        ],
      ),
    );
  }

  void _editAbout() {
    final bioController = TextEditingController(text: _currentProfile.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit About', style: TextStyle(color: AppColors.darkPurple)),
        content: TextField(
          controller: bioController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'About yourself',
            border: OutlineInputBorder(),
            hintText: 'Tell people about yourself...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore
                    .collection('users')
                    .doc(uid)
                    .update({'bio': bioController.text});
              }
              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  jobTitle: _currentProfile.jobTitle,
                  company: _currentProfile.company,
                  location: _currentProfile.location,
                  bio: bioController.text,
                  profilePicture: _currentProfile.profilePicture,
                  connections: _currentProfile.connections,
                  posts: _currentProfile.posts,
                  followers: _currentProfile.followers,
                  experience: _currentProfile.experience,
                  education: _currentProfile.education,
                  skills: _currentProfile.skills,
                  isOwnProfile: _currentProfile.isOwnProfile,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunglow),
            child: const Text('Save', style: TextStyle(color: AppColors.darkPurple)),
          ),
        ],
      ),
    );
  }
  void _addExperience() => _showExperienceDialog(null);
  void _editExperience(Experience experience) => _showExperienceDialog(experience);

  void _showExperienceDialog(Experience? experience) {
    final isEditing = experience != null;
    final positionController = TextEditingController(text: experience?.position ?? '');
    final companyController = TextEditingController(text: experience?.company ?? '');
    final locationController = TextEditingController(text: experience?.location ?? '');
    final descriptionController = TextEditingController(text: experience?.description ?? '');
    bool isCurrent = experience?.isCurrent ?? false;
    DateTime startDate = experience?.startDate ?? DateTime.now();
    DateTime? endDate = experience?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Experience' : 'Add Experience', style: const TextStyle(color: AppColors.darkPurple)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isCurrent,
                      onChanged: (value) {
                        setDialogState(() {
                          isCurrent = value ?? false;
                          if (isCurrent) endDate = null;
                        });
                      },
                    ),
                    const Text('I currently work here'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newExperience = Experience(
                  id: experience?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  position: positionController.text,
                  company: companyController.text,
                  location: locationController.text,
                  startDate: startDate,
                  endDate: isCurrent ? null : endDate,
                  isCurrent: isCurrent,
                  description: descriptionController.text,
                );

                List<Experience> updated = List.from(_currentProfile.experience);
                if (isEditing) {
                  final index = updated.indexWhere((exp) => exp.id == experience!.id);
                  if (index != -1) updated[index] = newExperience;
                } else {
                  updated.add(newExperience);
                }

                final authService = Provider.of<AuthService>(context, listen: false);
                final uid = authService.currentUser?.uid;
                if (uid != null) {
                  await authService.firestore.collection('users').doc(uid).update({
                    'experience': updated.map((e) => e.toMap()).toList(),
                  });
                }

                setState(() {
                  _currentProfile = UserProfile(
                    id: _currentProfile.id,
                    name: _currentProfile.name,
                    jobTitle: _currentProfile.jobTitle,
                    company: _currentProfile.company,
                    location: _currentProfile.location,
                    bio: _currentProfile.bio,
                    profilePicture: _currentProfile.profilePicture,
                    connections: _currentProfile.connections,
                    posts: _currentProfile.posts,
                    followers: _currentProfile.followers,
                    experience: updated,
                    education: _currentProfile.education,
                    skills: _currentProfile.skills,
                    isOwnProfile: _currentProfile.isOwnProfile,
                  );
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunglow),
              child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: AppColors.darkPurple)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExperience(Experience experience) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Experience', style: TextStyle(color: AppColors.darkPurple)),
        content: Text('Are you sure you want to delete "${experience.position}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedExperience = _currentProfile.experience
                  .where((exp) => exp.id != experience.id)
                  .toList();

              final authService = Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore.collection('users').doc(uid).update({
                  'experience': updatedExperience.map((e) => e.toMap()).toList(),
                });
              }

              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  jobTitle: _currentProfile.jobTitle,
                  company: _currentProfile.company,
                  location: _currentProfile.location,
                  bio: _currentProfile.bio,
                  profilePicture: _currentProfile.profilePicture,
                  connections: _currentProfile.connections,
                  posts: _currentProfile.posts,
                  followers: _currentProfile.followers,
                  experience: updatedExperience,
                  education: _currentProfile.education,
                  skills: _currentProfile.skills,
                  isOwnProfile: _currentProfile.isOwnProfile,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addEducation() => _showEducationDialog(null);
  void _editEducation(Education education) => _showEducationDialog(education);

  void _showEducationDialog(Education? education) {
    final isEditing = education != null;
    final institutionController = TextEditingController(text: education?.institution ?? '');
    final degreeController = TextEditingController(text: education?.degree ?? '');
    final fieldController = TextEditingController(text: education?.fieldOfStudy ?? '');
    final gradeController = TextEditingController(text: education?.grade ?? '');
    final descriptionController = TextEditingController(text: education?.description ?? '');
    DateTime startDate = education?.startDate ?? DateTime.now();
    DateTime? endDate = education?.endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Edit Education' : 'Add Education', style: const TextStyle(color: AppColors.darkPurple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: institutionController, decoration: const InputDecoration(labelText: 'Institution', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: fieldController, decoration: const InputDecoration(labelText: 'Field of Study', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'Grade/GPA (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEducation = Education(
                id: education?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                institution: institutionController.text,
                degree: degreeController.text,
                fieldOfStudy: fieldController.text,
                startDate: startDate,
                endDate: endDate,
                grade: gradeController.text,
                description: descriptionController.text,
              );

              List<Education> updated = List.from(_currentProfile.education);
              if (isEditing) {
                final index = updated.indexWhere((edu) => edu.id == education!.id);
                if (index != -1) updated[index] = newEducation;
              } else {
                updated.add(newEducation);
              }

              final authService = Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore.collection('users').doc(uid).update({
                  'education': updated.map((e) => e.toMap()).toList(),
                });
              }

              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  jobTitle: _currentProfile.jobTitle,
                  company: _currentProfile.company,
                  location: _currentProfile.location,
                  bio: _currentProfile.bio,
                  profilePicture: _currentProfile.profilePicture,
                  connections: _currentProfile.connections,
                  posts: _currentProfile.posts,
                  followers: _currentProfile.followers,
                  experience: _currentProfile.experience,
                  education: updated,
                  skills: _currentProfile.skills,
                  isOwnProfile: _currentProfile.isOwnProfile,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunglow),
            child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: AppColors.darkPurple)),
          ),
        ],
      ),
    );
  }

  void _deleteEducation(Education education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Education', style: TextStyle(color: AppColors.darkPurple)),
        content: Text('Are you sure you want to delete "${education.institution}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedEducation = _currentProfile.education
                  .where((edu) => edu.id != education.id)
                  .toList();

              final authService = Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore.collection('users').doc(uid).update({
                  'education': updatedEducation.map((e) => e.toMap()).toList(),
                });
              }

              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  jobTitle: _currentProfile.jobTitle,
                  company: _currentProfile.company,
                  location: _currentProfile.location,
                  bio: _currentProfile.bio,
                  profilePicture: _currentProfile.profilePicture,
                  connections: _currentProfile.connections,
                  posts: _currentProfile.posts,
                  followers: _currentProfile.followers,
                  experience: _currentProfile.experience,
                  education: updatedEducation,
                  skills: _currentProfile.skills,
                  isOwnProfile: _currentProfile.isOwnProfile,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Widget _buildExperienceSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Experience'),
                  if (profile.isOwnProfile)
                    IconButton(onPressed: _addExperience, icon: const Icon(Icons.add, color: AppColors.darkPurple)),
                ],
              ),
              const SizedBox(height: 12),
              if (profile.experience.isEmpty && profile.isOwnProfile)
                GestureDetector(
                  onTap: _addExperience,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppColors.darkPurple.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text('Add your work experience', style: TextStyle(color: AppColors.darkPurple.withOpacity(0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                )
              else
                ...profile.experience.map((exp) => _buildExperienceCard(exp, profile.isOwnProfile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(Experience experience, bool isOwn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work, color: AppColors.darkPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(experience.position, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkPurple)),
                    ),
                    if (isOwn) ...[
                      IconButton(onPressed: () => _editExperience(experience), icon: const Icon(Icons.edit, size: 16, color: AppColors.darkPurple)),
                      IconButton(onPressed: () => _deleteExperience(experience), icon: const Icon(Icons.delete, size: 16, color: Colors.red)),
                    ],
                  ],
                ),
                Text('${experience.company} • ${experience.location}', style: TextStyle(fontSize: 14, color: AppColors.darkPurple.withOpacity(0.7))),
                Text(experience.duration, style: TextStyle(fontSize: 13, color: AppColors.darkPurple.withOpacity(0.5))),
                if (experience.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(experience.description, style: TextStyle(fontSize: 14, color: AppColors.darkPurple.withOpacity(0.8), height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Education'),
                  if (profile.isOwnProfile)
                    IconButton(onPressed: _addEducation, icon: const Icon(Icons.add, color: AppColors.darkPurple)),
                ],
              ),
              const SizedBox(height: 12),
              if (profile.education.isEmpty && profile.isOwnProfile)
                GestureDetector(
                  onTap: _addEducation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppColors.darkPurple.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text('Add your education', style: TextStyle(color: AppColors.darkPurple.withOpacity(0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                )
              else
                ...profile.education.map((edu) => _buildEducationCard(edu, profile.isOwnProfile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationCard(Education education, bool isOwn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sunglow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: AppColors.darkPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(education.institution, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkPurple)),
                    ),
                    if (isOwn) ...[
                      IconButton(onPressed: () => _editEducation(education), icon: const Icon(Icons.edit, size: 16, color: AppColors.darkPurple)),
                      IconButton(onPressed: () => _deleteEducation(education), icon: const Icon(Icons.delete, size: 16, color: Colors.red)),
                    ],
                  ],
                ),
                Text('${education.degree} in ${education.fieldOfStudy}', style: TextStyle(fontSize: 14, color: AppColors.darkPurple.withOpacity(0.7))),
                Row(
                  children: [
                    Text(education.duration, style: TextStyle(fontSize: 13, color: AppColors.darkPurple.withOpacity(0.5))),
                    if (education.grade.isNotEmpty)
                      Text(' • ${education.grade}', style: TextStyle(fontSize: 13, color: AppColors.darkPurple.withOpacity(0.5))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Skills'),
                  if (profile.isOwnProfile)
                    IconButton(onPressed: _editSkills, icon: const Icon(Icons.edit, color: AppColors.darkPurple)),
                ],
              ),
              const SizedBox(height: 12),
              if (profile.skills.isEmpty && profile.isOwnProfile)
                GestureDetector(
                  onTap: _editSkills,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppColors.darkPurple.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text('Add your skills', style: TextStyle(color: AppColors.darkPurple.withOpacity(0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((skill) => _buildSkillChip(skill, profile.isOwnProfile)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill, bool isOwn) {
    return GestureDetector(
      onTap: isOwn ? _editSkills : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(skill, style: const TextStyle(fontSize: 13, color: AppColors.darkPurple, fontWeight: FontWeight.w500)),
            if (isOwn) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 12, color: AppColors.darkPurple),
            ],
          ],
        ),
      ),
    );
  }

  void _editSkills() {
    final skillController = TextEditingController();
    List<String> currentSkills = List.from(_currentProfile.skills);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Skills', style: TextStyle(color: AppColors.darkPurple)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skillController,
                        decoration: const InputDecoration(labelText: 'Add a skill', border: OutlineInputBorder()),
                        onSubmitted: (value) {
                          if (value.isNotEmpty && !currentSkills.contains(value)) {
                            setDialogState(() {
                              currentSkills.add(value);
                              skillController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (skillController.text.isNotEmpty && !currentSkills.contains(skillController.text)) {
                          setDialogState(() {
                            currentSkills.add(skillController.text);
                            skillController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add, color: AppColors.darkPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentSkills.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentSkills.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.wisteria.withOpacity(0.2),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setDialogState(() => currentSkills.remove(skill)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.darkPurple)),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                final uid = authService.currentUser?.uid;
                if (uid != null) {
                  await authService.firestore.collection('users').doc(uid).update({'skills': currentSkills});
                }
                setState(() {
                  _currentProfile = UserProfile(
                    id: _currentProfile.id,
                    name: _currentProfile.name,
                    jobTitle: _currentProfile.jobTitle,
                    company: _currentProfile.company,
                    location: _currentProfile.location,
                    bio: _currentProfile.bio,
                    profilePicture: _currentProfile.profilePicture,
                    connections: _currentProfile.connections,
                    posts: _currentProfile.posts,
                    followers: _currentProfile.followers,
                    experience: _currentProfile.experience,
                    education: _currentProfile.education,
                    skills: currentSkills,
                    isOwnProfile: _currentProfile.isOwnProfile,
                  );
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunglow),
              child: const Text('Save', style: TextStyle(color: AppColors.darkPurple)),
            ),
          ],
        ),
      ),
    );
  }
}