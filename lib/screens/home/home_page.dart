import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_services.dart' hide UserProfile;
import 'feed_page.dart';
import 'post_page.dart';
import 'messages_page.dart';
import '../profile/profile_page.dart';
import '../../models/user_profile.dart';
import '../../models/experience.dart';
import '../../models/education.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedPage(),
    const PostPage(),
    const MessagesPage(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  UserProfile _getSampleProfile() {
    return UserProfile(
      id: '1',
      name: 'John Doe',
      jobTitle: 'Software Developer',
      company: 'Tech Company',
      location: 'New York, NY',
      bio: 'Passionate developer with 3+ years of experience in Flutter and mobile development.',
      connections: 487,
      posts: 23,
      followers: 1205,
      isOwnProfile: true,
      experience: [
        Experience(
          id: '1',
          position: 'Software Developer',
          company: 'Tech Company',
          location: 'New York, NY',
          startDate: DateTime(2022, 1),
          isCurrent: true,
          description: 'Developing mobile applications using Flutter and Firebase.',
        ),
      ],
      education: [
        Education(
          id: '1',
          institution: 'University of Technology',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2018),
          endDate: DateTime(2021),
          grade: '3.7 GPA',
        ),
      ],
      skills: ['Flutter', 'Dart', 'Firebase', 'Git', 'UI/UX'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.signOut();
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.darkPurple,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.wisteria,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.work_outline,
                      color: AppColors.darkPurple,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userProfile: _getSampleProfile(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_outline,
                      color: AppColors.darkPurple,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Main Body
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        color: AppColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(
              icon: Icons.home,
              index: 0,
              label: 'Home',
            ),
            _buildNavButton(
              icon: Icons.add,
              index: 1,
              label: 'Post',
            ),
            _buildNavButton(
              icon: Icons.message,
              index: 2,
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.sunglow,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sunglow.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: AppColors.darkPurple,
          size: 24,
        ),
      ),
    );
  }
}