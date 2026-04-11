// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';
import '../../models/experience.dart';
import '../../models/education.dart';
import '../../services/auth_services.dart' hide UserProfile;
import '../../services/cloudinary_service.dart';
import 'connections_page.dart';
import 'followers_page.dart';
import 'posts_page.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  const ProfilePage({super.key, required this.userProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isConnected = false;
  bool _connectionLoading = false;
  late UserProfile _currentProfile;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  static const double _expandedHeight = 300.0;

  // 0 = at rest (circle), 1 = fully collapsed into toolbar
  double get _collapseProgress {
    const maxScroll = _expandedHeight - kToolbarHeight;
    return (_scrollOffset / maxScroll).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
    _scrollController.addListener(() {
      if (mounted) {
        setState(() =>
            _scrollOffset = _scrollController.offset.clamp(0.0, double.infinity));
      }
    });
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    if (_currentProfile.isOwnProfile) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentProfile.id)
        .collection('connections')
        .doc(myUid)
        .get();
    if (mounted) setState(() => _isConnected = doc.exists);
  }

  Future<void> _toggleConnection() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    setState(() => _connectionLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final profileConnRef = firestore
          .collection('users')
          .doc(_currentProfile.id)
          .collection('connections')
          .doc(myUid);
      final myConnRef = firestore
          .collection('users')
          .doc(myUid)
          .collection('connections')
          .doc(_currentProfile.id);

      if (_isConnected) {
        await profileConnRef.delete();
        await myConnRef.delete();
      } else {
        final myDoc = await firestore.collection('users').doc(myUid).get();
        final myData = myDoc.data() ?? {};
        await profileConnRef.set({
          'connectedAt': FieldValue.serverTimestamp(),
          'name': myData['fullName'] ?? '',
          'jobTitle': myData['jobTitle'] ?? '',
          'company': myData['company'] ?? '',
          'profilePicture': myData['profilePicture'] ?? '',
        });
        await myConnRef.set({
          'connectedAt': FieldValue.serverTimestamp(),
          'name': _currentProfile.name,
          'jobTitle': _currentProfile.jobTitle,
          'company': _currentProfile.company,
          'profilePicture': _currentProfile.profilePicture,
        });
      }
      if (mounted) setState(() => _isConnected = !_isConnected);
    } finally {
      if (mounted) setState(() => _connectionLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final subTextColor =
        isDark ? Colors.white60 : AppColors.darkPurple.withOpacity(0.55);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Collapsible banner with profile info ────────────────────────────
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: _collapseProgress > 0.7
                ? Opacity(
                    opacity: ((_collapseProgress - 0.7) / 0.3).clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentProfile.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_currentProfile.jobTitle.isNotEmpty ||
                            _currentProfile.location.isNotEmpty)
                          Text(
                            [
                              if (_currentProfile.jobTitle.isNotEmpty)
                                _currentProfile.jobTitle,
                              if (_currentProfile.location.isNotEmpty)
                                _currentProfile.location,
                            ].join(' · '),
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                      ],
                    ),
                  )
                : null,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildBanner(_currentProfile, _collapseProgress),
            ),
          ),

          // ── Profile body ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderCard(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 10),
                _buildStatsRow(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 10),
                _buildAboutSection(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 10),
                _buildExperienceSection(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 10),
                _buildEducationSection(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 10),
                _buildSkillsSection(
                    _currentProfile, cardColor, textColor, subTextColor),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AVATAR
  // ─────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // BANNER
  // Default:   circular avatar centered on gradient (Telegram Image 3)
  // Pull down: photo fills banner as rectangle   (Telegram Image 4)
  // Scroll up: banner collapses, content fades
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildBanner(UserProfile profile, double collapseProgress) {
    // collapseProgress = 0 → at rest (circle in center of banner)
    // collapseProgress = 1 → fully scrolled up (tiny circle in toolbar)
    //
    // expandProgress is derived inside LayoutBuilder from constraints.maxHeight.
    // When the user pulls down (overscroll), FlexibleSpaceBar gives a height
    // larger than _expandedHeight — this drives the circle → rectangle morph.

    final subtitle = [
      if (profile.jobTitle.isNotEmpty) profile.jobTitle,
      if (profile.location.isNotEmpty) profile.location,
    ].join(' · ');

    return LayoutBuilder(builder: (context, constraints) {
      final screenW = constraints.maxWidth;
      final currentH = constraints.maxHeight; // grows beyond 300 on pull-down
      final statusH = MediaQuery.of(context).padding.top;

      // expandProgress: 0 = at rest, 1 = photo fills banner as rectangle.
      // On mobile, LayoutBuilder reports expandedHeight + statusBarHeight at
      // rest (the SliverAppBar includes the status bar area in its height).
      // We subtract statusH so the morph only starts on actual overscroll.
      final restHeight = _expandedHeight + statusH;
      final expandProgress = ((currentH - restHeight) / 80.0).clamp(0.0, 1.0);

      // ── Default circle avatar metrics ─────────────────────────────────────
      const defaultSize = 112.0;
      const defaultRingPad = 3.0;
      const defaultGapPad = 2.0;
      // Centered horizontally; shifted down by statusH so avatar sits in the
      // visible banner area (below the status bar) on mobile.
      final defaultX = (screenW - defaultSize) / 2;
      final defaultY =
          statusH + ((_expandedHeight - statusH) / 2 - defaultSize / 2 - 28);

      // ── Collapse: circle shrinks and floats up into toolbar ───────────────
      const collapsedSize = 40.0;
      final collapsedX = (screenW - collapsedSize) / 2;
      final collapsedY = statusH + (kToolbarHeight - collapsedSize) / 2;

      final baseX = lerpDouble(defaultX, collapsedX, collapseProgress)!;
      final baseY = lerpDouble(defaultY, collapsedY, collapseProgress)!;
      final baseSize = lerpDouble(defaultSize, collapsedSize, collapseProgress)!;
      final baseRadius = baseSize / 2;

      // Ring + glow scale down as circle shrinks
      final ringScale = (1.0 - collapseProgress * 2.0).clamp(0.0, 1.0);
      final ringPad = defaultRingPad * ringScale;
      final gapPad = defaultGapPad * ringScale;
      final glowOpacity = 0.45 * ringScale * (1.0 - expandProgress);

      // ── Expand: circle morphs outward to fill the full banner ─────────────
      final avatarL = lerpDouble(baseX, 0.0, expandProgress)!;
      final avatarT = lerpDouble(baseY, 0.0, expandProgress)!;
      final avatarW = lerpDouble(baseSize, screenW, expandProgress)!;
      final avatarH = lerpDouble(baseSize, currentH, expandProgress)!;
      final avatarRadius = lerpDouble(baseRadius, 0.0, expandProgress)!;

      final currentRingPad = ringPad * (1.0 - expandProgress);
      final currentGapPad = gapPad * (1.0 - expandProgress);

      // ── Opacities ─────────────────────────────────────────────────────────
      // Info text fades as banner collapses OR as photo expands
      final infoOpacity =
          ((1.0 - collapseProgress * 2.5) * (1.0 - expandProgress * 2.0))
              .clamp(0.0, 1.0);
      // Name overlay at bottom-left appears as photo fills
      final overlayOpacity = (expandProgress * 3.0 - 0.8).clamp(0.0, 1.0);
      // Camera badge visible only near default state
      final badgeOpacity =
          ((1.0 - collapseProgress * 3.0) * (1.0 - expandProgress * 2.5))
              .clamp(0.0, 1.0);

      return Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.darkBg, AppColors.darkPurple],
              ),
            ),
          ),

          // ── Bottom scrim (text legibility when photo fills) ────────────────
          if (overlayOpacity > 0)
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 160,
              child: Opacity(
                opacity: overlayOpacity,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
            ),

          // ── Morphing avatar (circle ↔ rectangle) ──────────────────────────
          Positioned(
            left: avatarL,
            top: avatarT,
            width: avatarW,
            height: avatarH,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(avatarRadius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.wisteria, AppColors.splashPurple],
                ),
                boxShadow: glowOpacity > 0.01
                    ? [
                        BoxShadow(
                          color: AppColors.wisteria.withOpacity(glowOpacity),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              padding: EdgeInsets.all(currentRingPad),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(avatarRadius),
                  color: AppColors.darkBg,
                ),
                padding: EdgeInsets.all(currentGapPad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(avatarRadius),
                  child: _avatarFill(profile),
                ),
              ),
            ),
          ),

          // ── Info text: name · subtitle · member label ─────────────────────
          if (infoOpacity > 0)
            Positioned(
              left: 16, right: 16,
              top: defaultY + defaultSize + 14,
              child: Opacity(
                opacity: infoOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: profile.isOwnProfile ? _editBasicInfo : null,
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center)
                    else if (profile.isOwnProfile)
                      GestureDetector(
                        onTap: _editBasicInfo,
                        child: const Text('Add title · location',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 4),
                    const Text('Wi Network Member',
                        style: TextStyle(fontSize: 13, color: Colors.white54),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

          // ── Name overlay (bottom-left, appears as photo fills) ────────────
          if (overlayOpacity > 0)
            Positioned(
              left: 16, bottom: 20,
              right: profile.isOwnProfile ? 60 : 16,
              child: Opacity(
                opacity: overlayOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black87)
                          ],
                        )),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54)
                            ],
                          )),
                  ],
                ),
              ),
            ),

          // ── Camera badge (own profile, near-default state only) ───────────
          if (profile.isOwnProfile && badgeOpacity > 0)
            Positioned(
              left: avatarL + avatarW - 26,
              top: avatarT + avatarH - 26,
              child: Opacity(
                opacity: badgeOpacity,
                child: GestureDetector(
                  onTap: _editProfilePicture,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sunglow,
                      border: Border.all(color: AppColors.darkBg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: AppColors.darkPurple),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// The actual image/initial content that goes inside the avatar (circle or rectangle fill)
  Widget _avatarFill(UserProfile profile) {
    if (_isUploadingImage) {
      return Container(
        color: AppColors.wisteria,
        child: const Center(
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
      );
    }
    if (profile.profilePicture.isNotEmpty) {
      return Image.network(
        profile.profilePicture,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialBox(profile),
      );
    }
    return _initialBox(profile);
  }

  Widget _initialBox(UserProfile profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wisteria, AppColors.splashPurple],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.bold,
            letterSpacing: 1),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HEADER CARD  (action buttons only)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(UserProfile profile, Color cardColor, Color textColor,
      Color subTextColor) {
    return _card(
      cardColor: cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: profile.isOwnProfile
          ? SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                isPrimary: true,
                onTap: _editBasicInfo,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: _isConnected ? 'Connected' : 'Connect',
                    icon: _isConnected
                        ? Icons.how_to_reg_outlined
                        : Icons.person_add_alt_1_outlined,
                    isPrimary: !_isConnected,
                    isLoading: _connectionLoading,
                    onTap: _toggleConnection,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Message',
                    icon: Icons.send_outlined,
                    isPrimary: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? AppColors.sunglow : Colors.transparent,
        foregroundColor:
            isPrimary ? AppColors.darkPurple : AppColors.wisteria,
        elevation: 0,
        side: isPrimary
            ? null
            : const BorderSide(color: AppColors.wisteria, width: 1.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 11),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(UserProfile profile, Color cardColor, Color textColor,
      Color subTextColor) {
    final firestore = FirebaseFirestore.instance;
    return _card(
      cardColor: cardColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _liveStatItem(
              stream: firestore
                  .collection('users')
                  .doc(profile.id)
                  .collection('connections')
                  .snapshots(),
              label: 'Connections',
              subTextColor: subTextColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ConnectionsPage(profile: profile))),
            ),
            _verticalDivider(subTextColor),
            _liveStatItem(
              stream: firestore
                  .collection('posts')
                  .where('authorId', isEqualTo: profile.id)
                  .snapshots(),
              label: 'Posts',
              subTextColor: subTextColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PostsPage(profile: profile))),
            ),
            _verticalDivider(subTextColor),
            _liveStatItem(
              stream: firestore
                  .collection('users')
                  .doc(profile.id)
                  .collection('followers')
                  .snapshots(),
              label: 'Followers',
              subTextColor: subTextColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => FollowersPage(profile: profile))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveStatItem({
    required Stream<QuerySnapshot> stream,
    required String label,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.wisteria),
                ),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(fontSize: 11, color: subTextColor)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _verticalDivider(Color subTextColor) {
    return VerticalDivider(
        width: 1, thickness: 1, color: subTextColor.withOpacity(0.25));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SHARED SECTION CARD
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required Widget content,
    required Color cardColor,
    required Color textColor,
    VoidCallback? onAdd,
    VoidCallback? onEdit,
  }) {
    return _card(
      cardColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.wisteria,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),
              if (onAdd != null)
                _iconBtn(Icons.add_circle_outline_rounded, onAdd),
              if (onEdit != null)
                _iconBtn(Icons.edit_outlined, onEdit),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(icon, color: AppColors.wisteria, size: 21),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ABOUT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAboutSection(UserProfile profile, Color cardColor,
      Color textColor, Color subTextColor) {
    return _sectionCard(
      title: 'About',
      cardColor: cardColor,
      textColor: textColor,
      onEdit: profile.isOwnProfile ? _editAbout : null,
      content: GestureDetector(
        onTap: profile.isOwnProfile ? _editAbout : null,
        child: Text(
          profile.bio.isEmpty
              ? 'Add a bio to tell people about yourself'
              : profile.bio,
          style: TextStyle(
            fontSize: 14,
            color: profile.bio.isEmpty
                ? subTextColor
                : textColor.withOpacity(0.8),
            height: 1.65,
            fontStyle:
                profile.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EXPERIENCE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildExperienceSection(UserProfile profile, Color cardColor,
      Color textColor, Color subTextColor) {
    return _sectionCard(
      title: 'Experience',
      cardColor: cardColor,
      textColor: textColor,
      onAdd: profile.isOwnProfile ? _addExperience : null,
      content: profile.experience.isEmpty && profile.isOwnProfile
          ? _emptyPlaceholder(
              'Add your work experience', _addExperience, subTextColor)
          : Column(
              children: profile.experience
                  .map((exp) => _buildExperienceCard(
                      exp, profile.isOwnProfile, textColor, subTextColor))
                  .toList(),
            ),
    );
  }

  Widget _buildExperienceCard(Experience experience, bool isOwn,
      Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_center_rounded,
                color: AppColors.wisteria, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(experience.position,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                    ),
                    if (isOwn) ...[
                      GestureDetector(
                        onTap: () => _editExperience(experience),
                        child: Icon(Icons.edit_outlined,
                            size: 15, color: AppColors.wisteria),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _deleteExperience(experience),
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(experience.company,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subTextColor)),
                Text(experience.duration,
                    style: TextStyle(
                        fontSize: 12, color: subTextColor.withOpacity(0.7))),
                if (experience.location.isNotEmpty)
                  Text(experience.location,
                      style: TextStyle(
                          fontSize: 12,
                          color: subTextColor.withOpacity(0.7))),
                if (experience.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(experience.description,
                      style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.7),
                          height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EDUCATION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildEducationSection(UserProfile profile, Color cardColor,
      Color textColor, Color subTextColor) {
    return _sectionCard(
      title: 'Education',
      cardColor: cardColor,
      textColor: textColor,
      onAdd: profile.isOwnProfile ? _addEducation : null,
      content: profile.education.isEmpty && profile.isOwnProfile
          ? _emptyPlaceholder(
              'Add your education', _addEducation, subTextColor)
          : Column(
              children: profile.education
                  .map((edu) => _buildEducationCard(
                      edu, profile.isOwnProfile, textColor, subTextColor))
                  .toList(),
            ),
    );
  }

  Widget _buildEducationCard(
      Education education, bool isOwn, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.sunglow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded,
                color: AppColors.sunglow, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(education.institution,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                    ),
                    if (isOwn) ...[
                      GestureDetector(
                        onTap: () => _editEducation(education),
                        child: Icon(Icons.edit_outlined,
                            size: 15, color: AppColors.wisteria),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _deleteEducation(education),
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${education.degree} · ${education.fieldOfStudy}',
                    style:
                        TextStyle(fontSize: 13, color: subTextColor)),
                Row(
                  children: [
                    Text(education.duration,
                        style: TextStyle(
                            fontSize: 12,
                            color: subTextColor.withOpacity(0.7))),
                    if (education.grade.isNotEmpty)
                      Text(' · ${education.grade}',
                          style: TextStyle(
                              fontSize: 12,
                              color: subTextColor.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SKILLS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSkillsSection(UserProfile profile, Color cardColor,
      Color textColor, Color subTextColor) {
    return _sectionCard(
      title: 'Skills',
      cardColor: cardColor,
      textColor: textColor,
      onEdit: profile.isOwnProfile ? _editSkills : null,
      content: profile.skills.isEmpty && profile.isOwnProfile
          ? _emptyPlaceholder('Add your skills', _editSkills, subTextColor)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map((s) => _buildSkillChip(s, profile.isOwnProfile))
                  .toList(),
            ),
    );
  }

  Widget _buildSkillChip(String skill, bool isOwn) {
    return GestureDetector(
      onTap: isOwn ? _editSkills : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.wisteria.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.wisteria.withOpacity(0.45)),
        ),
        child: Text(skill,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.wisteria,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _card({
    required Widget child,
    required Color cardColor,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyPlaceholder(
      String text, VoidCallback onTap, Color subTextColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          border:
              Border.all(color: subTextColor.withOpacity(0.2), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                size: 18, color: AppColors.wisteria),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EDIT PROFILE PICTURE SHEET
  // ─────────────────────────────────────────────────────────────────────────────

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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPurple),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera)),
                _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery)),
                if (_currentProfile.profilePicture.isNotEmpty)
                  _buildImageOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: _removeProfilePicture,
                      isDestructive: true),
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
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppColors.wisteria.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isDestructive ? Colors.red : AppColors.darkPurple),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: isDestructive ? Colors.red : AppColors.darkPurple,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // IMAGE PICKER  (untouched backend logic)
  // ─────────────────────────────────────────────────────────────────────────────

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
        final imageUrl = await cloudinaryService
            .uploadProfilePicture(File(pickedFile.path));

        if (imageUrl != null) {
          final authService =
              Provider.of<AuthService>(context, listen: false);
          final uid = authService.currentUser?.uid;

          if (uid != null) {
            await authService.firestore
                .collection('users')
                .doc(uid)
                .update({'profilePicture': imageUrl});
          }

          setState(() {
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

  // ─────────────────────────────────────────────────────────────────────────────
  // EDIT DIALOGS  (untouched backend logic)
  // ─────────────────────────────────────────────────────────────────────────────

  void _editBasicInfo() {
    final nameController =
        TextEditingController(text: _currentProfile.name);
    final jobTitleController =
        TextEditingController(text: _currentProfile.jobTitle);
    final companyController =
        TextEditingController(text: _currentProfile.company);
    final locationController =
        TextEditingController(text: _currentProfile.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Basic Info',
            style: TextStyle(color: AppColors.darkPurple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: jobTitleController,
                  decoration: const InputDecoration(
                      labelText: 'Job Title',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: companyController,
                  decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore
                    .collection('users')
                    .doc(uid)
                    .update({
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow),
            child: const Text('Save',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
        ],
      ),
    );
  }

  void _editAbout() {
    final bioController =
        TextEditingController(text: _currentProfile.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit About',
            style: TextStyle(color: AppColors.darkPurple)),
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
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow),
            child: const Text('Save',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
        ],
      ),
    );
  }

  void _addExperience() => _showExperienceDialog(null);
  void _editExperience(Experience experience) =>
      _showExperienceDialog(experience);

  void _showExperienceDialog(Experience? experience) {
    final isEditing = experience != null;
    final positionController =
        TextEditingController(text: experience?.position ?? '');
    final companyController =
        TextEditingController(text: experience?.company ?? '');
    final locationController =
        TextEditingController(text: experience?.location ?? '');
    final descriptionController =
        TextEditingController(text: experience?.description ?? '');
    bool isCurrent = experience?.isCurrent ?? false;
    DateTime startDate = experience?.startDate ?? DateTime.now();
    DateTime? endDate = experience?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Experience' : 'Add Experience',
              style: const TextStyle(color: AppColors.darkPurple)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: positionController,
                    decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                        labelText: 'Company',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder())),
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
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.darkPurple)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newExperience = Experience(
                  id: experience?.id ??
                      DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                  position: positionController.text,
                  company: companyController.text,
                  location: locationController.text,
                  startDate: startDate,
                  endDate: isCurrent ? null : endDate,
                  isCurrent: isCurrent,
                  description: descriptionController.text,
                );

                List<Experience> updated =
                    List.from(_currentProfile.experience);
                if (isEditing) {
                  final index = updated
                      .indexWhere((exp) => exp.id == experience!.id);
                  if (index != -1) updated[index] = newExperience;
                } else {
                  updated.add(newExperience);
                }

                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final uid = authService.currentUser?.uid;
                if (uid != null) {
                  await authService.firestore
                      .collection('users')
                      .doc(uid)
                      .update({
                    'experience':
                        updated.map((e) => e.toMap()).toList(),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunglow),
              child: Text(isEditing ? 'Save' : 'Add',
                  style:
                      const TextStyle(color: AppColors.darkPurple)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Experience',
            style: TextStyle(color: AppColors.darkPurple)),
        content: Text(
            'Are you sure you want to delete "${experience.position}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedExperience = _currentProfile.experience
                  .where((exp) => exp.id != experience.id)
                  .toList();

              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore
                    .collection('users')
                    .doc(uid)
                    .update({
                  'experience': updatedExperience
                      .map((e) => e.toMap())
                      .toList(),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addEducation() => _showEducationDialog(null);
  void _editEducation(Education education) =>
      _showEducationDialog(education);

  void _showEducationDialog(Education? education) {
    final isEditing = education != null;
    final institutionController =
        TextEditingController(text: education?.institution ?? '');
    final degreeController =
        TextEditingController(text: education?.degree ?? '');
    final fieldController =
        TextEditingController(text: education?.fieldOfStudy ?? '');
    final gradeController =
        TextEditingController(text: education?.grade ?? '');
    final descriptionController =
        TextEditingController(text: education?.description ?? '');
    DateTime startDate = education?.startDate ?? DateTime.now();
    DateTime? endDate = education?.endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Edit Education' : 'Add Education',
            style: const TextStyle(color: AppColors.darkPurple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: institutionController,
                  decoration: const InputDecoration(
                      labelText: 'Institution',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: degreeController,
                  decoration: const InputDecoration(
                      labelText: 'Degree',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: fieldController,
                  decoration: const InputDecoration(
                      labelText: 'Field of Study',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(
                      labelText: 'Grade/GPA (optional)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEducation = Education(
                id: education?.id ??
                    DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                institution: institutionController.text,
                degree: degreeController.text,
                fieldOfStudy: fieldController.text,
                startDate: startDate,
                endDate: endDate,
                grade: gradeController.text,
                description: descriptionController.text,
              );

              List<Education> updated =
                  List.from(_currentProfile.education);
              if (isEditing) {
                final index = updated
                    .indexWhere((edu) => edu.id == education!.id);
                if (index != -1) updated[index] = newEducation;
              } else {
                updated.add(newEducation);
              }

              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore
                    .collection('users')
                    .doc(uid)
                    .update({
                  'education':
                      updated.map((e) => e.toMap()).toList(),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunglow),
            child: Text(isEditing ? 'Save' : 'Add',
                style:
                    const TextStyle(color: AppColors.darkPurple)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Education',
            style: TextStyle(color: AppColors.darkPurple)),
        content: Text(
            'Are you sure you want to delete "${education.institution}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkPurple)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedEducation = _currentProfile.education
                  .where((edu) => edu.id != education.id)
                  .toList();

              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final uid = authService.currentUser?.uid;
              if (uid != null) {
                await authService.firestore
                    .collection('users')
                    .doc(uid)
                    .update({
                  'education': updatedEducation
                      .map((e) => e.toMap())
                      .toList(),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Skills',
              style: TextStyle(color: AppColors.darkPurple)),
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
                        decoration: const InputDecoration(
                            labelText: 'Add a skill',
                            border: OutlineInputBorder()),
                        onSubmitted: (value) {
                          if (value.isNotEmpty &&
                              !currentSkills.contains(value)) {
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
                        if (skillController.text.isNotEmpty &&
                            !currentSkills
                                .contains(skillController.text)) {
                          setDialogState(() {
                            currentSkills.add(skillController.text);
                            skillController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add,
                          color: AppColors.darkPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentSkills.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Skills:',
                        style:
                            TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor:
                                  AppColors.wisteria.withOpacity(0.2),
                              deleteIcon:
                                  const Icon(Icons.close, size: 18),
                              onDeleted: () => setDialogState(
                                  () => currentSkills.remove(skill)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.darkPurple)),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final uid = authService.currentUser?.uid;
                if (uid != null) {
                  await authService.firestore
                      .collection('users')
                      .doc(uid)
                      .update({'skills': currentSkills});
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunglow),
              child: const Text('Save',
                  style: TextStyle(color: AppColors.darkPurple)),
            ),
          ],
        ),
      ),
    );
  }
}
